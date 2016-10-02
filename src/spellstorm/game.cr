require "crsfml/crsfml.cr"
require "./engine/*"
require "./cards/*"
require "./utils.cr"

module Spellstorm

  class SpellstormGame < Engine::Game
    @fps_label : SF::Text
    getter cards_db
    getter decks
    getter table

    def on_mouse(event, x, y)

    end

    def on_key(event : SF::Event::KeyEvent, key)
      @quitting = true
    end

    def draw
        @table.draw(@window, Player::First)
        @fps_label.string = "FPS=#{@fps}, UPS=#{@ups}"
        @window.draw(@fps_label)
    end

    def process

    end


    def initialize
      super

      @fps_label = new_text(0,0,"FPS, UPS = 0123456789", SF::Color::Red)

      @cards_db = CardsDB.new
      @decks = {Deck.new, Deck.new}
      @table = Table.new

    end

  end

end
