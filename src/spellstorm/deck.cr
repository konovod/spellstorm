require "./cards/*"
require "./utils.cr"

module Spellstorm

  class Deck
    getter data : Array(Card)

    def initialize
      @data = [] of Card
    end

  end


end
