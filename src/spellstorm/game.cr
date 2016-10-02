require "crsfml/crsfml.cr"
require "./engine/*"
require "./cards/*"
require "./utils.cr"

module Spellstorm

  class SpellstormGame < Engine::Game
    @text : SF::Text
    @cards_db : Array(Card)

    def on_mouse(event, x, y)

    end

    def on_key(event : SF::Event::KeyEvent, key)
      @quitting = true
    end

    def draw
        
        @window.draw(@triangle)
        @text.string = "FPS=#{@fps}, UPS=#{@ups}"
        @window.draw(@text)
    end

    def process

    end


    def initialize
      super

      @triangle = SF::VertexArray.new(SF::Triangles, 3)

      # define the positions and colors of the triangle's points
      @triangle[0] = SF::Vertex.new(SF.vector2(10, 10), SF::Color::Red)
      @triangle[1] = SF::Vertex.new(SF.vector2(100, 10), SF::Color::Blue)
      @triangle[2] = SF::Vertex.new(SF.vector2(100, 100), SF::Color::Green)
      @text = new_text(100,100,"FPS, UPS = 0123456789", SF::Color::Red)

      @cards_db = Array(Card).new
      #Spellstorm.init_card_db(@cards_db)

      @decks = {Array(Card).new, Array(Card).new}

    end

  end

end
