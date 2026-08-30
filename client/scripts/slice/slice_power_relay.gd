class_name SlicePowerRelay
extends SliceBuildingInstance

## Power relay presentation owns only the derived online/offline readout. The
## power graph remains authoritative for connectivity and never reads visuals.

const COLOR_DARK := Color(0.055, 0.08, 0.08, 0.76)
const COLOR_CYAN := Color(0.337, 0.784, 0.769, 1.0)
const COLOR_WARNING := Color(0.78, 0.314, 0.247, 1.0)
const FEEDBACK_SEGMENT_POSITIONS := [
	Vector2(-12, -56),
	Vector2(0, -69),
	Vector2(12, -56),
]

signal feedback_event_played(event_id: StringName)

var _feedback_state := &""
var _feedback_time := 0.0
var _pulse_remaining := 0.0
var _audio_play_count := 0


func _ready() -> void:
	_ensure_feedback_nodes()


func _process(delta: float) -> void:
	_feedback_time += delta
	_pulse_remaining = maxf(0.0, _pulse_remaining - delta)
	refresh_feedback()


func _exit_tree() -> void:
	_stop_feedback_audio()


func refresh_feedback() -> void:
	_ensure_feedback_nodes()
	var next_state := SliceDeviceFeedbackState.relay_state(powered)
	var event_id := SliceDeviceFeedbackState.common_device_edge_event(
		_feedback_state, next_state
	)
	if _feedback_state != next_state:
		_feedback_state = next_state
		_feedback_time = 0.0
		_play_feedback(event_id)
	_refresh_feedback_frame()


func feedback_state() -> StringName:
	return _feedback_state


func feedback_active_segment_count() -> int:
	return 3 if _feedback_state == SliceDeviceFeedbackState.RELAY_ONLINE else 0


func feedback_audio_play_count() -> int:
	return _audio_play_count


func _refresh_feedback_frame() -> void:
	var segments := _feedback_segments()
	if segments.size() != FEEDBACK_SEGMENT_POSITIONS.size():
		return
	for segment in segments:
		segment.color = COLOR_DARK
	var online_ring := get_node_or_null(
		"FeedbackVisual/OnlineRing"
	) as Line2D
	var disconnect_mark := get_node_or_null(
		"FeedbackVisual/DisconnectMark"
	) as Polygon2D
	if online_ring != null:
		online_ring.visible = false
	if disconnect_mark != null:
		disconnect_mark.visible = false
	match _feedback_state:
		SliceDeviceFeedbackState.RELAY_UNPOWERED:
			if disconnect_mark != null:
				disconnect_mark.visible = true
				disconnect_mark.color = COLOR_WARNING * 0.64
		SliceDeviceFeedbackState.RELAY_ONLINE:
			var active_index := int(floor(_feedback_time * 3.6)) % 3
			for index in range(segments.size()):
				segments[index].color = COLOR_CYAN * (
					1.0 if index == active_index else 0.42
				)
			if online_ring != null:
				online_ring.visible = true
				online_ring.default_color = COLOR_CYAN * (
					0.74 + 0.18 * sin(_feedback_time * 3.2)
				)
	_refresh_transition_pulse()


func _refresh_transition_pulse() -> void:
	var pulse := get_node_or_null(
		"FeedbackVisual/TransitionPulse"
	) as Line2D
	if pulse == null:
		return
	pulse.visible = _pulse_remaining > 0.0
	if not pulse.visible:
		return
	var progress := 1.0 - _pulse_remaining / 0.30
	pulse.scale = Vector2.ONE * lerpf(0.84, 1.08, progress)
	pulse.modulate = Color(1.0, 1.0, 1.0, 1.0 - progress)


func _play_feedback(event_id: StringName) -> void:
	if event_id.is_empty() or not is_inside_tree():
		return
	var player := get_node_or_null("FeedbackAudio") as AudioStreamPlayer2D
	var stream := SliceFeedbackAudio.stream_for(event_id)
	if player == null or stream == null:
		return
	player.stream = stream
	player.play()
	_audio_play_count += 1
	_pulse_remaining = 0.30
	_refresh_transition_pulse()
	feedback_event_played.emit(event_id)


func _stop_feedback_audio() -> void:
	var player := get_node_or_null("FeedbackAudio") as AudioStreamPlayer2D
	if player == null:
		return
	player.stop()
	player.stream = null


func _ensure_feedback_nodes() -> void:
	if get_node_or_null("FeedbackVisual") != null:
		return
	var visual := Node2D.new()
	visual.name = "FeedbackVisual"
	visual.z_index = 6
	add_child(visual)
	for index in range(FEEDBACK_SEGMENT_POSITIONS.size()):
		var segment := Polygon2D.new()
		segment.name = "Segment%d" % (index + 1)
		segment.polygon = PackedVector2Array([
			Vector2(0, -3), Vector2(3, 0),
			Vector2(0, 3), Vector2(-3, 0),
		])
		segment.position = FEEDBACK_SEGMENT_POSITIONS[index]
		segment.color = COLOR_DARK
		visual.add_child(segment)
	var online_ring := Line2D.new()
	online_ring.name = "OnlineRing"
	online_ring.width = 2.0
	online_ring.default_color = COLOR_CYAN
	online_ring.closed = true
	online_ring.antialiased = false
	online_ring.points = PackedVector2Array([
		Vector2(0, -66), Vector2(10, -61), Vector2(10, -51),
		Vector2(0, -46), Vector2(-10, -51), Vector2(-10, -61),
	])
	visual.add_child(online_ring)
	var disconnect_mark := Polygon2D.new()
	disconnect_mark.name = "DisconnectMark"
	disconnect_mark.position = Vector2(0, -56)
	disconnect_mark.polygon = PackedVector2Array([
		Vector2(-2, -8), Vector2(4, -8), Vector2(0, -1),
		Vector2(5, -1), Vector2(-4, 9), Vector2(-1, 2),
		Vector2(-6, 2),
	])
	visual.add_child(disconnect_mark)
	var pulse := Line2D.new()
	pulse.name = "TransitionPulse"
	pulse.width = 2.0
	pulse.default_color = COLOR_CYAN
	pulse.closed = true
	pulse.antialiased = false
	pulse.points = PackedVector2Array([
		Vector2(-25, -78), Vector2(25, -78),
		Vector2(28, -2), Vector2(-28, -2),
	])
	pulse.visible = false
	visual.add_child(pulse)
	var player := AudioStreamPlayer2D.new()
	player.name = "FeedbackAudio"
	player.bus = &"SFX"
	player.position = Vector2(0, -38)
	player.max_distance = 640.0
	add_child(player)


func _feedback_segments() -> Array[Polygon2D]:
	var result: Array[Polygon2D] = []
	for index in range(FEEDBACK_SEGMENT_POSITIONS.size()):
		var segment := get_node_or_null(
			"FeedbackVisual/Segment%d" % (index + 1)
		) as Polygon2D
		if segment != null:
			result.append(segment)
	return result
