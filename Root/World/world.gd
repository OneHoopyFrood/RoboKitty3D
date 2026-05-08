extends Node3D

@export var num_nodes: int = 100
var board_size: int = 50

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var node_scene = preload('res://Root/World/Symbol/Symbol.tscn')

var _music_player: AudioStreamPlayer = null
var _blurbs: Array[String] = []

func _ready():
  rng.randomize()

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

  # Music looping
  _music_player = get_node_or_null("BackgroundMusic") as AudioStreamPlayer
  if _music_player:
    _music_player.finished.connect(_on_music_finished)

func _on_music_finished():
  if _music_player:
    _music_player.play()

func _generate_nodes() -> Array[Symbol]:
  var nodes: Array[Symbol] = []
  var used_positions: Array[Vector3i] = [Vector3i(0, 1, 0)] # Start with the player's position as used to avoid spawning on top of them
  for i in range(num_nodes):
    var node: Symbol = node_scene.instantiate()
    node.randomize_bobbing(rng)
    node.randomize_color(rng)

    # Assign blurb to Symbol nodes
    node.blurb = _blurbs[i]

    var pos: Vector3i = random_pos()
    while used_positions.has(pos): # If an overlap happens, choose another spot until you get a unique value
      pos = random_pos()
    used_positions.push_back(pos)
    node.position = pos

    nodes.append(node)
  return nodes

func random_pos() -> Vector3i:
  var spawn_radius = int(board_size / 2) - 1
  return Vector3i(
      rng.randi_range(-spawn_radius, spawn_radius),
      1,
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
