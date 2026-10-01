class_name SliceCollector
extends SliceBuildingInstance

## Placed crystal collector: produces into one authoritative output buffer.
## Manual withdrawal and the fixed right logistics endpoint consume the same
## count, so belt backpressure cannot duplicate or discard production.

const BUFFER_CAP := 50
const OUTPUT_ITEM_ID := "crystal"
const BLOCKED_WARNING_COOLDOWN := 1.25
const COLOR_DARK := Color(0.055, 0.08, 0.08, 0.76)
const COLOR_CYAN := Color(0.337, 0.784, 0.769, 1.0)
const COLOR_AMBER := Color(0.878, 0.643, 0.235, 1.0)
const COLOR_WARNING := Color(0.78, 0.314, 0.247, 1.0)
const FEEDBACK_SEGMENT_POSITIONS := [
	Vector2(-14, -102),
	Vector2(0, -106),
	Vector2(14, -102),
]

signal feedback_event_played(event_id: StringName)

var buffer := 0
var production_progress := 0.0
var _feedback_state := &""
var _feedback_time := 0.0
var _pulse_remaining := 0.0
var _blocked_warning_cooldown := 0.0
var _audio_play_count := 0


func _ready() -> void:
	_ensure_feedback_nodes()


func _process(delta: float) -> void:
	_feedback_time += delta
	_pulse_remaining = maxf(0.0, _pulse_remaining - delta)
	_blocked_warning_cooldown = maxf(
		0.0, _blocked_warning_cooldown - delta
	)
	refresh_feedback()


func _exit_tree() -> void:
	_stop_feedback_audio()


func logistics_endpoints() -> Array[SliceLogisticsEndpoint]:
	var result: Array[SliceLogisticsEndpoint] = []
	if definition == null:
		return result
	var port := definition.logistics_port_definition("output")
	if port == null:
		return result
	result.append(SliceLogisticsEndpoint.new(
		self,
		port,
		Callable(),
		Callable(self, "_peek_logistics_output"),
		Callable(self, "_take_logistics_output")
	))
	return result


func has_space() -> bool:
	return buffer < BUFFER_CAP


func produce(n: int) -> void:
	buffer = mini(buffer + n, BUFFER_CAP)


func state_dict(allowed_keys: Array[String]) -> Dictionary:
	var result := {}
	if allowed_keys.has("buffer"):
		result["buffer"] = buffer
	if allowed_keys.has("production_progress"):
		result["production_progress"] = production_progress
	return result


func content_block_reason() -> String:
	return "" if buffer <= 0 else "先取空采集器"


func refresh_feedback() -> void:
	_ensure_feedback_nodes()
	var next_state := SliceDeviceFeedbackState.collector_state(
		powered, buffer, BUFFER_CAP
	)
	var event_id := SliceDeviceFeedbackState.common_device_edge_event(
		_feedback_state, next_state
	)
	if _feedback_state != next_state:
		_feedback_state = next_state
		_feedback_time = 0.0
		if (
			event_id != SliceDeviceFeedbackState.EVENT_DEVICE_BLOCKED
			or _blocked_warning_cooldown <= 0.0
		):
			_play_feedback(event_id)
	_refresh_feedback_frame()


func feedback_state() -> StringName:
	return _feedback_state


func feedback_active_segment_count() -> int:
	match _feedback_state:
		SliceDeviceFeedbackState.COLLECTOR_COLLECTING:
			return 3
		SliceDeviceFeedbackState.COLLECTOR_FULL:
			return 3
	return 0


func feedback_audio_play_count() -> int:
	return _audio_play_count


func _peek_logistics_output() -> String:
	return OUTPUT_ITEM_ID if buffer > 0 else ""


func _take_logistics_output(item_id: String) -> int:
	if item_id != OUTPUT_ITEM_ID or buffer <= 0:
		return 0
	buffer -= 1
	return 1


func _refresh_feedback_frame() -> void:
	var segments := _feedback_segments()
	if segments.size() != FEEDBACK_SEGMENT_POSITIONS.size():
		return
	for segment in segments:
		segment.color = COLOR_DARK
	var disconnect_mark := get_node_or_null(
		"FeedbackVisual/DisconnectMark"
	) as Polygon2D
	var full_mark := get_node_or_null(
		"FeedbackVisual/FullMark"
	) as Polygon2D
	if disconnect_mark != null:
		disconnect_mark.visible = false
	if full_mark != null:
		full_mark.visible = false
	match _feedback_state:
		SliceDeviceFeedbackState.COLLECTOR_UNPOWERED:
			if disconnect_mark != null:
				disconnect_mark.visible = true
				disconnect_mark.color = COLOR_WARNING * 0.58
		SliceDeviceFeedbackState.COLLECTOR_COLLECTING:
			var active_index := int(floor(_feedback_time * 4.2)) % 3
			for index in range(segments.size()):
				segments[index].color = COLOR_CYAN * (
					1.0 if index == active_index else 0.38
				)
		SliceDeviceFeedbackState.COLLECTOR_FULL:
			var warning_on := fmod(_feedback_time, 0.72) < 0.36
			for segment in segments:
				segment.color = COLOR_AMBER * (1.0 if warning_on else 0.48)
			if full_mark != null:
				full_mark.visible = true
				full_mark.color = COLOR_WARNING
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
	var progress := 1.0 - _pulse_remaining / 0.32
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
	_pulse_remaining = 0.32
	_refresh_transition_pulse()
	if event_id == SliceDeviceFeedbackState.EVENT_DEVICE_BLOCKED:
		_blocked_warning_cooldown = BLOCKED_WARNING_COOLDOWN
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
			Vector2(-4, -2), Vector2(4, -2),
			Vector2(4, 2), Vector2(-4, 2),
		])
		segment.position = FEEDBACK_SEGMENT_POSITIONS[index]
		segment.color = COLOR_DARK
		visual.add_child(segment)
	var disconnect_mark := Polygon2D.new()
	disconnect_mark.name = "DisconnectMark"
	disconnect_mark.position = Vector2(-29, -82)
	disconnect_mark.polygon = PackedVector2Array([
		Vector2(-2, -7), Vector2(4, -7), Vector2(0, -1),
		Vector2(5, -1), Vector2(-4, 8), Vector2(-1, 2),
		Vector2(-6, 2),
	])
	visual.add_child(disconnect_mark)
	var full_mark := Polygon2D.new()
	full_mark.name = "FullMark"
	full_mark.position = Vector2(30, -82)
	full_mark.polygon = PackedVector2Array([
		Vector2(-7, -7), Vector2(7, -7), Vector2(7, -3),
		Vector2(-7, -3), Vector2(-7, 2), Vector2(7, 2),
		Vector2(7, 6), Vector2(-7, 6),
	])
	visual.add_child(full_mark)
	var pulse := Line2D.new()
	pulse.name = "TransitionPulse"
	pulse.width = 2.0
	pulse.default_color = COLOR_CYAN
	pulse.closed = true
	pulse.antialiased = false
	pulse.points = PackedVector2Array([
		Vector2(-48, -112), Vector2(48, -112),
		Vector2(52, -2), Vector2(-52, -2),
	])
	pulse.visible = false
	visual.add_child(pulse)
	var player := AudioStreamPlayer2D.new()
	player.name = "FeedbackAudio"
	player.bus = &"SFX"
	player.position = Vector2(0, -56)
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
