require "./utils.cr"
require "./engine/*"

require "./cards.cr"
require "./visual_cards.cr"

module Spellstorm
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

    def reset_positions
      @drawn_cards.each { |card| card.pos = card.calc_pos }
      @animations.clear
    end

    def check_positions
      @game_state.parts.each &.compact_indices
      @drawn_cards.sort_by! { |dcard| dcard.visual_index }
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
        states.transform.translate INFO_X, INFO_Y
        states.transform.scale INFO_SCALE, INFO_SCALE
        sel.draw_big(target, states)
      end
    end

    def update_checkbox
      @check_texture.clear
      states = SF::RenderStates.new
      @drawn_cards.each_with_index do |card, index|
        # TODO - more then 254 cards
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
      pl = color.r
      index = color.g
      return nil if pl == 0
      player = Player.new(-1 + pl)
      @drawn_cards.find { |dcard| dcard.card_index == index && dcard.player == player }
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
        reset_positions
      end
    end
  end
end
