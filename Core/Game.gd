extends Node3D

@export var num_nodes: int = 100
@export var spawn_radius: int = 50

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

#var node_scene = preload('res://World/Cube/Cube.tscn')
var node_scene = preload('res://World/Symbol/Symbol.tscn')

func _ready():
  rng.randomize()
  add_child(_create_ground_plane())

  # Cubes
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
      0.5,
      rng.randf_range(-spawn_radius, spawn_radius)
    )

    nodes.append(node)
  return nodes

func _create_ground_plane() -> MeshInstance3D:
  var ground = MeshInstance3D.new()

  var plane = PlaneMesh.new()
  plane.size = Vector2(spawn_radius * 2, spawn_radius * 2)
  plane.subdivide_width = 20
  plane.subdivide_depth = 20
  ground.mesh = plane

  #var shader = preload('res://World/InfiniteGrid.gdshader')
  #var shader_mat = ShaderMaterial.new()
  #shader_mat.shader = shader
  #ground.set_surface_override_material(0, shader_mat)

  return ground
