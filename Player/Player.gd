extends CharacterBody3D

@export var step_duration: float = 0.1
@export var turn_duration: float = 0.2
@export var mouse_sensitivity: float = 0.15
@export var eye_height: float = 1


var cam: Camera3D
var shape: CollisionShape3D
var mouse_delta: Vector2 = Vector2.ZERO
var pitch: float = 0.0

var _tween: Tween # Constantly gets overwritten

func _ready():
  cam = $FPV
  shape = $Hitbox
  Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

  # Position camera at eye level
  cam.position = Vector3(0, eye_height, 0)

func _input(event):
  if event is InputEventMouseMotion:
    mouse_delta = event.relative

func _process(delta):
  if (!_is_mouse_captive()):
    if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
      _toggle_mouse_capture()
    else: return

  if Input.is_action_pressed("ui_cancel"):
    _toggle_mouse_capture()
    return

  # Movement
  if Input.is_action_pressed("move_left"):
    turn_left()
  if Input.is_action_pressed("move_right"):
    turn_right()
  if Input.is_action_pressed("move_forward"):
    go_forward()
  if Input.is_action_pressed("move_back"):
    go_backward()

  # Mouse look
  pitch -= mouse_delta.y * mouse_sensitivity
  pitch = clamp(pitch, -89.0, 89.0)

  cam.rotation_degrees = Vector3(pitch, 0, 0)

  # Reset for next frame
  mouse_delta = Vector2.ZERO

func go_forward():
  var one_step_forward = self.position - transform.basis.z
  _tween_if_not_tweening("position", one_step_forward, step_duration)
  return

func go_backward():
  var one_step_back = self.position + transform.basis.z
  _tween_if_not_tweening("position", one_step_back, step_duration)
  return

func turn_left():
  _face_degree(_cardinalize_deg(rotation_degrees.y + 90))

func turn_right():
  _face_degree(_cardinalize_deg(rotation_degrees.y - 90))

func _cardinalize_deg(turn_deg: int) -> int:
  return round(turn_deg / 90) * 90

func _face_degree(turn_degreees: int):
  # ... but not a real circle, more like a freaky-circle.
  _tween_if_not_tweening("rotation_degrees", Vector3(0,turn_degreees,0), turn_duration)

func _tween_if_not_tweening(property: String, final_val, duration: float):
  if _tween != null and _tween.is_running():
    # "Piss off, ghost!" - Korg
    return
  _tween = create_tween()
  _tween.bind_node(self)
  _tween.tween_property(self, property, final_val, duration)
  return _tween

func _toggle_mouse_capture(release := false):
  if (_is_mouse_captive() or release):
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    print_debug("Mouse released")
  else:
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    print_debug("Mouse captured")

func _is_mouse_captive():
  return Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
