extends Control

class_name Menu

enum MenuAction {
  RESUME,
  RESTART,
  QUIT
}

signal button_pressed(action: MenuAction)

@onready var _resume_button = $CenterContainer/PanelContainer/VBoxContainer/ResumeButton
@onready var _restart_button = $CenterContainer/PanelContainer/VBoxContainer/RestartButton
@onready var _quit_button = $CenterContainer/PanelContainer/VBoxContainer/QuitButton


func _ready() -> void:
  _resume_button.pressed.connect(_on_resume_pressed)
  _restart_button.pressed.connect(_on_restart_pressed)
  _quit_button.pressed.connect(_on_quit_pressed)


func _on_resume_pressed() -> void:
  button_pressed.emit(MenuAction.RESUME)


func _on_restart_pressed() -> void:
  button_pressed.emit(MenuAction.RESTART)


func _on_quit_pressed() -> void:
  button_pressed.emit(MenuAction.QUIT)
