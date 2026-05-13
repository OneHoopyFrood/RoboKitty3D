extends Node3D

class_name Root

@onready var _menu = $Menu
@onready var _world = $World
@onready var _player = $World/Player
@onready var _dialog = $Dialog
@onready var _cheat_console = $CheatConsoleLayer
@onready var _bg_music: AudioStreamPlayer = $BackgroundMusic
@onready var _alt_bg_music: AudioStreamPlayer = $AltBackgroundMusic
@onready var _bg_music_stream: AudioStreamPlaylist = _bg_music.stream

var _bg_music_track_indexes: Array[float] = [0.0]
var _bg_music_current_track_index: int = 0

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
  skip_music_forward()


func _play_track(idx: int) -> void:
  if _bg_music_track_indexes.is_empty():
    return
  _bg_music_current_track_index = wrapi(idx, 0, _bg_music_track_indexes.size())
  _bg_music.seek(_bg_music_track_indexes[_bg_music_current_track_index])
  _refresh_music_playback_label()
  if not _bg_music.playing:
    _bg_music.play()


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


func _fade_music_toggle(fade_len: float = 1.0, target: AudioStreamPlayer = _bg_music) -> void:
  var fade_in := target.volume_db > -80.0
  var fade_tween := create_tween()
  fade_tween.tween_property(target, "volume_db", -80.0 if fade_in else 0.0, fade_len).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
  await fade_tween.finished


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
    _toggle_menu()
    return true

  return false


func _restart_after_win() -> void:
  _has_won = false
  reset()


func _toggle_menu() -> void:
  if _current_scene == "menu":
    _hide_menu()
  else:
    _show_menu()

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
  _menu.reset()
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
  var cuban_pete_stream := load("res://Assets/music/Cuban Pete.ogg") as AudioStream
  if cuban_pete_stream and _bg_music.stream == _bg_music_stream:
    _menu.toggle_music_controls()

    # Transition to Cuban Pete
    _alt_bg_music.play()
    _fade_music_toggle(2, _alt_bg_music)

    await _fade_music_toggle(2, _bg_music)
    _bg_music.stop()

    await _alt_bg_music.finished
    _alt_bg_music.volume_db = 0.0

    # Restore original background music
    _bg_music.play()
    _fade_music_toggle(2, _bg_music)

    _menu.toggle_music_controls()
  else:
    print_debug("Failed to load Cuban Pete track")


func _on_kitten_found() -> void:
  if _has_won:
    return
  _has_won = true
  _player.disable_controls()
  _dialog.open("", _WIN_RESTART_PROMPT)


func _on_cheat_activated(code: String) -> void:
  if code == "rfk":
    resume()
    _world.bump_kitten()
    print_debug("Cheat activated: You win!")
  elif code == "herekittykitty":
    _world.dim_nkis()
    print_debug("Cheat activated: Dimmed all NKIs")
  elif code == "pete":
    # Make sure Pete is spawned.
    if not _world.has_pete():
      _world.spawn_pete()
    _world.dim_ncpis()
    print_debug("Cheat activated: Cuban Pete will appear in the world")
  elif code == "p":
    _cuban_pete()
