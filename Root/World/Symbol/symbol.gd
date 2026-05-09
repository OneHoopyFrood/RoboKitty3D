class_name Symbol
extends Node3D

signal bumped(blurb: String)

########################
## CONSTANTS
########################
# Clamp values
const MIN_AMPLITUDE: float = 0.1
const MAX_AMPLITUDE: float = 0.3
const MIN_SPEED: float = 0.5
const MAX_SPEED: float = 2.0
const MAX_Y: float = 1.5

# Defaults
const DEFAULT_AMPLITUDE: float = 0.25
const DEFAULT_SPEED: float = 1.0
const DEFAULT_COLOR: Color = Color.GREEN

########################
## Active values
########################
var bob_amplitude: float = DEFAULT_AMPLITUDE
var bob_speed: float = DEFAULT_SPEED
var base_y: float # Height to float (centerpoint of symbol)
var color: Color = DEFAULT_COLOR
var symbol: String
var blurb: String = ""

# Private
var _time: float = 0.0
var _mesh: MeshInstance3D
var _rotation_tween: Tween
var _text_mesh: TextMesh

########################
## Lifecycle
########################
func _ready() -> void:
  _mesh = get_node("Mesh") as MeshInstance3D

  symbol = random_symbol()
  # Make this a unique TextMesh.
  _mesh.mesh = _mesh.mesh.duplicate()
  _text_mesh = _mesh.mesh as TextMesh
  _text_mesh.text = symbol

  var box_size = _mesh.get_aabb().size
  # Make sure the symbol isn't in the ground or too high.
  base_y = clamp(global_position.y, box_size.y / 2, MAX_Y)

  # Add glow.
  _mesh.material_overlay = StandardMaterial3D.new()
  _mesh.material_overlay.emission_enabled = true
  _mesh.material_overlay.emission = color

func _process(delta: float) -> void:
  _time += delta
  var offset = sin(_time * bob_speed) * bob_amplitude
  global_position.y = base_y + offset

########################
## Methods
########################
func configure_bobbing(
  amplitude: float,
  speed: float
) -> void:
  bob_amplitude = clamp(amplitude, MIN_AMPLITUDE, MAX_AMPLITUDE)
  bob_speed = clamp(speed, MIN_SPEED, MAX_SPEED)

func set_color(new_color: Color) -> void:
  color = new_color
  if _mesh != null and _mesh.material_overlay != null:
    _mesh.material_overlay.emission = color

func randomize_bobbing(rng: RandomNumberGenerator) -> void:
  bob_amplitude = rng.randf_range(MIN_AMPLITUDE, MAX_AMPLITUDE)
  bob_speed = rng.randf_range(MIN_SPEED, MAX_SPEED)

func randomize_color(rng: RandomNumberGenerator) -> void:
  color = Color.from_hsv(rng.randf(), 0.8, 1.0) # Saturation is fixed for consistency.
  if _mesh != null:
    set_color(color)

func face_player(direction: Vector3) -> void:
  print_debug("face_player called on ", name, " with direction: ", direction)
  # Flip direction so symbol faces toward player (opposite of where player looks).
  var opposite_dir = - direction
  var target_rotation_y = rad_to_deg(atan2(opposite_dir.x, opposite_dir.z))
  print_debug("  -> target_rotation_y: ", target_rotation_y)

  if _rotation_tween:
    _rotation_tween.kill()

  var current_rotation_y = rotation_degrees.y
  var delta_rotation_y = wrapf(target_rotation_y - current_rotation_y, -180.0, 180.0)
  var shortest_target_rotation_y = current_rotation_y + delta_rotation_y

  _rotation_tween = create_tween()
  _rotation_tween.set_trans(Tween.TRANS_BACK)
  _rotation_tween.set_ease(Tween.EASE_OUT)
  _rotation_tween.tween_property(self , "rotation_degrees:y", shortest_target_rotation_y, 1.2)

## Handle interaction from player bump. Emits signal with this symbol as argument.
func bump() -> void:
  print_debug("Symbol ", symbol, " interacted with")
  bumped.emit(blurb)

## Returns the blurb text for this symbol.
func get_blurb() -> String:
  return blurb

# Returns a random character from ASCII 33 to 126.
func random_symbol() -> String:
  # Pulls from the same set of characters as the terminal version.
  var ascii_code: int
  while [0, 37].has(ascii_code): # 37 is %, which has display issues in this font.
    ascii_code = randi_range(33, 126)
  return char(ascii_code)
