extends Control

class_name Menu

@onready var _play_button = $CenterContainer/PanelContainer/VBoxContainer/PlayButton
@onready var _quit_button = $CenterContainer/PanelContainer/VBoxContainer/QuitButton


func _ready() -> void:
  _play_button.pressed.connect(_on_play_pressed)
  _quit_button.pressed.connect(_on_quit_pressed)


func _on_play_pressed() -> void:
  get_node("/root/Root").play()


func _on_quit_pressed() -> void:
  get_node("/root/Root").quit()
