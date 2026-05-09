extends Control

class_name Menu

enum MenuAction {
  PLAY,
  RESUME,
  QUIT
}

signal button_pressed(action: MenuAction)

@onready var _play_button = $CenterContainer/PanelContainer/VBoxContainer/PlayButton
@onready var _resume_button = $CenterContainer/PanelContainer/VBoxContainer/ResumeButton
@onready var _quit_button = $CenterContainer/PanelContainer/VBoxContainer/QuitButton


func _ready() -> void:
  _play_button.pressed.connect(_on_play_pressed)
  _resume_button.pressed.connect(_on_resume_pressed)
  _quit_button.pressed.connect(_on_quit_pressed)


func _on_play_pressed() -> void:
  button_pressed.emit(MenuAction.PLAY)


func _on_resume_pressed() -> void:
  button_pressed.emit(MenuAction.RESUME)


func _on_quit_pressed() -> void:
  button_pressed.emit(MenuAction.QUIT)
