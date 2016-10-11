require "./cards/*"
require "./utils.cr"

module Spellstorm
  class Deck
    getter cards : Array(Card)

    def initialize
      @cards = [] of Card
    end

    def generate
      @cards.clear
      DECK_SIZE.times do
        @cards << CardsDB.instance.sample
      end
    end

    def find(card) : CardIndex
      @cards.index(card).not_nil!
    end
  end
end
