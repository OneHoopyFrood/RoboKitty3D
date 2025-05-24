# InteractionNode
# Abstract base class for things that float about and can be interacted with

class_name BaseInteractionNode
extends Node3D

########################
## CONSTANTS
########################
# Clamp values
const MIN_AMPLITUDE: float = 0.1
const MAX_AMPLITUDE: float = 0.3
const MIN_SPEED: float = 0.5
const MAX_SPEED: float = 2.0
const MAX_Y: float = 2.0

# Defaults
const DEFAULT_AMPLITUDE: float = 0.25
const DEFAULT_SPEED: float = 1.0
const DEFAULT_Y: float = 1.0

########################
## Active values
########################
var bob_amplitude: float = DEFAULT_AMPLITUDE
var bob_speed: float = DEFAULT_SPEED
var base_y: float # Height to float (centerpoint of box)

# Private
var _time: float = 0.0
var _mesh: MeshInstance3D

########################
## Lifecycle
########################
func _ready():
  _mesh = get_node("Mesh") as MeshInstance3D
  var box_size = _mesh.get_aabb().size
  # Make sure the box isn't in the ground or too high.
  base_y = clamp(global_position.y, box_size.y / 2, MAX_Y)

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

func randomize_bobbing(rng: RandomNumberGenerator):
  bob_amplitude = rng.randf_range(MIN_AMPLITUDE, MAX_AMPLITUDE)
  bob_speed = rng.randf_range(MIN_SPEED, MAX_SPEED)
