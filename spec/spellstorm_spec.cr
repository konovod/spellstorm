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
      p part.counts
      part.hp.should eq(MAX_HP)
      part.count_cards(CardLocation::Deck).should eq(DECK_SIZE-MAX_HP)
      part.count_cards(CardLocation::Hand).should eq(MAX_HP)
    end
  end

end
