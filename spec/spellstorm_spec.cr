require "./spec_helper"

include Spellstorm

describe Spellstorm do

  decks = {Deck.new, Deck.new}
  it "decks generation" do
    decks.each &.generate
    decks.each {|deck| deck.cards.size.should eq(DECK_SIZE)}
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
  it "possible_actions : play" do
    we.mana[0] = 0
    we.possible_actions.size.should eq 0
    we.mana[0] = 100
    we.possible_actions.size.should eq MAX_HP
    we.possible_actions.each &.should be_a ActionPlay
  end
  it "playing card" do
    index = we.at_location(CardLocation::Hand).first
    card = we.deck.cards[index]
    element = card.element
    loc = card.field_location(we.card_state(index))
    we.mana[element.to_i] = card.cost/2
    we.mana[0] = 100
    old = we.mana.sum
    we.possible_actions.first.perform(game_state)
    we.count_cards(CardLocation::Hand).should eq(MAX_HP-1)
    we.count_cards(loc).should eq(1)
    (we.mana.sum).should eq old - card.cost
  end



end
