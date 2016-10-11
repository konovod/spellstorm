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
  it "sum of counts ok" do
    CardLocation.values.sum{ |loc| we.count_cards(loc)}.should eq DECK_SIZE
    CardLocation.values.sum{ |loc| enemy.count_cards(loc)}.should eq DECK_SIZE
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
  #tests of damage system
  #first, preparation
  attacks = CardsDB.instance.data.select(&.is_a? DangerCard).sort_by(&.power)
  shields = CardsDB.instance.data.select(&.is_a? ShieldCard).sort_by(&.power)
  big_attack = attacks.last
  small_attack = attacks.first
  big_shield = shields.last
  small_shield = shields.first
  it "cards set not broken" do
    attacks.size.should be > 1
    shields.size.should be > 1
    small_attack.power.should be < big_shield.power
    big_attack.power.should be > small_shield.power
  end
  #patch decks
  decks[0].cards[0] = big_attack
  decks[0].cards[1] = big_shield
  decks[1].cards[0] = small_shield
  decks[1].cards[1] = small_attack
  #new game
  game_state = GameState.new(decks)
  we = game_state.parts[Player::First.to_i]
  enemy = game_state.parts[Player::Second.to_i]
  #get cards to hand
  {we, enemy}.each do |x|
    loop do
      x.move_card 0, CardLocation::Hand
      x.move_card 1, CardLocation::Hand
      x.refill_hand
      break if x.card_state(0).location == CardLocation::Hand && x.card_state(1).location == CardLocation::Hand
    end
  end
  #sanity check
  it "prepare for damage" do
    we.card_state(1).location.should eq CardLocation::Hand
    enemy.count_cards(CardLocation::Hand).should eq MAX_HP
  end
  it "small atack don't penetrate big shield" do
    we.mana[0] = 100
    enemy.mana[0] = 100
    we.possible_actions[1].perform(game_state)
    enemy.possible_actions[1].perform(game_state)
    game_state.next_turn
    we.hp.should eq MAX_HP
    we.card_state(1).hp.should eq big_shield.power - small_attack.power
  end
  it "but shield fails over time" do
    5.times {game_state.next_turn}
    we.hp.should eq MAX_HP - small_attack.power
    we.card_state(1).location.should eq CardLocation::Drop
  end






end
