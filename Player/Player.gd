extends CharacterBody3D

@export var step_size: float = 1.0 # how big is one grid cell? (basically 1.0)
@export var step_duration: float = 0.1 # how long to spend moving one cell
@export var turn_duration: float = 0.25
@export var mouse_sensitivity: float = 0.15
@export var eye_height: float = 1

@export var dialog_ui_path: NodePath
@export var select_sfx_stream: AudioStream

var cam: Camera3D
var shape: CollisionShape3D
var mouse_delta: Vector2 = Vector2.ZERO
var yaw: float = 0.0
var pitch: float = 0.0

# Movement
var is_moving: bool = false
var move_dir: Vector3 = Vector3.ZERO
var target_position: Vector3 = Vector3.ZERO
var start_position: Vector3 = Vector3.ZERO # Grid-aligned position at movement start

var _tween: Tween
var _dialog_ui: Node = null
var _sfx: AudioStreamPlayer = null

const symbol_group = "symbol"

func _ready():
  cam = $FPV
  shape = $HitBox
  Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

  # Snap to grid on startup
  _snap_to_grid()

  # Position camera at eye level
  cam.position = Vector3(0, eye_height, 0)

  # Wire dialog UI if provided
  if dialog_ui_path != NodePath(""):
    _dialog_ui = get_node_or_null(dialog_ui_path)

  # Simple SFX player
  _sfx = AudioStreamPlayer.new()
  add_child(_sfx)
  if select_sfx_stream:
    _sfx.stream = select_sfx_stream

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
    else:
      # Try interaction on a *fresh* forward press
      # NOTE: Interactions only trigger on intentional bumps (standing -> just_pressed).
      # Walking into symbols (action_pressed while moving) should collide naturally
      # without triggering interaction.
      if Input.is_action_just_pressed("move_forward"):
        var symbol = _try_bump_interact()
        if symbol:
          # interacted; do not move
          _on_bumped_symbol(symbol)
        else:
          start_move(-transform.basis.z)
      # Holding W for zoom should still step repeatedly when not interacting
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

    move_and_slide()

    if move_dir.dot(target_position - global_transform.origin) <= 0:
      is_moving = false
      _snap_to_grid() # Snap to grid after completing move
    elif velocity == Vector3.ZERO:
      #print("Hit something")
      position = start_position # Return to grid-aligned start position
      is_moving = false
      # No need to snap - start_position is already grid-aligned
    # else still moving
  else:
    # If we’re not moving, ensure velocity is zero
    velocity = Vector3.ZERO

    # Save position before move_and_slide to detect collision push
    var before_pos = position

    # You still HAVE to call move_and_slide() every frame so that physics state stays consistent
    move_and_slide()

    # If we got pushed by a collision, snap back to grid
    if position != before_pos:
      _snap_to_grid()

func start_move(direction: Vector3) -> void:
  direction.y = 0
  direction = direction.normalized()

  # Set up our “moving” state
  move_dir = direction
  is_moving = true
  # Store current grid-aligned position for collision bounce-back
  start_position = global_transform.origin
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

func _cardinalize_deg(turn_deg: float) -> float:
  # First normalize to cardinal direction
  var cardinalized = round(turn_deg / 90) * 90
  # Then wrap to -180 to 180 range
  while cardinalized > 180:
    cardinalized -= 360
  while cardinalized <= -180:
    cardinalized += 360
  return cardinalized

func _face_degree(turn_degrees: float):
  _tween = create_tween().bind_node(self )
  _tween.set_trans(Tween.TRANS_ELASTIC)
  _tween.tween_property(self , "rotation_degrees", Vector3(0, turn_degrees, 0), turn_duration)

func _toggle_mouse_capture(release := false):
  if _is_mouse_captive() or release:
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    print_debug("Mouse released")
  else:
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    print_debug("Mouse captured")

func _is_mouse_captive() -> bool:
  return Input.mouse_mode == Input.MOUSE_MODE_CAPTURED

func _snap_to_grid() -> void:
  # Snap position to nearest grid cell center
  var snapped_pos = global_transform.origin
  snapped_pos.x = round(snapped_pos.x / step_size) * step_size
  snapped_pos.z = round(snapped_pos.z / step_size) * step_size
  global_transform.origin = snapped_pos

func _try_bump_interact() -> Node:
  # Cast one cell ahead on a horizontal line from player center
  var from := global_transform.origin + Vector3(0, eye_height * 0.5, 0)
  var fwd := -transform.basis.z
  fwd.y = 0
  fwd = fwd.normalized()
  var to := from + fwd * (step_size * 0.95)

  var space := get_world_3d().direct_space_state
  var query := PhysicsRayQueryParameters3D.create(from, to)
  query.exclude = [ self ]
  var hit := space.intersect_ray(query)

  if hit.size() > 0 and hit.has("collider") and hit.collider:
    var col: Node = hit.collider
    if col.is_in_group(symbol_group):
      return col
  return null

func _on_bumped_symbol(symbol: Node) -> void:
  # Play sfx
  if _sfx and _sfx.stream:
    _sfx.play()

  # Get blurb safely
  var blurb := ""
  if symbol.has_method("get_blurb"):
    blurb = symbol.get_blurb()
  elif symbol.has_meta("blurb"):
    blurb = str(symbol.get_meta("blurb"))
  elif "blurb" in symbol:
    blurb = str(symbol.blurb)

  # Open dialog if wired
  if _dialog_ui and _dialog_ui.has_method("open"):
    _dialog_ui.open(blurb)
