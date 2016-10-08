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

    def set_card_state(table, card_index, state, open)
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
    property selected_card : DrawnCard?
    @check_image : SF::Image
    @checkbox : RectType

    def initialize(decks)
      @game_state = GameState.new(decks)
      @animations = Array(CardAnimation).new
      @drawn_cards = Array(DrawnCard).new(DECK_SIZE*2)
      @checkbox = new_rect(0, 0, CARD_WIDTH, CARD_HEIGHT, thickness: 2)
      @check_texture = SF::RenderTexture.new(Engine::SCREENX, Engine::SCREENY)
      @check_texture.smooth = false
      @check_image = SF::Image.new(Engine::SCREENX, Engine::SCREENY)

      Player.values.each do |pl|
        DECK_SIZE.times do |i|
          @drawn_cards << DrawnCard.new(i, @game_state, decks[pl.to_i], pl)
        end
      end
      @check_image
    end

    def update_positions
      @drawn_cards.each { |card| card.pos = card.calc_pos }
      @animations.clear
    end

    def check_positions
      @game_state.parts.each &.compact_indices
      @drawn_cards.sort_by! { |dcard| dcard.my_state.index }
      @drawn_cards.select do |card|
        card.open = card.should_open
        card.pos != card.calc_pos &&
          !@animations.find { |x| x.card == card }
      end.each { |card| animate card }
    end

    def draw(target, states)
      @drawn_cards.each &.draw(target, states)
      if sel = @selected_card
        sel.draw(target, states)
      end
    end

    def update_checkbox
      @check_texture.clear
      states = SF::RenderStates.new
      @drawn_cards.each_with_index do |card, index|
        # TODO - more then 254 cards
        card_color = SF::Color.new(index + 1, 0, 0)
        @checkbox.outline_color = card_color
        @checkbox.fill_color = card_color
        card.draw_checkbox(@check_texture, states, @checkbox)
      end
      if sel = @selected_card
        sel.draw_checkbox(@check_texture, states, @checkbox)
      end
      @check_texture.display
      @check_image = @check_texture.texture.copy_to_image
    end

    def find_card(x, y)
      color = @check_image.get_pixel(x, y)
      index = color.r
      return nil if index == 0 || index > @drawn_cards.size
      @drawn_cards[index - 1]
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
