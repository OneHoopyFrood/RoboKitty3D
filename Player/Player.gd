extends CharacterBody3D

@export var speed: float = 10.0
@export var mouse_sensitivity: float = 0.15
@export var eye_height: float = 1.6

var cam: Camera3D
var shape: CollisionShape3D
var mouse_delta: Vector2 = Vector2.ZERO
var yaw: float = 0.0
var pitch: float = 0.0

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
  if (is_mouse_captive()):
    if Input.is_action_pressed("ui_cancel"):
      toggle_mouse_capture()
      return

    # Movement
    var dir = Vector3.ZERO
    if Input.is_action_pressed("move_forward"):
      dir -= cam.global_transform.basis.z
    if Input.is_action_pressed("move_back"):
      dir += cam.global_transform.basis.z
    if Input.is_action_pressed("move_left"):
      dir -= cam.global_transform.basis.x
    if Input.is_action_pressed("move_right"):
      dir += cam.global_transform.basis.x
    dir.y = 0

    velocity = dir.normalized() * speed if dir.length() > 0 else Vector3.ZERO
    move_and_slide()

    # Mouse look
    yaw   -= mouse_delta.x * mouse_sensitivity
    pitch -= mouse_delta.y * mouse_sensitivity
    pitch = clamp(pitch, -89.0, 89.0)

    rotation_degrees = Vector3(0, yaw, 0)
    cam.rotation_degrees = Vector3(pitch, 0, 0)

    # Reset for next frame
    mouse_delta = Vector2.ZERO

  elif Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
    toggle_mouse_capture()

func toggle_mouse_capture(release := false):
  if (is_mouse_captive() or release):
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    print_debug("Mouse released")
  else:
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    print_debug("Mouse captured")

func is_mouse_captive():
  return Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
