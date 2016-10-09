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

  alias CardIndex = Int32

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

    def possible_actions(player)
    end
  end

  class PlayerState
    property hp : Int32
    property damage : Int32
    getter counts

    def initialize(@player : Player, @deck : Deck)
      @data = StaticArray(CardState, DECK_SIZE).new { |i| CardState.new(@player, i) }
      @hp = MAX_HP
      @damage = 0
      @counts = StaticArray(Int32, 4).new { |i| i == CardLocation::Deck.to_i ? DECK_SIZE : 0 }
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

    def refill_hand
      needed = @hp - count_cards(CardLocation::Hand)
      if needed < 0
        in_hand = (0...@data.size).select { |i| @data[i].location == CardLocation::Hand }.shuffle!
        # drop excess cards
        (-needed).times do
          move_card(in_hand.pop, CardLocation::Drop)
        end
      else
        # get more cards
        in_deck = (0...@data.size).select { |i| @data[i].location == CardLocation::Deck }.shuffle!
        if in_deck.size < needed
          # TODO
          raise "Out of cards."
        end
        needed.times do
          move_card(in_deck.pop, CardLocation::Hand)
        end
      end
    end

    def compact_indices
      CardLocation.values.each do |loc|
        numbers = (0...@data.size).select { |i| @data[i].location == loc }
        numbers.sort_by! { |i| @data[i].index } unless loc == CardLocation::Deck
        numbers.each_with_index { |i, index| @data[i] = @data[i].set_index index }
      end
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
