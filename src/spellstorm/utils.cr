
module Spellstorm


CARD_WIDTH = 120
CARD_HEIGHT = 160

end

def new_text(x,y,str,color)
  atext = SF::Text.new
  atext.font = Engine::Font["default.ttf"]
  atext.string = str
  atext.character_size = 24
  atext.color = color
  atext.position = vec(x,y)
  #atext.style = (SF::Text::Bold | SF::Text::Underlined)
  return atext
end
