require "./utils.cr"
require "./engine/*"

module Spellstorm

class TableSide
  def initialize (player)
    @data = Hash(CardState, Array(Card)).new
    CardState.values.each do |p|
      @data[p] = Array(Card).new
    end
  end

  #todo - macroses
  def deck
    @data[CardState::Deck]
  end

  def hand
    @data[CardState::Hand]
  end

  def on_table
    @data[CardState::Table]
  end

  def drop
    @data[CardState::Drop]
  end

  def draw(target, states, my_turn)
    drop.last.draw(target, states, 0) unless drop.empty?
    on_table.each_with_index { |card, i| card.draw(target, states, i) }
    hand.each_with_index { |card, i| card.draw(target, states, i, my_turn) }
    deck.first.draw(target, states, 0, false) unless deck.empty?
  end

  def new_game(adeck)
    drop.clear
    on_table.clear
    hand.clear
    deck.clear
    deck.concat adeck.data.shuffle
    deck.each &.reset
    5.times { draw_card }
  end

  def draw_card
    return if deck.empty?
    card = deck.pop
    card.state = CardState::Hand
    @data[CardState::Hand] << card
  end

end


class Table

  def initialize
    @sides = Hash(Player, TableSide).new
    Player.values.each do |p|
      @sides[p] = TableSide.new(p)
    end
  end

  def draw(target, states, cur_player)
      @sides[Player::First].draw(target, states, cur_player == Player::First)
      #states.transform.rotate(45)
      states.transform.translate({0, Engine::SCREENY})
      states.transform.scale({1,-1})
      @sides[Player::Second].draw(target, states, cur_player == Player::Second)
  end

  def new_game(decks)
    Player.values.zip(decks.to_a).each do |p, d|
      @sides[p].new_game(d)
    end

  end

end


end
