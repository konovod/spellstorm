require "./cards/*"
require "./utils.cr"

module Spellstorm
  class Deck
    getter data : Array(Card)

    def initialize
      @data = [] of Card
    end

    def generate
      50.times do
        @data << CardsDB.instance.sample
      end
    end

    #TODO optimization
    def find(card)
      @data.index(card).not_nil!
    end

  end
end
