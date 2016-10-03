
module Spellstorm


CARD_WIDTH = 120
CARD_HEIGHT = 160

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
