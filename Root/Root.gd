extends Node3D

class_name Root

@onready var _menu = $Menu
@onready var _world = $World
@onready var _player = $World/Player
@onready var _dialog = $Dialog
@onready var _music: AudioStreamPlayer = $BackgroundMusic

var _current_scene: String = "menu" # "menu" or "world"


func _ready() -> void:
	_show_menu()
	_music.finished.connect(_on_music_finished)
	_connect_symbol_bump_signals_recursive(_world)
	_menu.button_pressed.connect(_on_menu_button_pressed)


func _on_music_finished() -> void:
	_music.play()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_show_menu()


func _show_menu() -> void:
	_current_scene = "menu"
	
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
	_menu.visible = false
	_player.enable_controls()
	_world.visible = true
	_world.process_mode = Node.PROCESS_MODE_INHERIT
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func play() -> void:
	_hide_menu()


func quit() -> void:
	get_tree().quit()


func _on_menu_button_pressed(action: Menu.MenuAction) -> void:
	match action:
		Menu.MenuAction.PLAY, Menu.MenuAction.RESUME:
			play()
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
