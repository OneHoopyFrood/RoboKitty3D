extends CanvasLayer

class_name CheatConsole

signal cheat_activated(code: String)

@onready var _cheat_panel: PanelContainer = $CheatPanel
@onready var _cheat_label: Label = $CheatPanel/CheatLabel

var _is_cheat_prompt_open: bool = false
var _cheat_input_buffer: String = ""


func _ready() -> void:
  visible = false
  _cheat_panel.visible = false
  _update_cheat_prompt_label()


func is_cheat_prompt_open() -> bool:
  return _is_cheat_prompt_open


func is_cheat_prompt_toggle_input(event: InputEvent) -> bool:
  if not (event is InputEventKey):
    return false

  var key_event := event as InputEventKey
  if not key_event.pressed or key_event.echo:
    return false

  if key_event.ctrl_pressed or key_event.alt_pressed or key_event.meta_pressed:
    return false

  if key_event.keycode == KEY_QUOTELEFT:
    return true

  if key_event.physical_keycode == KEY_QUOTELEFT:
    return true

  return key_event.unicode == 96


func open_cheat_prompt() -> void:
  _is_cheat_prompt_open = true
  _cheat_input_buffer = ""
  visible = true
  _cheat_panel.visible = true
  _update_cheat_prompt_label()


func close_cheat_prompt(should_execute: bool) -> void:
  if should_execute:
    _execute_cheat_code(_cheat_input_buffer)

  _is_cheat_prompt_open = false
  _cheat_input_buffer = ""
  _cheat_panel.visible = false
  visible = false
  _update_cheat_prompt_label()


func handle_cheat_prompt_input(event: InputEvent) -> void:
  if not (event is InputEventKey):
    return

  var key_event := event as InputEventKey
  if not key_event.pressed or key_event.echo:
    return

  if key_event.keycode == KEY_ESCAPE:
    close_cheat_prompt(false)
    return

  if key_event.keycode == KEY_ENTER or key_event.keycode == KEY_KP_ENTER:
    close_cheat_prompt(true)
    return

  if key_event.keycode == KEY_BACKSPACE:
    if not _cheat_input_buffer.is_empty():
      _cheat_input_buffer = _cheat_input_buffer.substr(0, _cheat_input_buffer.length() - 1)
      _update_cheat_prompt_label()
    return

  if key_event.ctrl_pressed or key_event.alt_pressed or key_event.meta_pressed:
    return

  if key_event.unicode >= 32:
    _cheat_input_buffer += char(key_event.unicode)
    _update_cheat_prompt_label()


func _update_cheat_prompt_label() -> void:
  _cheat_label.text = "> %s" % _cheat_input_buffer


func _execute_cheat_code(input_code: String) -> void:
  var normalized_code := input_code.strip_edges().to_lower()
  if normalized_code == "mrrow":
    cheat_activated.emit(normalized_code)
