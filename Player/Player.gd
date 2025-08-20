extends CharacterBody3D

@export var step_size: float = 1.0         # how big is one grid cell? (basically 1.0)
@export var step_duration: float = 0.1     # how long to spend moving one cell
@export var turn_duration: float = 0.25
@export var mouse_sensitivity: float = 0.15
@export var eye_height: float = 1

var cam: Camera3D
var shape: CollisionShape3D
var mouse_delta: Vector2 = Vector2.ZERO
var yaw: float = 0.0
var pitch: float = 0.0

# Movement
var is_moving: bool = false
var move_dir: Vector3 = Vector3.ZERO
var target_position: Vector3 = Vector3.ZERO

var _tween: Tween

func _ready():
  cam = $FPV
  shape = $HitBox
  Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

  # Position camera at eye level
  cam.position = Vector3(0, eye_height, 0)

func _input(event):
  if event is InputEventMouseMotion:
    mouse_delta = event.relative

func _process(delta):
  # Mouse-lock toggling
  if (!_is_mouse_captive()):
    if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
      _toggle_mouse_capture()
    else:
      return

  if Input.is_action_pressed("ui_cancel"):
    _toggle_mouse_capture()
    return

  if not is_moving:
    if Input.is_action_just_pressed("move_left"):
      turn_left()
    elif Input.is_action_just_pressed("move_right"):
      turn_right()
    elif Input.is_action_pressed("move_forward"):
      start_move(-transform.basis.z)
    elif Input.is_action_pressed("move_back"):
      start_move(transform.basis.z)

  # Mouse look
  if Input.is_action_pressed("look"):
    yaw -= mouse_delta.x * mouse_sensitivity
    yaw = clamp(yaw, -89.0, 89.0)
    pitch -= mouse_delta.y * mouse_sensitivity
    pitch = clamp(pitch, -89.0, 89.0)

    cam.rotation_degrees = Vector3(pitch, yaw, 0)
    mouse_delta = Vector2.ZERO

  if Input.is_action_just_released("look"):
    recenter_look()


func _physics_process(delta):
  if is_moving:
    # Compute the speed so we travel exactly step_size units in step_duration seconds
    var speed = step_size / step_duration
    velocity = move_dir.normalized() * speed

    var pre_move_pos = position
    move_and_slide()

    if move_dir.dot(target_position - global_transform.origin) <= 0:
      is_moving = false
    elif velocity == Vector3.ZERO:
      #print("Hit something")
      position = pre_move_pos
      is_moving = false
    # else still moving
  else:
    # If we’re not moving, ensure velocity is zero
    velocity = Vector3.ZERO

    # You still HAVE to call move_and_slide() every frame so that physics state stays consistent
    move_and_slide()

func start_move(direction: Vector3) -> void:
  direction.y = 0
  direction = direction.normalized()

  # Set up our “moving” state
  move_dir = direction
  is_moving = true

  # Calculate exactly one cell ahead
  target_position = global_transform.origin + move_dir * step_size

func turn_left():
  if is_moving:
    return
  var new_yaw = _cardinalize_deg(rotation_degrees.y + 90)
  _face_degree(new_yaw)

func turn_right():
  if is_moving: return
  var new_yaw = _cardinalize_deg(rotation_degrees.y - 90)
  _face_degree(new_yaw)

func recenter_look():
  yaw = 0
  pitch = 0
  _tween = create_tween().bind_node(cam)
  _tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
  _tween.tween_property(cam, "rotation_degrees", Vector3.ZERO, 0.2)

func _cardinalize_deg(turn_deg: int) -> int:
  return round(turn_deg / 90) * 90

func _face_degree(turn_degrees: int):
  # Tween your rotation_degrees around the Y axis; collisions don’t care about rotation anyway
  _tween = create_tween().bind_node(self)
  _tween.set_trans(Tween.TRANS_ELASTIC)
  _tween.tween_property(self, "rotation_degrees", Vector3(0, turn_degrees, 0), turn_duration)

func _toggle_mouse_capture(release := false):
  if _is_mouse_captive() or release:
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    print_debug("Mouse released")
  else:
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    print_debug("Mouse captured")

func _is_mouse_captive() -> bool:
  return Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
