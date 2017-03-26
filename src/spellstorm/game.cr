require "crsfml"
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
      # return unless event.is_a? SF::Event::MouseButtonReleased

      vcard = @table.find_card(x, y)
      if vcard && vcard.open
        @table.selected_card = vcard
      else
        @table.selected_card = nil
      end

      if event.is_a? SF::Event::MouseButtonReleased && event.button.right?
        skip_turn
        @some_action = true
      end

      if event.is_a? SF::Event::MouseButtonReleased && event.button.left? && vcard
        we = @table.game_state.parts[Player::First.to_i]
        return unless vcard.card.playable(we)
        ActionPlay.new(vcard.my_state).perform
        @some_action = true
      end
    end

    def we
      @table.game_state.parts[Player::First.to_i]
    end

    def enemy
      @table.game_state.parts[Player::Second.to_i]
    end

    def skip_turn
      loop do
        x = enemy.possible_actions
        break if x.empty?
        x.sample.perform
      end
      @table.game_state.next_turn
    end

    def on_key(event : SF::Event::KeyEvent, key)
      @quitting = true
    end

    def draw
      # @window.draw(@back)
      if !@table.animations.empty? || @some_action
        @table.check_positions
        @table.update_checkbox
        @some_action = false
      end
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
      @some_action = true
    end

    def run
      # new_game
      super
    end
  end
end
