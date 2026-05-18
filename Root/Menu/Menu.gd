extends Control

class_name Menu

enum MenuAction {
  MUSIC_SKIP_BACK,
  MUSIC_TOGGLE_PLAYBACK,
  MUSIC_SKIP_FORWARD,
  RESUME,
  RESTART,
  QUIT
}

signal button_pressed(action: MenuAction)

@onready var _resume_button = $CenterContainer/PanelContainer/VBoxContainer/ResumeButton
@onready var _restart_button = $CenterContainer/PanelContainer/VBoxContainer/RestartButton
@onready var _options_button = $CenterContainer/PanelContainer/VBoxContainer/OptionsButton
@onready var _quit_button = $CenterContainer/PanelContainer/VBoxContainer/QuitButton
@onready var _music_skip_back_button = $CenterContainer/PanelContainer/VBoxContainer/MusicPanel/MusicVBox/MusicControls/MusicSkipBackButton
@onready var _music_toggle_playback_button = $CenterContainer/PanelContainer/VBoxContainer/MusicPanel/MusicVBox/MusicControls/MusicTogglePlaybackButton
@onready var _music_skip_forward_button = $CenterContainer/PanelContainer/VBoxContainer/MusicPanel/MusicVBox/MusicControls/MusicSkipForwardButton
@onready var _music_track_label = $CenterContainer/PanelContainer/VBoxContainer/MusicPanel/MusicVBox/MusicTrackLabel

@onready var _main_panel = $CenterContainer/PanelContainer
@onready var _options_panel = $CenterContainer/OptionsPanel
@onready var _visited_dimming_check = $CenterContainer/OptionsPanel/VBoxContainer/VisitedDimmingRow/VisitedDimmingCheck
@onready var _board_size_spinbox = $CenterContainer/OptionsPanel/VBoxContainer/BoardSizeOption/BoardSizeControls/BoardSizeSpinBox
@onready var _nki_count_spinbox = $CenterContainer/OptionsPanel/VBoxContainer/NKICountOption/NKICountControls/NKICountSpinBox
@onready var _back_button = $CenterContainer/OptionsPanel/VBoxContainer/BackButton
@onready var _save_button = $CenterContainer/OptionsPanel/VBoxContainer/SaveButton


func _ready() -> void:
  _music_skip_back_button.pressed.connect(_on_music_skip_back_pressed)
  _music_toggle_playback_button.pressed.connect(_on_music_toggle_playback_pressed)
  _music_skip_forward_button.pressed.connect(_on_music_skip_forward_pressed)
  _resume_button.pressed.connect(_on_resume_pressed)
  _restart_button.pressed.connect(_on_restart_pressed)
  _options_button.pressed.connect(_on_options_pressed)
  _quit_button.pressed.connect(_on_quit_pressed)
  _back_button.pressed.connect(_on_back_pressed)
  _save_button.pressed.connect(_on_save_pressed)
  _visited_dimming_check.toggled.connect(_on_options_control_changed)
  _board_size_spinbox.value_changed.connect(_on_options_control_changed)
  _nki_count_spinbox.value_changed.connect(_on_options_control_changed)


func set_music_playing_state(is_playing: bool, track_title: String = "") -> void:
  _music_toggle_playback_button.text = "⏸︎" if is_playing else "▶︎"
  _music_track_label.text = track_title


func reset() -> void:
  _main_panel.visible = true
  _options_panel.visible = false
  _save_button.disabled = true


func disable_music_controls() -> void:
  _music_skip_back_button.disabled = true
  _music_toggle_playback_button.disabled = true
  _music_skip_forward_button.disabled = true


func enable_music_controls() -> void:
  _music_skip_back_button.disabled = false
  _music_toggle_playback_button.disabled = false
  _music_skip_forward_button.disabled = false


func _get_options_node() -> Node:
  return get_node_or_null("/root/GameOptions")


func _on_options_pressed() -> void:
  var options := _get_options_node()
  if options:
    _visited_dimming_check.set_pressed_no_signal(options.visited_dimming)
    _board_size_spinbox.set_value_no_signal(options.board_size)
    _nki_count_spinbox.set_value_no_signal(options.nki_count)
  _save_button.disabled = true
  _main_panel.visible = false
  _options_panel.visible = true


func _on_back_pressed() -> void:
  _options_panel.visible = false
  _main_panel.visible = true


func _on_save_pressed() -> void:
  var options := _get_options_node()
  if options:
    options.visited_dimming = _visited_dimming_check.button_pressed
    options.board_size = int(_board_size_spinbox.value)
    options.nki_count = int(_nki_count_spinbox.value)
  _save_button.disabled = true


func _on_options_control_changed(_value = null) -> void:
  var options := _get_options_node()
  if options == null:
    _save_button.disabled = true
    return

  var dirty: bool = _visited_dimming_check.button_pressed != options.visited_dimming \
    or int(_board_size_spinbox.value) != options.board_size \
    or int(_nki_count_spinbox.value) != options.nki_count
  _save_button.disabled = not dirty


func _on_music_skip_back_pressed() -> void:
  button_pressed.emit(MenuAction.MUSIC_SKIP_BACK)


func _on_music_toggle_playback_pressed() -> void:
  button_pressed.emit(MenuAction.MUSIC_TOGGLE_PLAYBACK)


func _on_music_skip_forward_pressed() -> void:
  button_pressed.emit(MenuAction.MUSIC_SKIP_FORWARD)


func _on_resume_pressed() -> void:
  button_pressed.emit(MenuAction.RESUME)


func _on_restart_pressed() -> void:
  button_pressed.emit(MenuAction.RESTART)


func _on_quit_pressed() -> void:
  button_pressed.emit(MenuAction.QUIT)
