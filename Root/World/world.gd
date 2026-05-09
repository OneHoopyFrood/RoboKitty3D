extends Node3D

signal kitten_found

@export var num_nodes: int = 100
@export var step_size: float = 1.0
var board_size: int = 50

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var node_scene = preload('res://Root/World/Symbol/Symbol.tscn')
const KITTEN_BLURB: String = "You found kitten! Way to go, robot."

var _blurbs: Array[String] = []
var _cell_to_symbol: Dictionary = {}

func _ready():
  rng.randomize()
  _cell_to_symbol.clear()

  # Load and shuffle blurbs from NKIs.txt
  _load_blurbs()

  # Floaty Bits
  var nodes = _generate_nodes()
  for node in nodes:
    add_child(node)

  # Connect player rotation signal to all interaction nodes
  var player = get_node_or_null("Player")
  print_debug("World: Looking for player at Player: ", player)
  if player and player.has_signal("player_movement"):
    print_debug("World: Found player with player_movement signal, connecting ", nodes.size(), " nodes")
    for node in nodes:
      if node.has_method("face_player") and not player.player_movement.is_connected(node.face_player):
        player.player_movement.connect(node.face_player)
        print_debug("World: Connected ", node.name, " to player_movement signal")
  else:
    print_debug("World: Failed to find player or signal!")

func _generate_nodes() -> Array[Symbol]:
  var nodes: Array[Symbol] = []
  var used_positions: Array[Vector2i] = [Vector2i(0, 0)] # Player spawn cell
  # Choose one generated symbol to become kitten.
  var kitten_index: int = rng.randi_range(0, max(num_nodes - 1, 0))

  for i in range(num_nodes):
    var node: Symbol = node_scene.instantiate()
    node.randomize_bobbing(rng)
    node.randomize_color(rng)

    if i == kitten_index:
      node.is_kitten = true
      node.blurb = KITTEN_BLURB
      if node.has_signal("kitten_found") and not node.kitten_found.is_connected(_on_kitten_found):
        node.kitten_found.connect(_on_kitten_found)
    elif _blurbs.size() > 0:
      node.blurb = _blurbs[i % _blurbs.size()]

    var cell := random_cell() # Returns Vector2i
    while used_positions.has(cell):
      cell = random_cell()
    used_positions.push_back(cell)

    _cell_to_symbol[cell] = node
    node.position = cell_to_world(cell)

    nodes.append(node)
  return nodes

func random_cell() -> Vector2i:
  var spawn_radius = int(board_size / 2) - 1
  return Vector2i(
    rng.randi_range(-spawn_radius, spawn_radius),
    rng.randi_range(-spawn_radius, spawn_radius)
  )

func _load_blurbs() -> void:
  var file = FileAccess.open("res://Assets/NKIs.txt", FileAccess.READ)
  if file:
    while not file.eof_reached():
      var line = file.get_line().strip_edges()
      if line.length() > 0:
        _blurbs.append(line)
    file.close()

    # Shuffle blurbs so each playthrough is different
    _blurbs.shuffle()

    print_debug("World: Loaded ", _blurbs.size(), " blurbs from NKIs.txt")
  else:
    print_debug("World: Failed to load NKIs.txt")

## Convert 3D world position to 2D floor grid cell.
## Vector2i.x = world X, Vector2i.y = world Z.
## World Y (vertical height) is ignored; occupancy is purely horizontal so bobbing doesn't affect collision.
func world_to_cell(world_pos: Vector3) -> Vector2i:
  return Vector2i(
    round(world_pos.x / step_size),
    round(world_pos.z / step_size)
  )

func cell_to_world(cell: Vector2i) -> Vector3:
  return Vector3(cell.x * step_size, 0.8, cell.y * step_size)

## Check if a floor grid cell is within gameplay bounds.
func is_in_bounds(cell: Vector2i) -> bool:
  var boundary := int(board_size / 2)
  return abs(cell.x) < boundary and abs(cell.y) < boundary

## Look up the symbol occupying a floor grid cell (2D xz address).
## Returns null if cell is empty or out of bounds.
func get_symbol_at_cell(cell: Vector2i) -> Symbol:
  if _cell_to_symbol.has(cell):
    return _cell_to_symbol[cell] as Symbol
  return null

## Check if a floor grid cell is blocked (out of bounds or occupied by symbol).
func is_cell_blocked(cell: Vector2i) -> bool:
  return not is_in_bounds(cell) or get_symbol_at_cell(cell) != null

func _on_kitten_found() -> void:
  kitten_found.emit()
