require "./cards/*"
require "./utils.cr"

module Spellstorm

  class Deck
    getter data : Array(Card)

    def initialize
      @data = [] of Card
    end

    def generate
      5.times do
        @data += CardsDB.instance.data.sample(10)
      end
    end

  end


end
