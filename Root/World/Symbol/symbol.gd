class_name Symbol
extends Node3D

signal bumped(blurb: String)
signal kitten_found

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
const DIM_GLOW_TIME: float = 0.2

########################
## Active values
########################
var bob_amplitude: float = DEFAULT_AMPLITUDE
var bob_speed: float = DEFAULT_SPEED
var base_y: float # Height to float (centerpoint of symbol)
var color: Color = DEFAULT_COLOR
var symbol: String
var blurb: String = ""
var is_kitten: bool = false
var is_bumped: bool = false

# Private
var _time: float = 0.0
var _mesh: MeshInstance3D
var _rotation_tween: Tween
var _dim_tween: Tween
var _text_mesh: TextMesh
var _options: Node

########################
## Lifecycle
########################
func _ready() -> void:
  _mesh = get_node("Mesh") as MeshInstance3D
  _options = get_node_or_null("/root/GameOptions")

  symbol = random_symbol()
  # Make this a unique TextMesh.
  _mesh.mesh = _mesh.mesh.duplicate()
  _text_mesh = _mesh.mesh as TextMesh
  _text_mesh.text = symbol

  var box_size = _mesh.get_aabb().size
  # Make sure the symbol isn't in the ground or too high.
  base_y = clamp(global_position.y, box_size.y / 2, MAX_Y)

  # Add undim.
  _mesh.material_overlay = StandardMaterial3D.new()
  _mesh.material_overlay.emission_enabled = true
  _mesh.material_overlay.emission_energy_multiplier = 1.0

  set_color(color)
  _sync_to_options()

func _process(delta: float) -> void:
  _time += delta
  var offset = sin(_time * bob_speed) * bob_amplitude
  global_position.y = base_y + offset
  _sync_to_options()

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
  _mesh.material_overlay.albedo_color = color
  _mesh.material_overlay.emission = color

func randomize_bobbing(rng: RandomNumberGenerator) -> void:
  bob_amplitude = rng.randf_range(MIN_AMPLITUDE, MAX_AMPLITUDE)
  bob_speed = rng.randf_range(MIN_SPEED, MAX_SPEED)

func randomize_color(rng: RandomNumberGenerator) -> void:
  color = Color.from_hsv(rng.randf(), 0.8, 1.0) # Saturation is fixed for consistency.
  if _mesh != null:
    set_color(color)

## Flip direction so symbol faces toward player (opposite of where player looks).
func face_player(direction: Vector3) -> void:
  var opposite_dir = - direction
  var target_rotation_y = rad_to_deg(atan2(opposite_dir.x, opposite_dir.z))

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
func bump(do_blurb: bool = true) -> void:
  print_debug("Symbol ", symbol, " interacted with")
  is_bumped = true
  if do_blurb:
    bumped.emit(blurb)
  if is_kitten:
    kitten_found.emit()


## Dim the symbol's color and emission
func dim() -> void:
  var dimmed_color := color.lerp(Color(0.65, 0.65, 0.65, color.a), 0.6)
  _tween_glow(dimmed_color, false)


## Undim (restore) the symbol's color and emission
func undim() -> void:
  _tween_glow(color, true)

func _tween_glow(target_color: Color, bright_glow: bool) -> void:
  if _dim_tween:
    return # Don't start a new tween if we're already tweening. This prevents visual glitches from rapidly toggling visited state.

  var target_emission_multiplier: float = 1.0 if bright_glow else 0.02

  _dim_tween = create_tween()
  _dim_tween.tween_property(_mesh.material_overlay, "albedo_color", target_color, DIM_GLOW_TIME)
  _dim_tween.tween_property(_mesh.material_overlay, "emission_energy_multiplier", target_emission_multiplier, DIM_GLOW_TIME)


func _sync_to_options() -> void:
  if not _options or "visited_dimming" not in _options:
    return

  var is_currently_dimmed: bool = _mesh.material_overlay.emission_energy_multiplier < 0.1

  if bool(_options.visited_dimming):
    if is_bumped and not is_currently_dimmed:
      dim()
    elif not is_bumped and is_currently_dimmed:
      undim()


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
