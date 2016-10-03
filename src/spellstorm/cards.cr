require "./engine/*"
require "./utils.cr"


module Spellstorm

  enum CardState
    Deck
    Hand
    Table
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
    @elements : Array(SF::Drawable)
    property state

    property cost : Int32
    property element : Element
    property power : Int32
    property name : String

    abstract def typ_name : String

    def initialize(@name, @cost, @element, @power)
      @state = CardState::Deck

      label_name = new_text(CARD_WIDTH / 2, CARD_HEIGHT / 2, @name,
            size: 12, color: SF::Color::Black, centered: true)
      label_cost = new_text(10, 10, @cost.to_s,
            size: 16, color: SF::Color::Black, style: SF::Text::Bold, centered: true)
      label_power = new_text(CARD_WIDTH-10, 10, @cost.to_s,
            size: 16, color: SF::Color::Black, style: SF::Text::Bold, centered: true)


      frame = SF::RectangleShape.new(vec(CARD_WIDTH, CARD_HEIGHT))
      #frame.origin = vec(CARD_WIDTH / 2, CARD_HEIGHT / 2)
      frame.outline_color = SF::Color::Red
      frame.fill_color = SF::Color::White
      frame.outline_thickness = 1

      @elements = [] of SF::Drawable
      @elements<<frame
      @elements<<label_name
      @elements<<label_cost
      @elements<<label_power

    end

    def update_pos(state, index)
      return vec(20+index*(CARD_WIDTH+5),20+state.to_i*(CARD_HEIGHT+10))
    end

    def draw(target : SF::RenderTarget, states : SF::RenderStates, index : Int32, open : Bool = true)
      states.transform.translate(update_pos(@state, index))
      if open
        @elements.each &.draw(target, states)
      else
        @elements.first.draw(target, states)
      end
    end

    def reset
      @state = CardState::Deck
    end



  end

end
