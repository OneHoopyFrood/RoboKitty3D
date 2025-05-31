class_name Symbol
extends BaseInteractionNode

########################
## Active values
########################
var symbol: String

# Private
var _textMesh: TextMesh

########################
## Lifecycles
########################
func _ready():
  super._ready()
  symbol = random_symbol()

  # Make this a unique TextMesh
  _mesh.mesh = _mesh.mesh.duplicate()
  _textMesh = _mesh.mesh as TextMesh
  _textMesh.text = symbol

########################
## Methods
########################
#Returns a random character from ASCII 33 to 126
func random_symbol() -> String:
  # Pulls from the same set of characters as the terminal version
  var ascii_code: int
  while [0, 37].has(ascii_code): # 37 is %, which has display issues in this font
    ascii_code = randi_range(33, 126)
  return char(ascii_code)
