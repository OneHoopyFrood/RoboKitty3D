extends CharacterBody3D

signal player_movement(direction: Vector3)

## Distance moved per step input; also defines grid cell size
@export var step_size: float = 1.0
## Duration of a single step movement (lower = snappier but less forgiving)
@export var step_duration: float = 0.1
## Duration of 90-degree turn (lower = snappier but may cause motion sickness)
@export var turn_duration: float = 0.25
## Mouse movement to camera rotation ratio (higher = more responsive, less precise)
@export var mouse_sensitivity: float = 0.15
## Camera catch-up speed to target angles (higher = snappier but less smooth)
@export var look_smoothing: float = 10.0
## Ease-out curve steepness (higher = more pronounced; tweak carefully)
@export var look_ease_power: float = 1.5
## Camera height above player origin (adjust based on model height)
@export var eye_height: float = 1

@export var dialog_ui_path: NodePath
@export var select_sfx_stream: AudioStream
@export var error_sfx_stream: AudioStream

var cam: Camera3D
var shape: CollisionShape3D
var mouse_delta: Vector2 = Vector2.ZERO
var target_yaw: float = 0.0 # Where the mouse wants to look
var target_pitch: float = 0.0
var yaw: float = 0.0 # Current camera angle (smoothed)
var pitch: float = 0.0

# Movement
var is_moving: bool = false
var is_animating: bool = false # Blocks input during animations
var move_dir: Vector3 = Vector3.ZERO
var target_position: Vector3 = Vector3.ZERO
var start_position: Vector3 = Vector3.ZERO # Grid-aligned position at movement start
var is_walking: bool = false # True when in continuous walk sequence; false after brake, turn, or key release

var _tween: Tween
var _dialog_ui: Node = null
var _sfx: AudioStreamPlayer = null
var _error_sfx: AudioStreamPlayer = null

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

  # Error SFX player
  _error_sfx = AudioStreamPlayer.new()
  add_child(_error_sfx)
  if error_sfx_stream:
    _error_sfx.stream = error_sfx_stream

func _input(event):
  if event is InputEventMouseMotion:
    mouse_delta = event.relative

func _process(delta):
  # Early exit if mouse capture not active
  if not _handle_mouse_capture():
    return

  # Handle movement and interaction input
  _handle_movement_input(delta)

  # Handle mouse look
  _handle_look_input(delta)

## Handle mouse capture toggling. Returns false if processing should stop.
func _handle_mouse_capture() -> bool:
  if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
    if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
      Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
      print_debug("Mouse captured")
      # Fall through to `return true`, capturing the mouse
    else:
      return false # Don't process input if mouse not captured
  elif Input.is_action_pressed("ui_cancel"):
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    print_debug("Mouse released")
    return false # Stop processing input on this frame to avoid sudden jumps when toggling capture
  return true

## Process all movement and interaction input (forward, back, turn).
func _handle_movement_input(delta: float) -> void:
  # Reset walk sequence when player releases movement keys
  if not Input.is_action_pressed("move_forward") and not Input.is_action_pressed("move_back"):
    is_walking = false

  if not is_moving and not is_animating:
    if Input.is_action_just_pressed("move_left"):
      turn_left()
    elif Input.is_action_just_pressed("move_right"):
      turn_right()
    else:
      # Interactions only trigger on intentional bumps (standing -> just_pressed).
      # Walking into symbols (action_pressed while moving) should collide naturally
      # without triggering interaction.
      if Input.is_action_just_pressed("move_forward"):
        # Intentional tap: interact or error
        var symbol = _try_bump_interact()
        if symbol:
          _on_bumped_symbol(symbol)
        elif _is_path_blocked(-transform.basis.z):
          if _error_sfx and _error_sfx.stream:
            _error_sfx.play()
        else:
          start_move(-transform.basis.z)
      elif Input.is_action_pressed("move_forward"):
        # Held walk: brake when hitting any obstacle during continuous walk
        if is_walking and _is_path_blocked(-transform.basis.z):
          # Hit obstacle during continuous walk - brake and end sequence
          _do_brake_animation()
          is_walking = false
        elif not _is_path_blocked(-transform.basis.z):
          start_move(-transform.basis.z)
          is_walking = true
      elif Input.is_action_just_pressed("move_back"):
        # Backward tap (always allowed)
        if _is_path_blocked(transform.basis.z):
          if _error_sfx and _error_sfx.stream:
            _error_sfx.play()
        else:
          start_move(transform.basis.z)
      elif Input.is_action_pressed("move_back"):
        # Held walk backward: brake when hitting any obstacle
        if is_walking and _is_path_blocked(transform.basis.z):
          # Hit obstacle during continuous walk - brake and end sequence
          _do_brake_animation()
          is_walking = false
        elif not _is_path_blocked(transform.basis.z):
          start_move(transform.basis.z)
          is_walking = true

