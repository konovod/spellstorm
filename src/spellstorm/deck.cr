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

  end


end
