extends CanvasLayer

class_name Dialog

## Public interface
var is_open: bool = false

## UI nodes
var _panel: Control
var _label: Label
var _tween: Tween

func _ready():
  # Get references to child nodes
  _panel = $Panel
  _label = $Panel/MarginContainer/Label

  # Start invisible
  _panel.modulate.a = 0
  _panel.visible = false

  # Don't process input until dialog is open
  set_process_input(false)

func _input(event: InputEvent) -> void:
  # Let Player handle Escape for mouse capture toggling.
  if event.is_action_pressed("ui_cancel"):
    return

  # Any key press dismisses the dialog
  if event is InputEventKey and event.pressed:
    close()
    get_viewport().set_input_as_handled()

## Open the dialog with the given blurb text
func open(blurb: String) -> void:
  if is_open:
    return

  is_open = true
  _label.text = blurb
  _panel.visible = true

  # Fade in
  if _tween:
    _tween.kill()
  _tween = create_tween()
  _tween.tween_property(_panel, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

  # Enable input processing for dismissal
  set_process_input(true)

## Close the dialog
func close() -> void:
  if not is_open:
    return

  # Disable input processing
  set_process_input(false)

  # Fade out
  if _tween:
    _tween.kill()
  _tween = create_tween()
  _tween.tween_property(_panel, "modulate:a", 0.0, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
  _tween.finished.connect(func():
    _panel.visible = false
    is_open = false
  )
