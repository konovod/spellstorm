require "./utils.cr"
require "./engine/*"

module Spellstorm
  class TableSide
    @reverted : Bool

    def initialize(player)
      @reverted = player == Player::Second
      @data = Hash(CardState, Array(GameCard)).new
      CardState.values.each do |p|
        @data[p] = Array(GameCard).new
      end
    end

    # todo - macroses
    def deck
      @data[CardState::Deck]
    end

    def hand
      @data[CardState::Hand]
    end

    def field
      @data[CardState::Field]
    end

    def drop
      @data[CardState::Drop]
    end

    def update_indices
      @data.values.each &.each_with_index { |card, i| card.index = i; card.pos = card.calc_pos }
    end

    def draw(target, states)
      @data.values.each &.each { |card| card.draw(target, states) }
    end

    def new_game(adeck)
      drop.clear
      field.clear
      hand.clear
      deck.clear
      deck.concat(adeck.data.map { |c| GameCard.new(c, @reverted) })
      deck.shuffle!
      deck.each &.reset
      10.times { draw_card }
      hand.sample(6).each { |c| play_card(c) }
      field.sample(2).each { |c| drop_card(c) }
      update_indices
    end

    def draw_card
      return if deck.empty?
      card = deck.pop
      card.state = CardState::Hand
      card.open = true unless @reverted
      @data[CardState::Hand] << card
    end

    def play_card(card)
      hand.delete(card)
      card.state = CardState::Field
      card.open = true
      @data[CardState::Field] << card
    end

    def drop_card(card)
      hand.delete(card)
      field.delete(card)
      card.state = CardState::Drop
      @data[CardState::Drop] << card
    end
  end

  class Table
    def initialize
      @sides = Hash(Player, TableSide).new
      Player.values.each do |p|
        @sides[p] = TableSide.new(p)
      end
    end

    def draw(target, states, cur_player)
      @sides.values.each &.draw(target, states)
    end

    def new_game(decks)
      Player.values.zip(decks.to_a).each do |p, d|
        @sides[p].new_game(d)
      end
    end
  end
end
