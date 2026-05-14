extends Node3D

class_name Root

@onready var _menu = $Menu
@onready var _world = $World
@onready var _player = $World/Player
@onready var _dialog = $Dialog
@onready var _cheat_console = $CheatConsoleLayer
@onready var _bg_music: BackgroundMusic = $BackgroundMusic


const _WIN_RESTART_PROMPT: String = "Press any key to restart"

var _current_scene: String = "menu" # "menu" or "world"
var _has_won: bool = false


func _ready() -> void:
  _connect_symbol_bump_signals()

  if _world.has_signal("kitten_found") and not _world.kitten_found.is_connected(_on_kitten_found):
    _world.kitten_found.connect(_on_kitten_found)

  _bg_music.playback_changed.connect(_refresh_music_playback_label)

  if not _cheat_console.cheat_activated.is_connected(_on_cheat_activated):
    _cheat_console.cheat_activated.connect(_on_cheat_activated)

  _menu.button_pressed.connect(_on_menu_button_pressed)
  _hide_menu()


func _refresh_music_playback_label(is_playing: bool, track_title: String) -> void:
  if _menu and _menu.has_method("set_music_playing_state"):
    _menu.set_music_playing_state(is_playing, track_title)


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
      _bg_music.previous()
    Menu.MenuAction.MUSIC_TOGGLE_PLAYBACK:
      _bg_music.toggle_playback()
    Menu.MenuAction.MUSIC_SKIP_FORWARD:
      _bg_music.next()
    Menu.MenuAction.RESUME:
      resume()
    Menu.MenuAction.RESTART:
      reset()
    Menu.MenuAction.QUIT:
      quit()


func _connect_symbol_bump_signals() -> void:
  for symbol: Symbol in _world.get_symbols():
    if symbol.has_signal("bumped") and not symbol.is_connected("bumped", Callable(self , "_on_symbol_bumped")):
      symbol.connect("bumped", Callable(self , "_on_symbol_bumped"))


func _on_world_child_entered_tree(node: Node) -> void:
  if node.has_signal("bumped") and not node.is_connected("bumped", Callable(self , "_on_symbol_bumped")):
    node.connect("bumped", Callable(self , "_on_symbol_bumped"))


func _on_symbol_bumped(blurb: String) -> void:
  if _dialog and _dialog.has_method("open"):
    _dialog.open(blurb)
    if blurb.contains("chik-chiky-boom"):
      _cuban_pete()


func _cuban_pete() -> void:
  _menu.toggle_music_controls()
  _bg_music.play_track_by_name("Cuban Pete")
  _menu.toggle_music_controls()


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
