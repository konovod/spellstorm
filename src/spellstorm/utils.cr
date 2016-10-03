module Spellstorm
  CARD_WIDTH  = 120
  CARD_HEIGHT = 160

  CARD_COORDS = {
    CardState::Deck  => {
      pos: vec(10, 10),
      delta: vec(5, 5),
      angle0: 0.0, dangle: 0.0},
    CardState::Hand  => {
      pos: vec(350, 10),
      delta: vec(20, 5),
      angle0: 0.0, dangle: 0.0},
    CardState::Field => {
      pos: vec(20, Engine::SCREENY / 2 - CARD_WIDTH - 10),
      delta: vec(70, 0),
      angle0: 0.0, dangle: 0.0},
    CardState::Drop  => {
      pos: vec(CARD_WIDTH + 50, 10),
      delta: vec(0, 0),
      angle0: 0.0, dangle: 0.0},
  }

  enum Player
    First
    Second
  end
end

def new_text(x, y, str, *, size = 12, color = SF::Color::Black, centered = false, style = SF::Text::Regular) : SF::Text
  atext = SF::Text.new
  atext.font = Engine::Font["default.ttf"]
  atext.string = str
  atext.character_size = size
  atext.color = color
  atext.position = vec(x, y)
  # atext.style = (SF::Text::Bold | SF::Text::Underlined)
  atext.style = style
  atext.origin = vec(atext.local_bounds.width/2, atext.local_bounds.height/2) if centered

  return atext
end
