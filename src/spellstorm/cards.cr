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

  class GameCard
    @elements : Array(SF::Drawable)
    @card : Card
    property state

    def initialize(@card)
      @state = CardState::Deck
      label_name = new_text(CARD_WIDTH / 2, CARD_HEIGHT / 2, @card.name,
        size: 12, color: SF::Color::Black, centered: true)
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

      @elements = [] of SF::Drawable
      @elements << frame
      @elements << label_name
      @elements << label_cost
      @elements << label_power
    end

    def calc_pos(state, index)
      return CARD_POS[state] + CARD_DELTA[state]*index
      #      result = vec(20+index*(CARD_WIDTH+5),20+state.to_i*(CARD_HEIGHT+10))
    end

    def reset
      @state = CardState::Deck
    end

    def draw(target : SF::RenderTarget, states : SF::RenderStates, pos : MyVec, angle, open : Bool)
      states.transform.translate(pos)
      states.transform.rotate(angle)
      if open
        @elements.each &.draw(target, states)
      else
        # @elements.first.draw(target, states)
        @back.draw(target, states)
      end
    end

    def draw(target : SF::RenderTarget, states : SF::RenderStates, index, reverted, open : Bool)
      apos = calc_pos(@state, index)
      apos.y = Engine::SCREENY - CARD_HEIGHT - apos.y if reverted

      draw(target, states, apos, 0, open)
    end
  end
end
