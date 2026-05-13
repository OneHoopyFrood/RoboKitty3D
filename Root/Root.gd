extends Node3D

class_name Root

@onready var _menu = $Menu
@onready var _world = $World
@onready var _player = $World/Player
@onready var _dialog = $Dialog
@onready var _cheat_console = $CheatConsoleLayer
@onready var _bg_music: AudioStreamPlayer = $BackgroundMusic
@onready var _bg_music_stream: AudioStreamPlaylist = _bg_music.stream

const _CUBAN_PETE_STREAM: AudioStream = preload("res://Assets/music/Cuban Pete.ogg")
const _MUSIC_FADE_DURATION: float = 1.0
const _MUSIC_MUTED_DB: float = -80.0
const _MUSIC_NORMAL_DB: float = 0.0

var _bg_music_track_indexes: Array[float] = [0.0]
var _bg_music_current_track_index: int = 0
var _bg_music_transition_tween: Tween = null
var _bg_music_restore_tween: Tween = null
var _is_cuban_pete_active: bool = false

const _WIN_RESTART_PROMPT: String = "Press any key to restart"

var _current_scene: String = "menu" # "menu" or "world"
var _has_won: bool = false


func _ready() -> void:
  if not _bg_music.finished.is_connected(_on_music_finished):
    _bg_music.finished.connect(_on_music_finished)

  # Pre-calculate the starting position of each track in the playlist so we can seek to them directly when skipping.
  var num_tracks := _bg_music_stream.stream_count
  _bg_music_track_indexes = []
  var track_start := 0.0
  for i in range(num_tracks):
    _bg_music_track_indexes.append(track_start)
    var stream: AudioStream = _bg_music_stream.get_list_stream(i)
    if stream:
      track_start += stream.get_length()
  print_debug("Background music track indexes: ", _bg_music_track_indexes)

  # Pick a random start track
  if num_tracks > 0:
    _play_track(randi_range(0, num_tracks - 1))

  _connect_symbol_bump_signals_recursive(_world)

  if _world.has_signal("kitten_found") and not _world.kitten_found.is_connected(_on_kitten_found):
    _world.kitten_found.connect(_on_kitten_found)

  if not _cheat_console.cheat_activated.is_connected(_on_cheat_activated):
    _cheat_console.cheat_activated.connect(_on_cheat_activated)

  _menu.button_pressed.connect(_on_menu_button_pressed)

  _hide_menu()


func _on_music_finished() -> void:
  if _is_cuban_pete_active:
    return
  skip_music_forward()


func _play_track(idx: int) -> void:
  if _bg_music_track_indexes.is_empty():
    return
  _bg_music_current_track_index = wrapi(idx, 0, _bg_music_track_indexes.size())
  if _bg_music.stream != _bg_music_stream:
    return
  _bg_music.seek(_bg_music_track_indexes[_bg_music_current_track_index])
  _refresh_music_playback_label()


func _music_find_current_track_index() -> int:
  if _bg_music_track_indexes.is_empty():
    return 0
  return wrapi(_bg_music_current_track_index, 0, _bg_music_track_indexes.size())


func skip_music_back() -> void:
  if _bg_music_track_indexes.is_empty():
    return
  var current_index := _music_find_current_track_index()
  var last_index := wrapi(current_index - 1, 0, _bg_music_track_indexes.size())
  _play_track(last_index)


func skip_music_forward() -> void:
  if _bg_music_track_indexes.is_empty():
    return
  var current_index := _music_find_current_track_index()
  var next_index := wrapi(current_index + 1, 0, _bg_music_track_indexes.size())
  _play_track(next_index)


func toggle_music_playback() -> void:
  if _bg_music.playing and not _bg_music.stream_paused:
    _bg_music.stream_paused = true
    _refresh_music_playback_label()
    return

  if _bg_music.stream_paused:
    _bg_music.stream_paused = false
    _refresh_music_playback_label()
    return


func _refresh_music_playback_label() -> void:
  var is_playing := _bg_music.playing and not _bg_music.stream_paused
  if _menu and _menu.has_method("set_music_playing_state"):
    _menu.set_music_playing_state(is_playing)


func _input(event: InputEvent) -> void:
  if _handle_root_input(event):
    _player.disable_controls()
    var viewport = get_viewport()
    if viewport != null:
      viewport.set_input_as_handled()
  else:
    _player.enable_controls()


func _unhandled_input(event: InputEvent) -> void:
  _input(event)


func _handle_root_input(event: InputEvent) -> bool:
  if _cheat_console.is_cheat_prompt_open():
    _cheat_console.handle_cheat_prompt_input(event)
    return true

  if _cheat_console.is_cheat_prompt_toggle_input(event):
    _cheat_console.open_cheat_prompt()
    return true

  if _has_won and event is InputEventKey and event.pressed and not event.echo:
    _restart_after_win()
    return true

  if event.is_action_pressed("ui_cancel"):
    _show_menu()
    return true

  return false


func _restart_after_win() -> void:
  _has_won = false
  reset()


