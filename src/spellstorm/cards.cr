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
    @label : SF::Text
    getter state
    getter index

    property cost : Int32
    property element : Element
    property power : Int32
    property name : String

    abstract def typ_name : String

    def initialize(@name, @cost, @element, @power)
      @state = CardState::Deck
      @index = 0 #TODO index
      @label = new_text(0,0, @name, SF::Color::White)
      @label.origin = vec(@label.local_bounds.width/2, @label.local_bounds.height/2)
      @frame = SF::RectangleShape.new
      @frame.size = vec(CARD_WIDTH, CARD_HEIGHT)
      @frame.origin = vec(CARD_WIDTH / 2, CARD_HEIGHT / 2)
      @frame.outline_color = SF::Color::Red
      @frame.fill_color = SF::Color::Transparent
      @frame.outline_thickness = 1
      update_pos
    end

    def update_pos
      pos = vec(200,200)
      @label.position = pos
      @frame.position = pos
    end

    def draw(target : SF::RenderTarget)

      target.draw @frame
      target.draw @label
    end



  end

end
