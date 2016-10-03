
module Spellstorm


CARD_WIDTH = 120
CARD_HEIGHT = 160

CARD_POS = {
  CardState::Deck => vec(10,10),
  CardState::Hand => vec(Engine::SCREENX / 2, 50),
  CardState::Field => vec(20, Engine::SCREENY / 2 - CARD_WIDTH - 10),
  CardState::Drop => vec(Engine::SCREENX-CARD_WIDTH-10, 10),
}
CARD_DELTA = {
  CardState::Deck => vec(5,5),
  CardState::Hand =>  vec(20, 5),
  CardState::Field =>  vec(70, 0),
  CardState::Drop =>  vec(20, 0),
}


enum Player
  First
  Second
end

end

def new_text(x,y,str,*, size=12, color=SF::Color::Black, centered = false, style = SF::Text::Regular) : SF::Text
  atext = SF::Text.new
  atext.font = Engine::Font["default.ttf"]
  atext.string = str
  atext.character_size = size
  atext.color = color
  atext.position = vec(x,y)
  #atext.style = (SF::Text::Bold | SF::Text::Underlined)
  atext.style = style
  atext.origin = vec(atext.local_bounds.width/2, atext.local_bounds.height/2) if centered

  return atext
end
