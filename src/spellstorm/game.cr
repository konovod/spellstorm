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
      return unless event.is_a? SF::Event::MouseButtonReleased
      # side = @table.sides[Player::First]
      # card = side.find_card(x,y)
      # if card
      #   #p card.card.name
      #   if card.state == CardState::Deck
      #     side.draw_card
      #   elsif card.state == CardState::Hand
      #       side.play_card(card)
      #   else
      #     side.drop_card(card)
      #   end
      # end

    end

    def on_key(event : SF::Event::KeyEvent, key)
      @quitting = true
    end

    def draw
      # @window.draw(@back)
      @table.draw(@window, SF::RenderStates.new)
      @fps_label.string = "FPS=#{@fps}, UPS=#{@ups}"
      @window.draw(@fps_label)
    end

    def process
      @table.process_animations
    end

    def new_game
      @decks.each &.generate
      @table = Table.new(@decks)
    end

    def initialize
      super

      @fps_label = new_text(0, 0, "FPS, UPS = 0123456789", size: 24, color: SF::Color::Red)

      CardsDB.instance # forcing init
      @decks = {Deck.new, Deck.new}
      @decks.each &.generate
      @table = Table.new(@decks)

      @back = Engine::Background.new(self, Engine::Tex["water.jpg"])
      @cur_player = Player::First
    end

    def run
      new_game
      super
    end
  end
end
