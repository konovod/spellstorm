
require "../cards.cr"

module Spellstorm

class ShieldCard < Card

  def typ_name : String
    "Щит"
  end

end

class CardsDB
  getter data : Array(Card)

  def initialize
    @data = [] of Card
    #@name, @cost, @element, @power
    @data << ShieldCard.new("Малый щит",2,Element::Neutral,2)
  end

  def sample : Card
    @data.sample
  end

end

end
