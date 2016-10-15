require "./spec_helper"

include Spellstorm

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
    we.own_mana = 0
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

SMALL_SHIELD = ShieldCard.new("Малый щит", 2, Element::Neutral, 2)
BIG_SHIELD = ShieldCard.new("Большой щит", 6, Element::Neutral, 5)
SMALL_DANGER = DangerCard.new("Малая угроза", 1, Element::Neutral, 1)
BIG_DANGER = DangerCard.new("Большая угроза", 7, Element::Neutral, 3)

def prepare_cards(card1, card2)
  #patch decks
  decks = {Deck.new, Deck.new}
  decks.each &.generate
  decks[0].cards[0] = card1
  decks[1].cards[0] = card2
  #new game
  game_state = GameState.new(decks)
  #get cards to hand
  game_state.parts.each do |x|
    x.at_location(CardLocation::Hand).each &.move(CardLocation::Drop)
    CardStateMutable.new(x, 0).move(CardLocation::Hand)
    x.refill_hand
  end
  game_state
end

describe "Damage system" do
  game_state = prepare_cards BIG_SHIELD, SMALL_DANGER
  we = game_state.parts[Player::First.to_i]
  enemy = game_state.parts[Player::Second.to_i]
  it "prepare for damage" do
    we.card_state(0).location.should eq CardLocation::Hand
    enemy.count_cards(CardLocation::Hand).should eq MAX_HP
  end
  it "small attack don't penetrate big shield" do
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
  #opposite situation
  game_state = prepare_cards BIG_DANGER, SMALL_SHIELD
  we = game_state.parts[Player::First.to_i]
  enemy = game_state.parts[Player::Second.to_i]
  it "big attack penetrate small shield" do
    we.test_mana[0] = 100
    enemy.test_mana[0] = 100
    we.possible_actions.first.perform
    enemy.possible_actions.first.perform
    game_state.next_turn
    enemy.hp.should eq MAX_HP - (BIG_DANGER.power - SMALL_SHIELD.power)
    enemy.card_state(0).hp.should eq 0
  end
  it "and shield is broken on next turn" do
    game_state.next_turn
    enemy.hp.should eq MAX_HP - BIG_DANGER.power
    enemy.card_state(0).location.should eq CardLocation::Drop
  end
end

ELEMENT1 = Element::Fire
ELEMENT2 = Element::Earth
SOURCE1 = SourceCard.new("Малый источник", 2, ELEMENT1, 2)
SOURCE2 = SourceCard.new("Большой источник", 5, ELEMENT2, 5)

def prepare_source_cards(card1, card2)
  #patch decks
  decks = {Deck.new, Deck.new}
  decks.each &.generate
  decks[0].cards[0] = card1
  decks[0].cards[1] = card2
  #new game
  game_state = GameState.new(decks)
  we = game_state.parts.first
  enemy = game_state.parts.last
  enemy.test_damage = MAX_HP-2
  game_state.next_turn
  #drop current cards
  we.at_location(CardLocation::Hand).each &.move(CardLocation::Drop)
  CardStateMutable.new(we, 0).move(CardLocation::Hand)
  CardStateMutable.new(we, 1).move(CardLocation::Hand)
  game_state
end

describe "sources system" do
  game_state = prepare_source_cards SOURCE1, SOURCE2
  we = game_state.parts.first
  src1 = we.card_state(0)
  it "playing a source costs mana" do
    we.own_mana = SOURCE1.cost
    we.possible_actions[0].perform
    we.own_mana.should eq 0
    src1.hp.should eq 0
  end
  it "mana of same color accumulates" do
    we.mana_spent[ELEMENT1.to_i] = 0
    we.own_mana = 1
    we.pay_mana ELEMENT1, 1
    game_state.next_turn
    src1.hp.should eq 1
  end
  it "mana of wrong color don't accumulates" do
    we.own_mana = 1
    we.pay_mana ELEMENT2, 1
    src1.hp.should eq 1
    game_state.next_turn
    src1.hp.should eq 1
  end
  it "mana of same color is used" do
    we.own_mana = 0
    src1.hp.should eq 1
    we.max_mana(ELEMENT1).should eq 1
    we.pay_mana ELEMENT1, 1
    src1.hp.should eq 0
    we.max_mana(ELEMENT1).should eq 0
    we.mana_spent[ELEMENT1.to_i] = 0
    game_state.next_turn
    src1.hp.should eq 0
  end
  it "mana sources overflow and blows on next turn" do
    we.own_mana = 10
    we.pay_mana ELEMENT1, 10
    game_state.next_turn
    src1.hp.should eq src1.card.power
    src1.location.should eq CardLocation::FieldSource
    game_state.next_turn
    src1.location.should eq CardLocation::Drop
  end

end
