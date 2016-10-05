require "./engine/*"
require "./utils.cr"

module Spellstorm
  enum CardState
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

  abstract class Card
    property cost : Int32
    property element : Element
    property power : Int32
    property name : String

    abstract def typ_name : String

    def initialize(@name, @cost, @element, @power)
    end
  end

  struct CardPos
    property pos : MyVec
    property angle : Float64

    def initialize(@pos, @angle)
    end

    def apply(states)
      states.transform.translate(@pos)
      states.transform.rotate(@angle)
      return states
    end

    def invert
      @pos.y = Y0 - @pos.y - 100
    end
  end

  class CardAnimation
    getter cur_pos : CardPos
    getter counter : Int32
    getter card : GameCard

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

  class GameCard
    @elements : Array(SF::Drawable)
    getter card : Card
    @reverted : Bool
    @back : SF::Drawable
    property state
    property index
    property open
    property pos : CardPos

    def initialize(@card, @reverted)
      @state = CardState::Deck
      @index = 0
      @open = false
      @pos = calc_pos

      label_name = new_text(CARD_WIDTH / 2, CARD_HEIGHT / 2, @card.name,
        size: 16, color: SF::Color::Black, centered: true)
      label_cost = new_text(10, 10, @card.cost.to_s,
        size: 16, color: SF::Color::Black, style: SF::Text::Bold, centered: true)
      label_power = new_text(CARD_WIDTH - 10, 10, @card.power.to_s,
        size: 16, color: SF::Color::Black, style: SF::Text::Bold, centered: true)

      frame = new_rect(0,0,CARD_WIDTH, CARD_HEIGHT,
                    outline: SF::Color::Black,
                    fill: SF::Color::White,
                    thickness: 2
                    )
      @back = new_rect(0,0,CARD_WIDTH, CARD_HEIGHT,
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
      calc_pos(@state, @index)
    end

    def calc_pos(state, index)
      base = CARD_COORDS[state]
      result = CardPos.new(base[:pos] + base[:delta]*index, base[:angle0] + base[:dangle]*index)
      result.invert if @reverted
      return result
    end

    def reset
      @state = CardState::Deck
    end

    def draw(target : SF::RenderTarget, states : SF::RenderStates)
      states = @pos.apply(states)
      if open
        @elements.each &.draw(target, states)
      else
        @back.draw(target, states)
      end
    end

  end
end
