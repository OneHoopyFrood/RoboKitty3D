extends Node3D

class_name Root

@onready var _menu = $Menu
@onready var _world = $World
@onready var _player = $World/Player
@onready var _dialog = $Dialog
@onready var _cheat_console = $CheatConsoleLayer
@onready var _music: AudioStreamPlayer = $BackgroundMusic

const _MUSIC_TRACKS: Array[AudioStream] = [
  preload("res://Assets/music/Nostalgium 2023.ogg"),
  preload("res://Assets/music/I Found A Pretty Stone (soft cutoff).ogg"),
  preload("res://Assets/music/jonbeck bonbo.ogg")
]
const _MUSIC_TRACK_INDEX_SETTING: String = "game/current_music_track_index"
const _WIN_RESTART_PROMPT: String = "Press any key to restart"

var _current_scene: String = "menu" # "menu" or "world"
var _has_won: bool = false
var _track_index: int = 0


func _ready() -> void:
  if not _music.finished.is_connected(_on_music_finished):
    _music.finished.connect(_on_music_finished)
  if ProjectSettings.has_setting(_MUSIC_TRACK_INDEX_SETTING):
    _track_index = int(ProjectSettings.get_setting(_MUSIC_TRACK_INDEX_SETTING))
  _play_track(_track_index)
  _refresh_music_playback_label()

  _connect_symbol_bump_signals_recursive(_world)

  if _world.has_signal("kitten_found") and not _world.kitten_found.is_connected(_on_kitten_found):
    _world.kitten_found.connect(_on_kitten_found)

  if not _cheat_console.cheat_activated.is_connected(_on_cheat_activated):
    _cheat_console.cheat_activated.connect(_on_cheat_activated)

  _menu.button_pressed.connect(_on_menu_button_pressed)

  _hide_menu()


func _on_music_finished() -> void:
  skip_music_forward()


func _play_track(index: int) -> void:
  if _MUSIC_TRACKS.is_empty():
    return

  _track_index = wrapi(index, 0, _MUSIC_TRACKS.size())
  ProjectSettings.set_setting(_MUSIC_TRACK_INDEX_SETTING, _track_index)
  _music.stream = _MUSIC_TRACKS[_track_index]
  _music.stream_paused = false
  _music.play()
  _refresh_music_playback_label()


func skip_music_back() -> void:
  _play_track(_track_index - 1)


func skip_music_forward() -> void:
  _play_track(_track_index + 1)


func toggle_music_playback() -> void:
  if _music.playing and not _music.stream_paused:
    _music.stream_paused = true
    _refresh_music_playback_label()
    return

  if _music.stream_paused:
    _music.stream_paused = false
    _refresh_music_playback_label()
    return

  _play_track(_track_index)


func _refresh_music_playback_label() -> void:
  var is_playing := _music.playing and not _music.stream_paused
  if _menu and _menu.has_method("set_music_playing_state"):
    _menu.set_music_playing_state(is_playing)


func _input(event: InputEvent) -> void:
  if _handle_root_input(event):
    get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
  if _handle_root_input(event):
    get_viewport().set_input_as_handled()


func _handle_root_input(event: InputEvent) -> bool:
  if _cheat_console.is_cheat_prompt_open():
    _cheat_console.handle_cheat_prompt_input(event)
    return true

  if _current_scene == "menu" and _cheat_console.is_cheat_prompt_toggle_input(event):
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
  shuffle_bg_music()
  get_tree().reload_current_scene()


func shuffle_bg_music() -> void:
  if not _MUSIC_TRACKS.is_empty():
    ProjectSettings.set_setting(_MUSIC_TRACK_INDEX_SETTING, wrapi(_track_index + 1, 0, _MUSIC_TRACKS.size()))


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
