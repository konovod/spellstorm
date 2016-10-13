require "./spec_helper"

include Spellstorm

SMALL_SHIELD = ShieldCard.new("Малый щит", 2, Element::Neutral, 2)
BIG_SHIELD = ShieldCard.new("Большой щит", 6, Element::Neutral, 5)
SMALL_DANGER = DangerCard.new("Малая угроза", 1, Element::Neutral, 1)
BIG_DANGER = DangerCard.new("Большая угроза", 7, Element::Neutral, 3)


describe "Basic mechanics" do

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
    we.test_damage = 1
    game_state.next_turn
    enemy.count_cards(CardLocation::Hand).should eq(MAX_HP-1)
    enemy.count_cards(CardLocation::Deck).should eq(DECK_SIZE-MAX_HP)
    enemy.count_cards(CardLocation::Drop).should eq(1)
  end
  it "refilling hand" do
    we.test_damage = 0
    game_state.next_turn
    enemy.count_cards(CardLocation::Hand).should eq(MAX_HP)
    enemy.count_cards(CardLocation::Deck).should eq(DECK_SIZE-MAX_HP-1)
    enemy.count_cards(CardLocation::Drop).should eq(1)
  end
  it "sum of counts ok" do
    CardLocation.values.sum{ |loc| we.count_cards(loc)}.should eq DECK_SIZE
    CardLocation.values.sum{ |loc| enemy.count_cards(loc)}.should eq DECK_SIZE
  end
  it "possible_actions : play" do
    we.test_mana[0] = 0
    we.possible_actions.size.should eq 0
    we.test_mana[0] = 100
    we.possible_actions.size.should eq MAX_HP
    we.possible_actions.each &.should be_a ActionPlay
  end
  it "playing card" do
    what = we.at_location(CardLocation::Hand).first
    card = what.card
    element = card.element
    loc = card.field_location(what)
    we.test_mana[element.to_i] = card.cost/2
    we.test_mana[0] = 100
    old = we.test_mana.sum
    we.possible_actions.first.perform
    we.count_cards(CardLocation::Hand).should eq(MAX_HP-1)
    we.count_cards(loc).should eq(1)
    (we.test_mana.sum).should eq old - card.cost
  end
end

describe "Damage system" do
  #patch decks
  decks = {Deck.new, Deck.new}
  decks.each &.generate
  decks[0].cards[0] = BIG_SHIELD
  decks[1].cards[0] = SMALL_DANGER
  #new game
  game_state = GameState.new(decks)
  we = game_state.parts[Player::First.to_i]
  enemy = game_state.parts[Player::Second.to_i]
  #get cards to hand
  {we, enemy}.each do |x|
    loop do
      CardStateMutable.new(x, 0).move(CardLocation::Hand)
      x.refill_hand
      break if x.card_state(0).location == CardLocation::Hand
    end
  end
  #sanity check
  it "prepare for damage" do
    we.card_state(0).location.should eq CardLocation::Hand
    enemy.count_cards(CardLocation::Hand).should eq MAX_HP
  end
  it "small atack don't penetrate big shield" do
    we.test_mana[0] = 100
    enemy.test_mana[0] = 100
    we.possible_actions.first.perform
    enemy.possible_actions.first.perform
    game_state.next_turn
    we.hp.should eq MAX_HP
    we.card_state(0).hp.should eq BIG_SHIELD.power - SMALL_DANGER.power
  end
  it "but shield fails over time" do
    10.times {game_state.next_turn}
    we.hp.should eq MAX_HP - SMALL_DANGER.power
    we.card_state(0).location.should eq CardLocation::Drop
  end

end
