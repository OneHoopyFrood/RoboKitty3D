extends Node3D

class_name Root

@onready var _menu = $Menu
@onready var _world = $World


func _ready() -> void:
	_show_menu()


func _show_menu() -> void:
	if _world:
		_world.visible = false
	if _menu:
		_menu.visible = true


func _show_world() -> void:
	if _menu:
		_menu.visible = false
	if _world:
		_world.visible = true


func play() -> void:
	_show_world()


func quit() -> void:
	get_tree().quit()
