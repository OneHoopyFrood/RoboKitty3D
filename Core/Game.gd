extends Node3D

@export var num_cubes: int = 100
@export var spawn_radius: float = 50.0

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var cube_scene = preload('res://World/Cube/Cube.tscn')

func _ready():
  rng.randomize()
  add_child(_create_ground_plane())

  # Cubes
  var cubes = _generate_cubes()
  for cube in cubes:
    add_child(cube)

func _generate_cubes() -> Array:
  var cubes: Array[Cube];
  for i in range(num_cubes):
    var cube: Cube = cube_scene.instantiate() as Cube

    cube.randomize_bobbing(rng)

    cube.position = Vector3(
      rng.randf_range(-spawn_radius, spawn_radius),
      0.5,
      rng.randf_range(-spawn_radius, spawn_radius)
    )

    cubes.append(cube)
  return cubes

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
