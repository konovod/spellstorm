require "./utils.cr"
require "./engine/*"

module Spellstorm

class TableSide
  def initialize (player)
    @deck = Array(Card).new
    @drop = Array(Card).new
    @on_table = Array(Card).new
  end

  def draw(target, my_turn)
    #todo - draw decks
    @drop.last.draw(target, 0) unless @drop.empty?
    @on_table.each_with_index { |card, i| card.draw(target, i) }
    @deck.each_with_index { |card, i| card.draw(target, i, my_turn) }
  end

end


class Table

  def initialize
    @sides = Hash(Player, TableSide).new
    Player.values.each do |p|
      @sides[p] = TableSide.new(p)
    end
  end

  def draw(target, cur_player)
    Player.values.each do |p|
      @sides[p].draw(target, p == cur_player)
    end
  end

end


end
