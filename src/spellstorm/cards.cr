require "./engine/*"
require "./utils.cr"

module Spellstorm
  enum CardLocation
    Deck
    Hand
    Field
    Drop
  end

  enum Element
    Neutral
    Fire
    Water
    Earth
    Air
  end

  struct CardState
    property location : CardLocation
    property index : Int32
    property hp : Int32
    property side : Player

    def initialize(@side)
      @hp = 0
      @index = 0
      @location = CardLocation::Deck
    end

    def reset
      hp = 0
      index = 0
      location = CardLocation::Deck
    end

    def move (states, newlocation)

    end

  end

  class GameState
    property parts
    def initialize(decks)
      @parts = { PlayerState.new(Player::First, decks[0]), PlayerState.new(Player::Second, decks[1]) }
    end

    def card_state(player, card)
      @parts[player.to_i].card_state(card)
    end

  end

  class PlayerState
    getter hp : Int32

    def initialize(@player : Player, @deck : Deck)
      @data = StaticArray(CardState, DECK_SIZE).new{ |i| CardState.new(@player)}
      @hp = MAX_HP
      @counts = StaticArray(Int32, 4).new{ |i| i == CardLocation::Deck.to_i ? DECK_SIZE : 0}
    end

    def counts(location : CardLocation)
      @counts[location.to_i]
    end

    def card_state(card : Card)
      @data[@deck.find(card)]
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
  end
end
