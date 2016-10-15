require "./engine/*"
require "./utils.cr"
require "./cards.cr"

module Spellstorm
  struct CardState
    property location : CardLocation
    property loc_index : Int32
    property hp : Int32
    property need_processing : Bool

    def initialize(@loc_index)
      @hp = 0
      @location = CardLocation::Deck
      @need_processing = false
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
        ((owner.data.to_unsafe.as(CardState*) + index)).value.{{x}}=value
        # t = owner.data[index]
        # t.{{x}}=value
        # owner.data[index] = t
      end
    end

    access_property location
    access_property hp
    access_property loc_index
    access_property need_processing

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

    def max_mana(element)
      # test_mana
      result = @test_mana[element.to_i]
      result += @test_mana[Element::Neutral.to_i] unless element == Element::Neutral
      # sources
      result += at_location(CardLocation.field).sum { |mut| mut.card.mana_source(mut, element) }
      # own_mana
      result += @own_mana
      result
    end

    def count_cards(location : CardLocation)
      @counts[location.to_i]
    end

    def card_state(card_index)
      CardStateMutable.new(self, card_index)
    end

    def pay_mana(element, value)
      return false if value > max_mana(element)
      # first use @test_mana
      {element.to_i, Element::Neutral.to_i}.each do |i|
        if value > @test_mana[i]
          value -= @test_mana[i]
          @test_mana[i] = 0
        else
          @test_mana[i] -= value
          return true
        end
      end
      # now use sources
      sources = at_location(CardLocation.field).map { |mut|
        {mut, mut.card.mana_source(mut, element)}
      }.select { |mut, value| value > 0 }
      sources_max = sources.sum { |mut, value| value }
      if value >= sources_max
        # use all available mana
        sources.each do |mut, mana|
          mut.card.mana_provide(mut, element, mana)
          value -= mana
        end
      else
        if sources.size > 1
          sources.sort_by! { |(mut, power)| {mut.card.power - power, mut.card.power} }
        end
        # TODO - there is possible optimization, but does it worth it?
        loop do
          sources.each do |src, power|
            src.card.mana_provide(src, element, 1)
            value -= 1
            return true if value <= 0
          end
        end
      end
      # finally, use @own_mana
      return false if value > @own_mana
      @own_mana -= value
      return true
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
        numbers.sort_by! { |mut| mut.loc_index } unless loc == CardLocation::Deck
        numbers.each_with_index { |mut, index| mut.loc_index = index }
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
        enemy.hp = MAX_HP
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
              dam = attacker.card.hook_damage(attacker, defender, dam)
              break if dam <= 0
              dam = defender.card.hook_shield(defender, attacker, dam)
              break if dam <= 0
            end
            attacker.card.damage_player(attacker, dam) if dam > 0
          end
        end
        enemy.hp -= who.test_damage
        # cards processing
        who.at_location(CardLocation.field).each { |mut| mut.card.hook_processing(mut) if mut.need_processing }
        enemy.refill_hand
      end
    end
  end
end
