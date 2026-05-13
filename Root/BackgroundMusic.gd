extends AudioStreamPlayer

class_name BackgroundMusic

signal playback_changed(is_playing: bool, track_title: String)

@onready var num_tracks: int = stream.clip_count

var playback: AudioStreamPlaybackInteractive = null

var _tracks: Dictionary = {}
var _track_order: Dictionary = {}
var _last_reported_clip: int = -2
var _last_reported_is_playing: bool = false

func _ready() -> void:
  # Pick a random start track
  var random_track = randi_range(0, num_tracks - 2) # -1 for 0-based index, -1 to exclude Cuban Pete track
  stream.set_initial_clip(random_track)
  play()
  playback = get_stream_playback()

  # Make a lookup table for tracks to clip indices based on AutoAdvance order,
  # since the AudioStream doesn't provide a way to query this.
  for i in range(num_tracks):
    var next_clip_idx = stream.get_clip_auto_advance_next_clip(i)
    _track_order[i] = next_clip_idx
    _tracks[stream.get_clip_name(i)] = i

  # Give a moment for playback to start and emit the initial state.
  await get_tree().process_frame
  _emit_playback_changed_if_needed(true)


func _process(_delta: float) -> void:
  _emit_playback_changed_if_needed(false)


func _emit_playback_changed_if_needed(force_emit: bool = false) -> void:
  var clip_idx = current_track()

  if not force_emit and clip_idx == _last_reported_clip and is_playing() == _last_reported_is_playing:
    return

  _last_reported_clip = clip_idx
  _last_reported_is_playing = is_playing()
  playback_changed.emit(is_playing(), current_track_title())

func next() -> void:
  var next_track = stream.get_clip_auto_advance_next_clip(current_track())
  playback.switch_to_clip(next_track)
  _emit_playback_changed_if_needed(true)

func previous() -> void:
  # Find the value to key into _track_order that has the current track as its
  # value, which gives us the previous track in the auto-advance order.
  var prev_track: int = _track_order.keys().find_custom(func(key):
    return _track_order[key] == current_track()
  )
  if prev_track == -1:
    prev_track = 0 # Fallback to first track if we can't find the current track for some reason.
  playback.switch_to_clip(prev_track)
  _emit_playback_changed_if_needed(true)

func current_track() -> int:
  if playback:
    return playback.get_current_clip_index()
  return -1

func current_track_title() -> String:
  var clip_idx = current_track()
  if clip_idx != -1:
    return stream.get_clip_name(clip_idx)
  return ""

func pause() -> void:
  stream_paused = true
  _emit_playback_changed_if_needed(true)

func unpause() -> void:
  stream_paused = false
  _emit_playback_changed_if_needed(true)

func toggle_playback() -> void:
  stream_paused = not stream_paused
  _emit_playback_changed_if_needed(true)

func play_track_by_name(track_name: String) -> void:
  if not _tracks.has(track_name):
    return
  playback.switch_to_clip_by_name(track_name)
  _emit_playback_changed_if_needed(true)