## Process mouse look input and apply smoothed camera rotation.
func _handle_look_input(delta: float) -> void:
  # Update target angles based on mouse input
  if Input.is_action_pressed("look"):
    target_yaw -= mouse_delta.x * mouse_sensitivity
    target_yaw = clamp(target_yaw, -89.0, 89.0)
    target_pitch -= mouse_delta.y * mouse_sensitivity
    target_pitch = clamp(target_pitch, -89.0, 89.0)
    mouse_delta = Vector2.ZERO

  # Exponential decay for smooth ease-out (starts fast, slows as it approaches, no oscillation)
  var smoothing_factor = 1.0 - exp(-look_smoothing * delta)
  var eased_factor = pow(smoothing_factor, look_ease_power) # Apply power curve for steeper easing
  yaw = lerp(yaw, target_yaw, eased_factor)
  pitch = lerp(pitch, target_pitch, eased_factor)
  cam.rotation_degrees = Vector3(pitch, yaw, 0)

  if Input.is_action_just_released("look"):
    recenter_look()

func _physics_process(delta):
  if is_moving:
    # Compute the speed so we travel exactly step_size units in step_duration seconds
    var speed = step_size / step_duration
    velocity = move_dir.normalized() * speed

    var pos_before = global_transform.origin
    move_and_slide()

    if move_dir.dot(target_position - global_transform.origin) <= 0:
      # Reached target - successful move
      is_moving = false
      _snap_to_grid()
      # Note: is_walking persists here to allow continuous walk sequence to continue
    elif global_transform.origin.distance_to(pos_before) < 0.001:
      # Made no progress - blocked mid-move, snap back and end walk sequence
      global_transform.origin = start_position
      is_moving = false
      is_walking = false
      # Error SFX on wall bump
      if _error_sfx and _error_sfx.stream:
        _error_sfx.play()
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
  is_walking = false # Turning ends walk sequence
  var new_yaw = _cardinalize_deg(rotation_degrees.y + 90)
  _face_degree(new_yaw)
  var dir = _yaw_to_direction(new_yaw)
  print_debug("Player turn_left: emitting player_movement with direction: ", dir)
  player_movement.emit(dir)

func turn_right():
  if is_moving: return
  is_walking = false # Turning ends walk sequence
  var new_yaw = _cardinalize_deg(rotation_degrees.y - 90)
  _face_degree(new_yaw)
  var dir = _yaw_to_direction(new_yaw)
  print_debug("Player turn_right: emitting player_movement with direction: ", dir)
  player_movement.emit(dir)

func recenter_look():
  target_yaw = 0
  target_pitch = 0
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

func _yaw_to_direction(yaw_deg: float) -> Vector3:
  var r = deg_to_rad(yaw_deg)
  return Vector3(-sin(r), 0, -cos(r))

func _face_degree(turn_degrees: float):
  _tween = create_tween().bind_node(self )
  _tween.set_trans(Tween.TRANS_ELASTIC)
  _tween.tween_property(self , "rotation_degrees", Vector3(0, turn_degrees, 0), turn_duration)


func _snap_to_grid() -> void:
  # Snap position to nearest grid cell center
  var snapped_pos = global_transform.origin
  snapped_pos.x = round(snapped_pos.x / step_size) * step_size
  snapped_pos.z = round(snapped_pos.z / step_size) * step_size
  global_transform.origin = snapped_pos