func _show_menu() -> void:
  _current_scene = "menu"
  _cheat_console.close_cheat_prompt(false)

  # Disable player controls and hide world, but keep them active so they can be seen in the background.
  _player.disable_controls()

  # Close dialog if open
  if _dialog.is_open:
    _dialog.close()

  # Show world in the background, but disable processing so it doesn't update or respond to interactions.
  _world.visible = true
  _world.process_mode = Node.PROCESS_MODE_INHERIT

  # Show menu on top of world
  _menu.visible = true

  Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _hide_menu() -> void:
  _current_scene = "world"
  _cheat_console.close_cheat_prompt(false)
  _menu.visible = false
  _player.enable_controls()
  _world.visible = true
  _world.process_mode = Node.PROCESS_MODE_INHERIT
  Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func resume() -> void:
  _hide_menu()


func reset() -> void:
  get_tree().reload_current_scene()


func quit() -> void:
  get_tree().quit()


func _on_menu_button_pressed(action: Menu.MenuAction) -> void:
  match action:
    Menu.MenuAction.MUSIC_SKIP_BACK:
      skip_music_back()
    Menu.MenuAction.MUSIC_TOGGLE_PLAYBACK:
      toggle_music_playback()
    Menu.MenuAction.MUSIC_SKIP_FORWARD:
      skip_music_forward()
    Menu.MenuAction.RESUME:
      resume()
    Menu.MenuAction.RESTART:
      reset()
    Menu.MenuAction.QUIT:
      quit()


func _connect_symbol_bump_signals_recursive(node: Node) -> void:
  for child in node.get_children():
    if child.has_signal("bumped") and not child.is_connected("bumped", Callable(self , "_on_symbol_bumped")):
      child.connect("bumped", Callable(self , "_on_symbol_bumped"))
    _connect_symbol_bump_signals_recursive(child)


func _on_world_child_entered_tree(node: Node) -> void:
  if node.has_signal("bumped") and not node.is_connected("bumped", Callable(self , "_on_symbol_bumped")):
    node.connect("bumped", Callable(self , "_on_symbol_bumped"))


func _on_symbol_bumped(blurb: String) -> void:
  if _dialog and _dialog.has_method("open"):
    _dialog.open(blurb)
    if blurb.contains("chik-chiky-boom"):
      _cuban_pete()


func _cuban_pete() -> void:
  if not _CUBAN_PETE_STREAM:
    print_debug("Failed to load Cuban Pete track")
    return

  if _is_cuban_pete_active or _bg_music.stream != _bg_music_stream:
    return

  _kill_music_tween(_bg_music_transition_tween)
  _kill_music_tween(_bg_music_restore_tween)

  _is_cuban_pete_active = true
  _bg_music_transition_tween = create_tween().bind_node(self)
  _bg_music_transition_tween.tween_property(_bg_music, "volume_db", _MUSIC_MUTED_DB, _MUSIC_FADE_DURATION)
  _bg_music_transition_tween.tween_callback(_start_cuban_pete_playback)
  _bg_music_transition_tween.tween_property(_bg_music, "volume_db", _MUSIC_NORMAL_DB, _MUSIC_FADE_DURATION)
  _bg_music_transition_tween.finished.connect(_on_bg_music_transition_finished, CONNECT_ONE_SHOT)


func _start_cuban_pete_playback() -> void:
  _bg_music.stop()
  _bg_music.stream = _CUBAN_PETE_STREAM
  _bg_music.play()
  _bg_music.finished.connect(_on_cuban_pete_finished, CONNECT_ONE_SHOT)


func _on_cuban_pete_finished() -> void:
  if not _is_cuban_pete_active:
    return

  _kill_music_tween(_bg_music_transition_tween)
  _kill_music_tween(_bg_music_restore_tween)

  _bg_music_restore_tween = create_tween().bind_node(self)
  _bg_music_restore_tween.tween_property(_bg_music, "volume_db", _MUSIC_MUTED_DB, _MUSIC_FADE_DURATION)
  _bg_music_restore_tween.tween_callback(_restore_background_music)
  _bg_music_restore_tween.tween_property(_bg_music, "volume_db", _MUSIC_NORMAL_DB, _MUSIC_FADE_DURATION)
  _bg_music_restore_tween.finished.connect(_on_bg_music_restore_finished, CONNECT_ONE_SHOT)


func _restore_background_music() -> void:
  _bg_music.stop()
  _bg_music.stream = _bg_music_stream
  _bg_music.play()
  _play_track(_bg_music_current_track_index)


func _on_bg_music_transition_finished() -> void:
  _bg_music_transition_tween = null


func _on_bg_music_restore_finished() -> void:
  _bg_music_restore_tween = null
  _is_cuban_pete_active = false


func _kill_music_tween(tween: Tween) -> void:
  if tween:
    tween.kill()


func _on_kitten_found() -> void:
  if _has_won:
    return
  _has_won = true
  _player.disable_controls()
  if _dialog and _dialog.has_method("open"):
    _dialog.open("", _WIN_RESTART_PROMPT)


func _on_cheat_activated(code: String) -> void:
  if code == "rfk":
    resume()
    _world.bump_kitten()
    print_debug("Cheat activated: You win!")
  elif code == "herekittykitty":
    # Set dim visited option to true if it's not already, so that the effect of
    # the cheat is visible.
    var options := get_node_or_null("/root/GameOptions")
    if options and not bool(options.visited_dimming):
      options.visited_dimming = true
    _world.bump_all_nkis()
    print_debug("Cheat activated: Bumped all NKIs")
  elif code == "cubanpete":
    # If symbol in front of player, assign it the chik-chiky-boom blurb
    # For now, play music
    _cuban_pete()
    print_debug("Cheat activated: Cuban Pete")
