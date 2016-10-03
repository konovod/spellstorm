require "../cards.cr"
require "./basic.cr"

module Spellstorm
  class CardsDB
    @@instance : CardsDB?

    def self.instance : CardsDB
      item = @@instance
      return item if item
      item = new
      @@instance = item
      item
    end

    getter data : Array(Card)

    private def initialize
      @data = [] of Card
      # @name, @cost, @element, @power
      @data << ShieldCard.new("Малый щит", 2, Element::Neutral, 2)
      @data << ShieldCard.new("Рассеивающий щит", 5, Element::Neutral, 2)
      @data << ShieldCard.new("Большой щит", 6, Element::Neutral, 5)
      @data << DangerCard.new("Малая угроза", 1, Element::Neutral, 1)
      @data << DangerCard.new("Средняя угроза", 3, Element::Neutral, 2)
      @data << DangerCard.new("Большая угроза", 7, Element::Neutral, 2)
      @data << ActionCard.new("Молния", 2, Element::Neutral, 2)
      @data << ActionCard.new("Большая Молния", 5, Element::Neutral, 5)
      @data << EnchantCard.new("Тишина", 3, Element::Neutral, 2)
      @data << EnchantCard.new("Изоляция", 3, Element::Neutral, 1)
      @data << EnchantCard.new("Противофаза", 1, Element::Neutral, 0)
      @data << EnchantCard.new("Рассеивание", 3, Element::Neutral, 0)
      @data << SourceCard.new("Малый резервуар", 2, Element::Neutral, 2)
      @data << SourceCard.new("Большой резервуар", 5, Element::Neutral, 5)
    end

    def sample : Card
      @data.sample
    end
  end
end