func _do_bump_bounce() -> void:
  # Bounce animation: slight forward movement, then hop backward with camera shake
  is_animating = true

  var fwd = - transform.basis.z
  fwd.y = 0
  fwd = fwd.normalized()

  var start_pos = global_transform.origin
  var forward_pos = start_pos + fwd * (step_size * 0.15) # Move 15% forward

  # Animate player body
  var body_tween = create_tween()
  body_tween.tween_property(self , "global_position", forward_pos, 0.08)
  body_tween.tween_property(self , "global_position", start_pos, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

  # Re-enable input after animation completes
  body_tween.finished.connect(func(): is_animating = false)

  # Camera shake
  var original_cam_pos = cam.position
  var shake_tween = create_tween()
  shake_tween.tween_property(cam, "position", original_cam_pos + Vector3(randf_range(-0.05, 0.05), randf_range(-0.05, 0.05), randf_range(-0.05, 0.05)), 0.05)
  shake_tween.tween_property(cam, "position", original_cam_pos + Vector3(randf_range(-0.03, 0.03), randf_range(-0.03, 0.03), 0), 0.05)
  shake_tween.tween_property(cam, "position", original_cam_pos, 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _do_brake_animation() -> void:
  # Brake animation: camera lurches forward and down like sudden deceleration, then snaps back
  is_animating = true

  var fwd = - transform.basis.z
  fwd.y = 0
  fwd = fwd.normalized()

  var start_pos = global_transform.origin
  var forward_pos = start_pos + fwd * (step_size * 0.08) # Small forward skid

  # Animate player body forward and back
  var body_tween = create_tween()
  body_tween.tween_property(self , "global_position", forward_pos, 0.06)
  body_tween.tween_property(self , "global_position", start_pos, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
  body_tween.finished.connect(func(): is_animating = false)

  # Camera lurch
  var original_cam_pos = cam.position
  var original_cam_rot = cam.rotation_degrees
  var lurch_pos = original_cam_pos + Vector3(0, -0.08, -0.15) # Down and forward
  var lurch_rot = original_cam_rot + Vector3(-5, 0, 0) # Tilt up slightly

  var cam_tween = create_tween()
  cam_tween.set_parallel(true)
  cam_tween.tween_property(cam, "position", lurch_pos, 0.06).set_ease(Tween.EASE_OUT)
  cam_tween.tween_property(cam, "rotation_degrees", lurch_rot, 0.06).set_ease(Tween.EASE_OUT)
  cam_tween.tween_property(cam, "position", original_cam_pos, 0.18).set_delay(0.06).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
  cam_tween.tween_property(cam, "rotation_degrees", original_cam_rot, 0.18).set_delay(0.06).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

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
    # The collider is typically ColliderBody (StaticBody3D), parent is the Symbol
    var parent = col.get_parent()
    if parent and parent is Symbol:
      return parent
  return null

func _is_path_blocked(direction: Vector3) -> bool:
  # Check if moving in this direction would hit something or go out of bounds
  var target_pos := global_transform.origin + direction.normalized() * step_size

  # World boundaries - get board_size from World node parent
  var world = get_parent()
  if world:
    var board_size = world.get("board_size")
    if board_size is int or board_size is float:
      var boundary = int(board_size / 2)
      if abs(target_pos.x) >= boundary or abs(target_pos.z) >= boundary:
        return true

  # Raycast for collisions with objects
  var from := global_transform.origin + Vector3(0, eye_height * 0.5, 0)
  var fwd := direction
  fwd.y = 0
  fwd = fwd.normalized()
  var to := from + fwd * (step_size * 0.95)

  var space := get_world_3d().direct_space_state
  var query := PhysicsRayQueryParameters3D.create(from, to)
  query.exclude = [ self ]
  var hit := space.intersect_ray(query)

  return hit.size() > 0

func _on_bumped_symbol(symbol: Node) -> void:
  # Log interaction
  print_debug("Bumped symbol: ", symbol.name)

  # Bounce off the symbol
  _do_bump_bounce()

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
