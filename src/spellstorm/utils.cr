module Spellstorm
  CARD_WIDTH  = 120
  CARD_HEIGHT = 160

  ANIM_SPEED = 20

  Y0 = Engine::SCREENY - CARD_HEIGHT

  CARD_COORDS = {
    CardState::Deck => {
      pos: vec(10, Y0 - 10),
      delta: vec(0, 2),
      angle0: 0.0, dangle: 0.0,
    },
    CardState::Hand => {
      pos: vec(CARD_WIDTH + 35, Y0 - 10),
      delta: vec(CARD_WIDTH + 5, 0),
      angle0: 0.0, dangle: 0.0,
    },
    CardState::Field => {
      pos: vec(10, Y0 - CARD_HEIGHT - 50),
      delta: vec(CARD_WIDTH + 5, 0),
      angle0: -20.0, dangle: 5.0,
    },
    CardState::Drop => {
      pos: vec(Engine::SCREENX+CARD_WIDTH*2, Y0),
      delta: vec(0, 0),
      angle0: 90.0, dangle: 5.0,
    },
  }

  enum Player
    First
    Second
  end
end

def new_text(x, y, str, *, size = 12, color = SF::Color::Black, centered = false, style = SF::Text::Regular) : SF::Text
  atext = SF::Text.new
  atext.font = Engine::Font["small.ttf"]
  atext.string = str
  atext.character_size = size
  atext.color = color
  atext.position = vec(x, y)
  # atext.style = (SF::Text::Bold | SF::Text::Underlined)
  atext.style = style
  atext.origin = vec(atext.local_bounds.width/2, atext.local_bounds.height/2) if centered

  return atext
end

def new_rect(x0, y0, width, height, *, thickness = 1, outline = SF::Color::Transparent, fill = SF::Color::Transparent, texture : (SF::Texture | Nil) = nil) : SF::RectangleShape
  result = SF::RectangleShape.new(vec(width, height))
  result.position = vec(x0, y0)
  result.texture = texture if texture
  result.outline_color = outline unless outline == SF::Color::Transparent
  result.outline_thickness = thickness
  result.fill_color = fill unless fill == SF::Color::Transparent
  return result
end
