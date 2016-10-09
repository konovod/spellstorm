require "./spec_helper"

include Spellstorm

describe Spellstorm do

  decks = {Deck.new, Deck.new}
  it "decks generation" do
    decks.each &.generate
    decks.each {|deck| deck.data.size.should eq(DECK_SIZE)}
  end
  game_state = GameState.new(decks)
  it "new game" do
    game_state.parts.each do |part|
      part.hp.should eq(MAX_HP)
      part.count_cards(CardLocation::Deck).should eq(DECK_SIZE-MAX_HP)
      part.count_cards(CardLocation::Hand).should eq(MAX_HP)
    end
  end
  we = game_state.parts[Player::First.to_i]
  enemy = game_state.parts[Player::Second.to_i]
  it "applying damage" do
    we.damage = 1
    game_state.next_turn
    enemy.count_cards(CardLocation::Hand).should eq(MAX_HP-1)
    enemy.count_cards(CardLocation::Deck).should eq(DECK_SIZE-MAX_HP)
    enemy.count_cards(CardLocation::Drop).should eq(1)
  end
  it "refilling hand" do
    we.damage = 0
    game_state.next_turn
    enemy.count_cards(CardLocation::Hand).should eq(MAX_HP)
    enemy.count_cards(CardLocation::Deck).should eq(DECK_SIZE-MAX_HP-1)
    enemy.count_cards(CardLocation::Drop).should eq(1)
  end

end
