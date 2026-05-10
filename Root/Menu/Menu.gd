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
@onready var _quit_button = $CenterContainer/PanelContainer/VBoxContainer/QuitButton
@onready var _music_skip_back_button = $CenterContainer/PanelContainer/VBoxContainer/MusicPanel/MusicVBox/MusicControls/MusicSkipBackButton
@onready var _music_toggle_playback_button = $CenterContainer/PanelContainer/VBoxContainer/MusicPanel/MusicVBox/MusicControls/MusicTogglePlaybackButton
@onready var _music_skip_forward_button = $CenterContainer/PanelContainer/VBoxContainer/MusicPanel/MusicVBox/MusicControls/MusicSkipForwardButton


func _ready() -> void:
  _music_skip_back_button.pressed.connect(_on_music_skip_back_pressed)
  _music_toggle_playback_button.pressed.connect(_on_music_toggle_playback_pressed)
  _music_skip_forward_button.pressed.connect(_on_music_skip_forward_pressed)
  _resume_button.pressed.connect(_on_resume_pressed)
  _restart_button.pressed.connect(_on_restart_pressed)
  _quit_button.pressed.connect(_on_quit_pressed)


func set_music_playing_state(is_playing: bool) -> void:
  _music_toggle_playback_button.text = "⏸︎" if is_playing else "▶︎"


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
