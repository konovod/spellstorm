require "./engine/*"
require "./utils.cr"
require "./cards.cr"

module Spellstorm
  struct CardState
    property location : CardLocation
    property loc_index : Int32
    property hp : Int32

    def initialize(@loc_index)
      @hp = 0
      @location = CardLocation::Deck
    end
  end

  alias CardIndex = Int32

  struct CardStateMutable
    property owner : PlayerState
    property index : CardIndex

    def initialize(@owner, @index)
    end

    macro access_property(x)
      def {{x}}
        owner.data[index].{{x}}
      end
      def {{x}}=(value)
        #lol, no easy structs mutation
        #owner.data[index].{{x}}=value
        t = owner.data[index]
        t.{{x}}=value
        owner.data[index] = t
      end
    end

    access_property location
    access_property hp
    access_property loc_index

    def reset
      self.hp = 0
      self.loc_index = 0
      self.location = CardLocation::Deck
    end

    def move(newlocation)
      owner.counts[location.to_i] -= 1
      self.location = newlocation
      self.loc_index = owner.count_cards(newlocation)
      owner.counts[newlocation.to_i] += 1
    end

    def card
      owner.deck.cards[index]
    end

    def raw
      owner.data[index]
    end
  end

  class PlayerState
    getter game : GameState
    property hp : Int32
    property test_damage : Int32
    property test_mana
    getter counts
    getter deck
    property own_mana
    property data

    def initialize(@game, @player : Player, @deck : Deck)
      @data = StaticArray(CardState, DECK_SIZE).new { |i| CardState.new(i) }
      @hp = MAX_HP
      @test_damage = 0
      @counts = StaticArray(Int32, N_CARD_LOCATIONS).new { |i| i == CardLocation::Deck.to_i ? DECK_SIZE : 0 }
      @test_mana = StaticArray(Int32, N_ELEMENTS).new(0)
      @own_mana = 0
    end

    def opponent
      @game.parts[@player.opponent.to_i]
    end

    # TODO - optimization?
    def estim_damage
      at_location(CardLocation.field).sum { |mut| mut.card.get_damage(mut) }
    end

    def estim_shield
      at_location(CardLocation.field).sum { |mut| mut.card.estim_shield(mut) }
    end

    def mana(element)
      @test_mana[element.to_i]
      # TODO - source mechanics
    end

    def count_cards(location : CardLocation)
      @counts[location.to_i]
    end

    def card_state(card_index)
      CardStateMutable.new(self, card_index)
    end

    def max_mana(element)
      allowed = mana(Element::Neutral)
      allowed += mana(element) unless element == Element::Neutral
      allowed
    end

    def pay_mana(element, value)
      return false if value > max_mana(element)
      # TODO - source mechanics
      if value >= @test_mana[element.to_i]
        value -= @test_mana[element.to_i]
        @test_mana[element.to_i] = 0
        @test_mana[Element::Neutral.to_i] -= value
      else
        @test_mana[element.to_i] -= value
      end
      true
    end

    def refill_hand
      needed = @hp - count_cards(CardLocation::Hand)
      if needed < 0
        in_hand = at_location(CardLocation::Hand).shuffle!
        # drop excess cards
        (-needed).times do
          in_hand.pop.move(CardLocation::Drop)
        end
      else
        # get more cards
        in_deck = at_location(CardLocation::Deck).shuffle!
        if in_deck.size < needed
          # TODO
          raise "Out of cards."
        end
        needed.times do
          in_deck.pop.move(CardLocation::Hand)
        end
      end
    end

    def at_location(loc : CardLocation) : Array(CardStateMutable)
      locs = {loc}
      at_location locs
    end

    def at_location(locs) : Array(CardStateMutable)
      (0...@data.size).select { |i| locs.includes? @data[i].location }.map { |index| CardStateMutable.new(self, index) }
    end

    def compact_indices
      CardLocation.values.each do |loc|
        numbers = at_location loc
        # card_state isn't used here as a (premature?) optimization
        numbers.sort_by! { |i| @data[i].index } unless loc == CardLocation::Deck
        numbers.each_with_index { |i, index| @data[i].index = index }
      end
    end

    def possible_actions
      result = [] of Action
      at_location(CardLocation::Hand).each do |mut|
        if mut.card.playable(self)
          result << ActionPlay.new(mut)
        end
      end
      result
    end
  end
end

class GameState
  property parts

  def initialize(decks)
    # TODO - tuple\StaticArray make it nullable
    @parts = [] of PlayerState
    @parts << PlayerState.new(self, Player::First, decks[0])
    @parts << PlayerState.new(self, Player::Second, decks[1])
    next_turn
  end

  def card_state(player, card_index)
    @parts[player.to_i].card_state(card_index)
  end

  def next_turn
    Player.values.each do |player|
      who = @parts[player.to_i]
      enemy = @parts[player.opponent.to_i]
      # damage and shields mechanics
      who_cards = who.at_location(CardLocation.field)
      enemy_cards = enemy.at_location(CardLocation.field)
      if who.estim_damage > 0
        # TODO - remove dynamic allocations here?
        attackers = Hash(CardStateMutable, Int32).new
        who_cards.each do |mut|
          v = mut.card.get_damage(mut)
          attackers[mut] = v if v > 0
        end
        defenders = enemy_cards.select do |def_mut|
          def_mut.card.estim_shield(def_mut) > 0
        end
        attackers.each do |attacker, dam|
          defenders.each do |defender|
            dam = attacker.card.damage_hook(attacker, defender, dam)
            break if dam <= 0
            dam = defender.card.shield_card(defender, attacker, dam)
            break if dam <= 0
          end
          attacker.card.damage_player(attacker, dam) if dam > 0
        end
      end

      who.hp = MAX_HP - enemy.test_damage
      who.refill_hand
    end
  end
end
