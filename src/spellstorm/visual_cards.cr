require "./engine/*"
require "./utils.cr"
require "./cards.cr"

module Spellstorm
  struct CardPos
    property pos : MyVec
    property angle : Float64

    def initialize(@pos, @angle)
    end

    def apply(sf_states)
      sf_states.transform.translate(@pos)
      sf_states.transform.rotate(@angle)
      return sf_states
    end

    def invert
      @pos.y = Y0 - @pos.y - TOP_HIDING
    end
  end

  class CardAnimation
    getter cur_pos : CardPos
    getter counter : Int32
    getter card : DrawnCard

    def initialize(@card, @start : CardPos, @end : CardPos)
      @cur_pos = @start
      length = [(@end.pos.x - @start.pos.x).abs, (@end.pos.y - @start.pos.y).abs].max
      @counter = (length / ANIM_SPEED).to_i
      @step = CardPos.new(
        (@end.pos - @start.pos) / @counter,
        (@end.angle - @start.angle) / @counter
      )
    end

    def one_step
      @cur_pos.pos += @step.pos
      @cur_pos.angle += @step.angle
      @counter -= 1
      return @counter <= 0
    end

    def process
      f = one_step
      if f
        @card.pos = @end
      else
        @card.pos = @cur_pos
      end
      f
    end
  end

  class DrawnCard
    @elements : Array(SF::Drawable)
    @back : SF::Drawable
    getter card_index : CardIndex
    property open
    property pos : CardPos
    getter player : Player

    def my_state : CardStateMutable
      @states.card_state(@player, @card_index)
    end

    def card
      @deck.cards[@card_index]
    end

    def visual_index
      my_state.loc_index
    end

    def initialize(@card_index, @states : GameState, @deck : Deck, @player)
      @open = false
      starty = @player == Player::First ? Y0 - 100 : 100
      @pos = CardPos.new(vec(Engine::SCREENX / 2, starty), 0.0)
      acard = @deck.cards[@card_index]
      label_name = new_text(CARD_WIDTH / 2, 30, acard.name,
        size: 16, color: SF::Color::Black, centered: true)
      label_cost = new_text(10, 10, acard.cost.to_s,
        size: 16, color: SF::Color::Black, style: SF::Text::Bold, centered: true)
      label_power = new_text(CARD_WIDTH - 10, 10, acard.power.to_s,
        size: 16, color: SF::Color::Black, style: SF::Text::Bold, centered: true)

      frame = new_rect(0, 0, CARD_WIDTH, CARD_HEIGHT,
        outline: SF::Color::Black,
        fill: SF::Color::White,
        thickness: 2
      )
      @back = new_rect(0, 0, CARD_WIDTH, CARD_HEIGHT,
        texture: Engine::Tex["grass.png"],
        outline: SF::Color::Black,
        thickness: 2
      )
      # @back.origin = vec(CARD_WIDTH / 2, CARD_HEIGHT / 2)

      @elements = [] of SF::Drawable
      @elements << frame
      @elements << label_name
      @elements << label_cost
      @elements << label_power
    end

    def calc_pos
      calc_pos(my_state.location, visual_index)
    end

    def should_open
      case @player
      when Player::First
        my_state.location > CardLocation::Deck
      when Player::Second
        my_state.location > CardLocation::Hand
      else
        true
      end
    end

    def reverted
      @player == Player::Second
    end

    def calc_pos(location, index)
      base = CARD_COORDS[location]
      base = CARD_COORDS[DEBUG_MODE] if DEBUG_MODE && location != CardLocation::Deck
      result = CardPos.new(base[:pos] + base[:delta]*index, base[:angle0] + base[:dangle]*index)
      result.invert if reverted
      return result
    end

    def draw(target : SF::RenderTarget, sf_states : SF::RenderStates)
      sf_states = @pos.apply(sf_states)
      if open
        @elements.each &.draw(target, sf_states)
      else
        @back.draw(target, sf_states)
      end
    end

    def draw_big(target : SF::RenderTarget, sf_states : SF::RenderStates)
      @elements.each &.draw(target, sf_states)
    end

    def draw_checkbox(target : SF::RenderTarget, sf_states : SF::RenderStates, checkbox)
      sf_states = @pos.apply(sf_states)
      card_color = SF::Color.new(player.to_i + 1, card_index, 0, 255)
      checkbox.outline_color = card_color
      checkbox.fill_color = card_color
      checkbox.draw(target, sf_states)
    end
  end
end
