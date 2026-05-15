extends Node3D

signal kitten_found

const KITTEN_BLURB: String = "You found kitten! Way to go, robot."
const PETE_BLURB: String = "It's a cigar box. There's an inscription here... it reads: \"chik-chiky-boom?\""
const DEFAULT_PETE_CHANCE: float = 0.1 # % chance for Pete to spawn

@export var num_symbols: int = 100
@export var step_size: float = 1.0
@export var pete_chance: float = DEFAULT_PETE_CHANCE
var board_size: int = 50

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var symbol_scene = preload('res://Root/World/Symbol/Symbol.tscn')

var _blurbs: Array[String] = []
var _cell_to_symbol: Dictionary = {}
var _kitten: Symbol = null
var _pete: Symbol = null

func _ready():
  _apply_root_options()
  rng.randomize()
  _cell_to_symbol.clear()

  # Load and shuffle blurbs from NKIs.txt
  _load_blurbs()

  # Generate symbols and add them to the world.
  var symbols = _generate_symbols()
  for symbol in symbols:
    add_child(symbol)

  # Random chance to spawn Pete
  if rng.randf() <= pete_chance:
    spawn_pete()

  # Connect player rotation signal to all interaction symbols
  var player = get_node_or_null("Player")
  if player and player.has_signal("player_movement"):
    for symbol in symbols:
      if symbol.has_method("face_player") and not player.player_movement.is_connected(symbol.face_player):
        player.player_movement.connect(symbol.face_player)
  else:
    print_debug("World: Failed to find player or signal!")


func _apply_root_options() -> void:
  var options := get_node_or_null("/root/GameOptions")
  if options:
    board_size = int(options.board_size)
    num_symbols = int(options.nki_count)

func _generate_symbols() -> Array[Symbol]:
  var symbols: Array[Symbol] = []
  var used_positions: Array[Vector2i] = [Vector2i(0, 0)] # Player spawn cell

  # Choose one generated symbol to become kitten.
  var kitten_index: int = rng.randi_range(0, max(num_symbols - 1, 0))

  for i in range(num_symbols):
    var symbol: Symbol = symbol_scene.instantiate()
    symbol.randomize_bobbing(rng)
    symbol.randomize_color(rng)

    if i == kitten_index:
      symbol.blurb = KITTEN_BLURB
      symbol.bumped.connect(kitten_found.emit)
      _kitten = symbol
    else:
      if _blurbs.size() > 0:
        symbol.blurb = _blurbs[i % _blurbs.size()]

    var cell := random_cell() # Returns Vector2i
    while used_positions.has(cell):
      cell = random_cell()
    used_positions.push_back(cell)

    _cell_to_symbol[cell] = symbol
    symbol.position = cell_to_world(cell)

    symbols.append(symbol)
  return symbols


func get_symbols():
  return _cell_to_symbol.values() as Array[Symbol]


func random_cell() -> Vector2i:
  var spawn_radius = int(board_size / 2.0) - 1
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
  var inv_step: float = 1.0 / max(step_size, 0.0001)
  return Vector2i(
    round(world_pos.x * inv_step),
    round(world_pos.z * inv_step)
  )

func cell_to_world(cell: Vector2i) -> Vector3:
  return Vector3(cell.x * step_size, 0.8, cell.y * step_size)

## Check if a floor grid cell is within gameplay bounds.
func is_in_bounds(cell: Vector2i) -> bool:
  var boundary := int(board_size / 2.0)
  return abs(cell.x) < boundary and abs(cell.y) < boundary

## Look up the symbol occupying a floor grid cell (2D xz address).
## Returns null if cell is empty or out of bounds.
func get_symbol_at_cell(cell: Vector2i) -> Symbol:
  if _cell_to_symbol.has(cell):
    return _cell_to_symbol[cell] as Symbol
  return null

func get_random_symbol() -> Symbol:
  if _cell_to_symbol.size() == 0:
    return null
  return _cell_to_symbol.values()[rng.randi_range(0, _cell_to_symbol.size() - 1)]

## Check if a floor grid cell is blocked (out of bounds or occupied by symbol).
func is_cell_blocked(cell: Vector2i) -> bool:
  return not is_in_bounds(cell) or get_symbol_at_cell(cell) != null

func _dim_symbols_except(...exclude_symbols) -> void:
  assert(
    exclude_symbols.size() == 0 || exclude_symbols.any(func(s): return _cell_to_symbol.values().has(s)),
    "_dim_symbols_except requires at least one Symbol argument")

  for symbol in _cell_to_symbol.values():
    if not exclude_symbols.has(symbol):
      symbol.dim()
    elif symbol.is_dimmed:
      symbol.undim()

## Bump the kitten directly. (Used for debug cheat that lets you skip straight to the win.)
func bump_kitten() -> void:
  if _kitten:
    _kitten.bump()

## Dim all NKIs (non-kitten interactables).
func dim_nkis() -> void:
  _dim_symbols_except(_kitten)

## Get cuban pete!
func has_pete() -> bool:
  return _pete != null

## Override a random symbol to become Pete, if Pete isn't already present.
func spawn_pete() -> void:
  if _pete == null:
    _pete = get_random_symbol()
    _pete.blurb = PETE_BLURB

## Dim all symbols except Pete, if Pete exists. Returns true if Pete was found, false if not.
func dim_ncpis() -> bool:
  if has_pete():
    _dim_symbols_except(_pete)
    return true
  return false
