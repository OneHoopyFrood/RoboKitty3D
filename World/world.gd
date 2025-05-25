extends Node3D

@export var num_nodes: int = 100
@export var spawn_radius: int = 25

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
  for i in range(num_nodes):
    var node := node_scene.instantiate()

    node.randomize_bobbing(rng)

    node.position = Vector3(
      rng.randf_range(-spawn_radius, spawn_radius),
      1,
      rng.randf_range(-spawn_radius, spawn_radius)
    )

    nodes.append(node)
  return nodes
