require "./utils.cr"
require "./engine/*"

module Spellstorm
  class TableSide
    @reverted : Bool
    @table : Table

    def initialize(@table, player)
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

    def all_cards
      @data.values.each &.each { |card| yield card }
    end

    def update_indices
      @data.values.each &.each_with_index { |card, i| card.index = i; card.pos = card.calc_pos }
      @table.animations.clear
    end

    def draw(target, states)
      all_cards &.draw(target, states)
    end

    def find_card(x,y, **args)
      all_cards { |card|
        if SF.float_rect(card.pos.pos.x,card.pos.pos.y,CARD_WIDTH, CARD_HEIGHT).contains?(x,y)
          return card
        end
      }
      nil
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
      @table.animate card
    end

    def play_card(card)
      hand.delete(card)
      card.state = CardState::Field
      card.open = true
      @data[CardState::Field] << card
      @table.animate card
    end

    def drop_card(card)
      hand.delete(card)
      field.delete(card)
      card.state = CardState::Drop
      @data[CardState::Drop] << card
      @table.animate card
    end
  end

  class Table
    getter animations
    getter sides
    def initialize
      @animations = Array(CardAnimation).new
      @sides = Hash(Player, TableSide).new
      Player.values.each do |p|
        @sides[p] = TableSide.new(self, p)
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

    #will contain additional constraints
    def find_card(x,y, **args)
      @sides.values.each do |v|
        if c = v.find_card(x,y, **args)
          return c
        end
      end
      nil
    end

    def animate(card)
      animate(card, card.pos, card.calc_pos)
    end

    def animate(card, oldpos, newpos)
      @animations.reject!{|x| x.card == card}
      @animations << CardAnimation.new(card, oldpos, newpos)
    end

    def process_animations
      @animations.reject! &.process
    end

  end
end
