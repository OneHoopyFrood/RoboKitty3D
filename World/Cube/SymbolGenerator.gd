# SymbolGenerator.gd
# Generates ImageTextures with a single ASCII character rendered to them.

extends Object
class_name SymbolGenerator

#Returns a random character from ASCII 33 to 126
static func random_symbol() -> String:
  # Pulls from the same set of characters as the terminal version
  var ascii_code := randi_range(33, 126)
  return char(ascii_code)

static func generate_texture(
    symbol: String,
    font: Font,
    texture_size: Vector2i = Vector2i(128, 128),
    font_size: int = 96,
    color: Color = Color.WHITE
  ) -> ImageTexture:
  # Create an image and draw to it
  var img := Image.create(texture_size.x, texture_size.y, false, Image.FORMAT_RGBA8)
  img.fill(Color(0, 0, 0, 0))  # Transparent background

  var draw_pos := Vector2(
     (texture_size.x - font.get_string_size(symbol, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size).x) / 2,
     (texture_size.y + font.get_height(font_size)) / 2
  )

  font.draw_string(img, draw_pos, symbol, HORIZONTAL_ALIGNMENT_CENTER, texture_size.x, font_size, color)

  # Convert image to texture
  var tex := ImageTexture.create_from_image(img)
  return tex
