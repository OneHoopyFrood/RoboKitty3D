extends Node3D

@export var num_cubes: int = 100
@export var spawn_radius: float = 50.0

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready():
	rng.randomize()
	add_child(_create_ground_plane())
	var cubes = _generate_cubes()
	for cube in cubes:
		add_child(cube)

func _generate_cubes() -> Array:
	var cubes: Array = []
	for i in range(num_cubes):
		var cube = MeshInstance3D.new()
		cube.mesh = BoxMesh.new()

		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(rng.randf(), rng.randf(), rng.randf())
		cube.set_surface_override_material(0, mat)

		cube.position = Vector3(
			rng.randf_range(-spawn_radius, spawn_radius),
			0.5,
			rng.randf_range(-spawn_radius, spawn_radius)
		)

		# Optional: add a label above each cube
		var label = Label3D.new()
		label.text = char(65 + rng.randi_range(0, 25))
		label.position = Vector3(0, 1.1, 0)
		cube.add_child(label)

		cubes.append(cube)
	return cubes

func _create_ground_plane() -> MeshInstance3D:
	var ground = MeshInstance3D.new()

	var plane = PlaneMesh.new()
	plane.size = Vector2(spawn_radius * 2, spawn_radius * 2)
	plane.subdivide_width = 20
	plane.subdivide_depth = 20
	ground.mesh = plane

	var shader = load("res://Shaders/InfiniteGrid.gdshader")
	var shader_mat = ShaderMaterial.new()
	shader_mat.shader = shader
	ground.set_surface_override_material(0, shader_mat)

	return ground
