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
      return if event.is_a? SF::Event::MouseMoved
      if @cur_player == Player::First
        @cur_player = Player::Second
      else
        @cur_player = Player::First
      end
    end

    def on_key(event : SF::Event::KeyEvent, key)
      @quitting = true
    end

    def draw
      # @window.draw(@back)
      @table.draw(@window, SF::RenderStates.new, @cur_player)
      @fps_label.string = "FPS=#{@fps}, UPS=#{@ups}"
      @window.draw(@fps_label)
    end

    def process
    end

    def new_game
      @decks.each &.generate
      @table.new_game(@decks)
    end

    def initialize
      super

      @fps_label = new_text(0, 0, "FPS, UPS = 0123456789", size: 24, color: SF::Color::Red)

      CardsDB.instance # forcing init
      @decks = {Deck.new, Deck.new}
      @table = Table.new

      @back = Engine::Background.new(self, Engine::Tex["water.jpg"])
      @cur_player = Player::First
    end

    def run
      new_game
      super
    end
  end
end
