require "crsfml/crsfml.cr"
require "./engine/*"
module Spellstorm

  class SpellstormGame < Engine::Game

    def on_mouse(event, x, y)

    end

    def on_key(event : SF::Event::KeyEvent, key)
      @quitting = true
    end

    def draw
        #@debug_draw.draw @space
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

      @text = SF::Text.new

      @text.font = Engine::Font["default.ttf"] # font is a SF::Font
      @text.string = "FPS, UPS = 0123456789"
      @text.character_size = 24 # in pixels, not points!
      @text.color = SF::Color::Red
      @text.style = (SF::Text::Bold | SF::Text::Underlined)
    end

  end

end
