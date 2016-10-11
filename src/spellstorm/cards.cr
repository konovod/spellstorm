require "./engine/*"
require "./utils.cr"

module Spellstorm
  enum CardLocation
    Deck
    Hand
    FieldShield
    FieldDanger
    FieldSource
    FieldOther
    Drop
  end
  N_CARD_LOCATIONS = 7

  enum Element
    Neutral
    Fire
    Water
    Earth
    Air
  end
  N_ELEMENTS = 5

  alias CardIndex = Int32
  alias ActionArray = Array(Action)

  struct CardState
    property location : CardLocation
    property index : Int32
    property hp : Int32
    property side : Player

    def initialize(@side, @index)
      @hp = 0
      @location = CardLocation::Deck
    end

    def reset
      result = self
      result.hp = 0
      result.index = 0
      result.location = CardLocation::Deck
      result
    end

    def move(states, newlocation)
      result = self
      states.counts[location.to_i] -= 1
      result.location = newlocation
      result.index = states.count_cards(newlocation)
      states.counts[newlocation.to_i] += 1
      result
    end

    def set_index(aindex)
      result = self
      result.index = aindex
      result
    end
  end

  class GameState
    property parts

    def initialize(decks)
      @parts = {
        PlayerState.new(Player::First, decks[0]),
        PlayerState.new(Player::Second, decks[1]),
      }
      next_turn
    end

    def card_state(player, card_index)
      @parts[player.to_i].card_state(card_index)
    end

    def next_turn
      Player.values.each do |player|
        who = @parts[player.to_i]
        enemy = @parts[player.opponent.to_i]
        # TODO - all mechanics
        who.hp = MAX_HP - enemy.damage
        who.refill_hand
      end
    end
  end

  class PlayerState
    property hp : Int32
    property damage : Int32
    property mana
    getter counts
    getter deck

    def initialize(@player : Player, @deck : Deck)
      @data = StaticArray(CardState, DECK_SIZE).new { |i| CardState.new(@player, i) }
      @hp = MAX_HP
      @damage = 0
      @counts = StaticArray(Int32, N_CARD_LOCATIONS).new { |i| i == CardLocation::Deck.to_i ? DECK_SIZE : 0 }
      @mana = StaticArray(Int32, N_ELEMENTS).new(0)
    end

    def count_cards(location : CardLocation)
      @counts[location.to_i]
    end

    def card_state(card_index)
      @data[card_index]
    end

    def move_card(card_index, location : CardLocation)
      @data[card_index] = @data[card_index].move self, location
    end

    def max_mana(element)
      allowed = @mana[Element::Neutral.to_i]
      allowed += @mana[element.to_i] unless element == Element::Neutral
      allowed
    end

    def pay_mana(element, value)
      return false if value > max_mana(element)
      if value >= @mana[element.to_i]
        value -= @mana[element.to_i]
        @mana[element.to_i] = 0
        @mana[Element::Neutral.to_i] -= value
      else
        @mana[element.to_i] -= value
      end
      true
    end

    def refill_hand
      needed = @hp - count_cards(CardLocation::Hand)
      if needed < 0
        in_hand = at_location(CardLocation::Hand).shuffle!
        # drop excess cards
        (-needed).times do
          move_card(in_hand.pop, CardLocation::Drop)
        end
      else
        # get more cards
        in_deck = at_location(CardLocation::Deck).shuffle!
        if in_deck.size < needed
          # TODO
          raise "Out of cards."
        end
        needed.times do
          move_card(in_deck.pop, CardLocation::Hand)
        end
      end
    end

    def at_location(loc) : Array(CardIndex)
      (0...@data.size).select { |i| @data[i].location == loc }
    end

    def compact_indices
      CardLocation.values.each do |loc|
        numbers = at_location loc
        numbers.sort_by! { |i| @data[i].index } unless loc == CardLocation::Deck
        numbers.each_with_index { |i, index| @data[i] = @data[i].set_index index }
      end
    end

    def possible_actions
      result = [] of Action
      at_location(CardLocation::Hand).each do |index|
        if @deck.cards[index].playable(self)
          result << ActionPlay.new(@player, index)
        end
      end
      result
    end
  end

  abstract class Card
    property cost : Int32
    property element : Element
    property power : Int32
    property name : String

    abstract def typ_name : String

    def initialize(@name, @cost, @element, @power)
    end

    def playable(player_state : PlayerState) : Bool
      allowed = player_state.mana[Element::Neutral.to_i]
      allowed += player_state.mana[@element.to_i] unless @element == Element::Neutral
      allowed >= @cost
    end

    # redefinable methods
    def field_location(state : CardState) : CardLocation
      CardLocation::FieldOther
    end

    def get_damage(state : CardState) : Int32
      0
    end

    def estimate_shield(state : CardState) : Int32
      0
    end

    def damage_hook(state : CardState, other : Card, other_state : CardState, value : Int32) : Int32
      value
    end

    def damage_player(state : CardState, game : GameState, value : Int32)
      game.parts[state.side.opponent].hp -= value
    end

    def shield_card(state : CardState, other : Card, other_state : CardState, value : Int32) : Int32
      value
    end
  end

  abstract class Action
    abstract def perform(state : GameState)

    def initialize(@player : Player)
    end
  end

  class ActionPlay < Action
    getter card_index

    def initialize(@player, @card_index : CardIndex)
    end

    def perform(state : GameState)
      st = state.parts[@player.to_i]
      card = st.deck.cards[card_index]
      raise "IMPOSSIBLE" unless st.pay_mana(card.element, card.cost)
      loc = st.deck.cards[card_index].field_location(st.card_state(@card_index))
      st.move_card(card_index, loc)
    end
  end
end
