require "./utils.cr"
require "./engine/*"

module Spellstorm

class TableSide
  def initialize (player)
    @deck = Array(Card).new
    @drop = Array(Card).new
    @on_table = Array(Card).new
  end

  def draw(target)
    #todo - draw decks
    @drop.last.draw(target) unless @drop.empty?
    @on_table.each(&.draw(target))
  end

end


class Table < Engine::GameObject

  def initialize(owner)
    super(owner, 0, 0)
    @sides = Hash(Player, TableSide).new
    Player.values.each do |p|
      @sides[p] = TableSide.new(p)
    end
  end

  def draw(target)
    Player.values.each do |p|
      @sides[p].draw(target)
    end
  end

end


end
