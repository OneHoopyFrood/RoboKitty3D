extends Node3D

@export var num_nodes: int = 100
var board_size: int = 50

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

#var node_scene = preload('res://World/Cube/Cube.tscn')
var node_scene = preload('res://World/Symbol/Symbol.tscn')

func _ready():
  rng.randomize()

  # Floaty Bits
  var nodes = _generate_nodes()
  for node in nodes:
    add_child(node)

func _generate_nodes() -> Array[BaseInteractionNode]:
  var nodes: Array[BaseInteractionNode];
  var used_positions: Array[Vector3i] = []
  for i in range(num_nodes):
    var node := node_scene.instantiate()

    node.randomize_bobbing(rng)

    var pos: Vector3i = random_pos()
    while used_positions.has(pos): # If an overlap happens, choose another spot until you get a unique value
      pos = random_pos()
    used_positions.push_back(pos)
    node.position = pos

    nodes.append(node)
  return nodes

func random_pos() -> Vector3i:
  var spawn_radius = (board_size / 2) - 1
  return Vector3i(
      rng.randi_range(-spawn_radius, spawn_radius),
      1,
      rng.randi_range(-spawn_radius, spawn_radius)
    )
