extends Node3D

class_name Root

@onready var _menu = $Menu
@onready var _world = $World
@onready var _dialog = $Dialog

var _current_scene: String = "menu" # "menu" or "world"


func _ready() -> void:
	_show_menu()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_show_menu()


func _show_menu() -> void:
	_current_scene = "menu"
	if _world:
		_world.visible = false
		_world.process_mode = Node.PROCESS_MODE_DISABLED
	if _menu:
		_menu.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _show_world() -> void:
	_current_scene = "world"
	if _menu:
		_menu.visible = false
	if _world:
		_world.visible = true
		_world.process_mode = Node.PROCESS_MODE_INHERIT
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func play() -> void:
	_show_world()


func quit() -> void:
	get_tree().quit()
