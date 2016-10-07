require "./utils.cr"
require "./engine/*"

require "./cards.cr"
require "./visual_cards.cr"

module Spellstorm
  abstract class Action
    abstract def perform(state : GameState)
    abstract def visualize(table : Table)

    def initialize(@player : Player)
    end

    def set_card_state(table, card, state, open)
      @data[card.state].delete(card)
      card.state = state
      card.open = true if open
      @data[state] << card
      card.index = @data[state].size - 1
      @table.animate card
    end
  end

  class ActionDraw < Action
    def perform(state : GameState)
    end

    def visualize(table : Table)
    end
  end

  # def new_game(adeck)
  #   drop.clear
  #   field.clear
  #   hand.clear
  #   deck.clear
  #   deck.concat(adeck.data.map { |c| DrawnCard.new(c, @reverted) })
  #   deck.shuffle!
  #   deck.each &.reset
  #   10.times { draw_card }
  #   hand.sample(6).each { |c| play_card(c) }
  #   field.sample(2).each { |c| drop_card(c) }
  #   update_positions
  # end

  # def draw_card
  #   return if deck.empty?
  #   card = deck.pop
  #   set_card_state(card, CardState::Hand, !@reverted)
  # end
  #
  # def play_card(card)
  #   set_card_state(card, CardState::Field, @reverted)
  # end
  #
  # def drop_card(card)
  #   set_card_state(card, CardState::Drop, true)
  # end

  class Table
    getter animations
    property game_state : GameState

    def initialize(decks)
      @game_state = GameState.new(decks)
      @animations = Array(CardAnimation).new
      @drawn_cards = Array(DrawnCard).new
      decks.each_with_index do |deck, i|
        @drawn_cards += deck.data.map { |card| DrawnCard.new(card, @game_state, Player.new(i)) }
      end
    end

    def update_positions
      @drawn_cards.each { |card| card.pos = card.calc_pos }
      @animations.clear
    end

    def draw(target, states)
      @drawn_cards.each &.draw(target, states)
    end

    def find_card(x, y, **args)
      @drawn_cards.each { |card|
        if SF.float_rect(card.pos.pos.x, card.pos.pos.y, CARD_WIDTH, CARD_HEIGHT).contains?(x, y)
          return card
        end
      }
      nil
    end

    # will contain additional constraints
    def find_card(x, y, **args)
      @sides.values.each do |v|
        if c = v.find_card(x, y, **args)
          return c
        end
      end
      nil
    end

    def animate(card)
      animate(card, card.pos, card.calc_pos)
    end

    def animate(card, oldpos, newpos)
      @animations.reject! { |x| x.card == card }
      @animations << CardAnimation.new(card, oldpos, newpos)
    end

    def process_animations
      was = !@animations.empty?
      @animations.reject! &.process
      if @animations.empty? && was
        update_positions
      end
    end
  end
end
