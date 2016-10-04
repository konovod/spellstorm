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
    @pos : MyVec
    @angle : Float64

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

  class GameCard
    @elements : Array(SF::Drawable)
    @card : Card
    property state

    def initialize(@card)
      @state = CardState::Deck
      label_name = new_text(CARD_WIDTH / 2, CARD_HEIGHT / 2, @card.name,
        size: 16, color: SF::Color::Black, centered: true)
      label_cost = new_text(10, 10, @card.cost.to_s,
        size: 16, color: SF::Color::Black, style: SF::Text::Bold, centered: true)
      label_power = new_text(CARD_WIDTH - 10, 10, @card.power.to_s,
        size: 16, color: SF::Color::Black, style: SF::Text::Bold, centered: true)

      frame = SF::RectangleShape.new(vec(CARD_WIDTH, CARD_HEIGHT))
      # frame.origin = vec(CARD_WIDTH / 2, CARD_HEIGHT / 2)
      frame.outline_color = SF::Color::Black
      frame.fill_color = SF::Color::White
      frame.outline_thickness = 2

      @back = SF::RectangleShape.new(vec(CARD_WIDTH, CARD_HEIGHT))
      @back.texture = Engine::Tex["grass.png"]
      @back.outline_color = SF::Color::Black
      @back.outline_thickness = 2
      # @back.origin = vec(CARD_WIDTH / 2, CARD_HEIGHT / 2)

      @elements = [] of SF::Drawable
      @elements << frame
      @elements << label_name
      @elements << label_cost
      @elements << label_power
    end

    def calc_pos(state, index)
      base = CARD_COORDS[state]
      return CardPos.new(base[:pos] + base[:delta]*index, base[:angle0] + base[:dangle]*index)
      #      result = vec(20+index*(CARD_WIDTH+5),20+state.to_i*(CARD_HEIGHT+10))
    end

    def reset
      @state = CardState::Deck
    end

    def draw(target : SF::RenderTarget, states : SF::RenderStates, open : Bool)
      if open
        @elements.each &.draw(target, states)
      else
        # @elements.first.draw(target, states)
        @back.draw(target, states)
      end
    end

    def draw(target : SF::RenderTarget, states : SF::RenderStates, index, reverted, open : Bool)
      apos = calc_pos(@state, index)
      apos.invert if reverted
      draw(target, apos.apply(states), open)
    end
  end
end
