extends CharacterBody3D

@export var step_size: float = 1.0 # how big is one grid cell? (basically 1.0)
@export var step_duration: float = 0.1 # how long to spend moving one cell
@export var turn_duration: float = 0.25
@export var mouse_sensitivity: float = 0.15
@export var eye_height: float = 1

@export var dialog_ui_path: NodePath
@export var select_sfx_stream: AudioStream
@export var error_sfx_stream: AudioStream

var cam: Camera3D
var shape: CollisionShape3D
var mouse_delta: Vector2 = Vector2.ZERO
var yaw: float = 0.0
var pitch: float = 0.0

# Movement
var is_moving: bool = false
var is_animating: bool = false # Blocks input during animations
var move_dir: Vector3 = Vector3.ZERO
var target_position: Vector3 = Vector3.ZERO
var start_position: Vector3 = Vector3.ZERO # Grid-aligned position at movement start
var _block_cooldown: float = 0.0
var _blocked_move_dir: Vector3 = Vector3.ZERO # direction that got blocked
const BLOCK_COOLDOWN_DURATION: float = 0.8

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
  # Mouse-lock toggling
  if (!_is_mouse_captive()):
    if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
      _toggle_mouse_capture()
    else:
      return

  if Input.is_action_pressed("ui_cancel"):
    _toggle_mouse_capture()
    return

  if _block_cooldown > 0.0:
    _block_cooldown -= delta

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
        # Held walk: crash into symbol, stop silently at walls
        var symbol = _try_bump_interact()
        if symbol:
          _do_brake_animation()
        elif _block_cooldown <= 0.0 and not _is_path_blocked(-transform.basis.z):
          start_move(-transform.basis.z)
      elif Input.is_action_just_pressed("move_back"):
        if _is_path_blocked(transform.basis.z):
          if _error_sfx and _error_sfx.stream:
            _error_sfx.play()
        else:
          start_move(transform.basis.z)
      elif Input.is_action_pressed("move_back"):
        if _block_cooldown <= 0.0 and not _is_path_blocked(transform.basis.z):
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

    var pos_before = global_transform.origin
    move_and_slide()

    if move_dir.dot(target_position - global_transform.origin) <= 0:
      # Reached target - successful move
      is_moving = false
      _snap_to_grid()
    elif global_transform.origin.distance_to(pos_before) < 0.001:
      # Made no progress - blocked mid-move, snap back and unlock
      global_transform.origin = start_position
      is_moving = false
      _block_cooldown = BLOCK_COOLDOWN_DURATION
      _blocked_move_dir = move_dir
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
  _block_cooldown = 0.0
  var new_yaw = _cardinalize_deg(rotation_degrees.y + 90)
  _face_degree(new_yaw)

func turn_right():
  if is_moving: return
  _block_cooldown = 0.0
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

  var original_cam_pos = cam.position
  var original_cam_rot = cam.rotation_degrees

  # Lurch forward and tilt down
  var lurch_pos = original_cam_pos + Vector3(0, -0.1, -0.2) # Down and forward
  var lurch_rot = original_cam_rot + Vector3(8, 0, 0) # Tilt down

  var brake_tween = create_tween()
  brake_tween.set_parallel(true)
  # Quick lurch
  brake_tween.tween_property(cam, "position", lurch_pos, 0.1).set_ease(Tween.EASE_OUT)
  brake_tween.tween_property(cam, "rotation_degrees", lurch_rot, 0.1).set_ease(Tween.EASE_OUT)
  # Snap back
  brake_tween.chain().set_parallel(true)
  brake_tween.tween_property(cam, "position", original_cam_pos, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
  brake_tween.tween_property(cam, "rotation_degrees", original_cam_rot, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

  # Re-enable input after animation completes
  brake_tween.finished.connect(func(): is_animating = false)

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
  # Check if moving in this direction would hit something
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
