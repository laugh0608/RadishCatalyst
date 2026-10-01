class_name SliceCoreVisual
extends Node2D

## Y-sorted presentation shell for the fixed map core. The logical core stays
## at its frozen world position; this sibling shell sorts at the footprint
## front edge so belts remain behind it and the player can still pass in front.

const SORT_ANCHOR_OFFSET := Vector2(0, 33)
const SPRITE_POSITION := Vector2(0, -33)
const REPAIRED_SPRITE_OFFSET := Vector2(0, -32)
const INPUT_DOCKING_POSITION := Vector2(-66, 13)
const OUTPUT_DOCKING_POSITION := Vector2(66, 13)
const DOCKING_PATCH_SIZE := Vector2(12, 24)
const INPUT_DOCKING_TEXTURE_LOCAL_ANCHOR := Vector2i(0, 97)
const OUTPUT_DOCKING_TEXTURE_LOCAL_ANCHOR := Vector2i(132, 97)
const LEFT_DOCKING_TEXTURE := preload(
	"res://assets/sprites/slice/docking_left_connected_patch.png"
)
const RIGHT_DOCKING_TEXTURE := preload(
	"res://assets/sprites/slice/docking_right_connected_patch.png"
)
const COLOR_DARK := Color(0.055, 0.08, 0.08, 0.76)
const COLOR_CYAN := Color(0.337, 0.784, 0.769, 1.0)
const COLOR_AMBER := Color(0.878, 0.643, 0.235, 1.0)
const COLOR_WARNING := Color(0.78, 0.314, 0.247, 1.0)
const SEGMENT_POSITIONS := [
	Vector2(-16, -104),
	Vector2(0, -108),
	Vector2(16, -104),
]

signal feedback_event_played(event_id: StringName)

var _feedback_state := &""
var _feedback_time := 0.0
var _pulse_remaining := 0.0
var _audio_play_count := 0


func _ready() -> void:
	_ensure_feedback_nodes()


func _process(delta: float) -> void:
	if _feedback_state.is_empty():
		return
	_feedback_time += delta
	_pulse_remaining = maxf(0.0, _pulse_remaining - delta)
	_refresh_feedback_frame()


func apply_repaired_texture(texture: Texture2D) -> void:
	var sprite := _sprite()
	if sprite == null:
		return
	sprite.texture = texture
	sprite.offset = REPAIRED_SPRITE_OFFSET


func set_connected_logistics_port_visuals(
	connected_port_ids: Array[String]
) -> void:
	_set_docking_patch(
		"InputDockingPatch",
		LEFT_DOCKING_TEXTURE,
		INPUT_DOCKING_POSITION,
		connected_port_ids.has("input")
	)
	_set_docking_patch(
		"OutputDockingPatch",
		RIGHT_DOCKING_TEXTURE,
		OUTPUT_DOCKING_POSITION,
		connected_port_ids.has("output")
	)


func set_core_modulate(color: Color) -> void:
	var sprite := _sprite()
	if sprite != null:
		sprite.self_modulate = color


func apply_feedback_state(next_state: StringName) -> void:
	if next_state not in [
		SliceDeviceFeedbackState.CORE_DAMAGED,
		SliceDeviceFeedbackState.CORE_REPAIRED,
		SliceDeviceFeedbackState.CORE_CHARGED,
		SliceDeviceFeedbackState.CORE_SAMPLE_INSTALLED,
	]:
		push_error("Unsupported core feedback state: %s" % next_state)
		return
	_ensure_feedback_nodes()
	var event_id := SliceDeviceFeedbackState.core_edge_event(
		_feedback_state, next_state
	)
	if _feedback_state == next_state:
		return
	_feedback_state = next_state
	_feedback_time = 0.0
	_refresh_feedback_frame()
	if not event_id.is_empty():
		_pulse_remaining = 0.42
		_play_feedback(event_id)
		_refresh_pulse()


func feedback_state() -> StringName:
	return _feedback_state


func feedback_active_segment_count() -> int:
	match _feedback_state:
		SliceDeviceFeedbackState.CORE_DAMAGED:
			return 2
		SliceDeviceFeedbackState.CORE_REPAIRED:
			return 1
		SliceDeviceFeedbackState.CORE_CHARGED:
			return 3
		SliceDeviceFeedbackState.CORE_SAMPLE_INSTALLED:
			return 3
	return 0


func feedback_audio_play_count() -> int:
	return _audio_play_count


func core_sprite() -> Sprite2D:
	return _sprite()


func _refresh_feedback_frame() -> void:
	var segments := _feedback_segments()
	if segments.size() != SEGMENT_POSITIONS.size():
		return
	for index in range(segments.size()):
		segments[index].color = COLOR_DARK
	var fault_mark := get_node_or_null(
		"FeedbackVisual/FaultMark"
	) as Polygon2D
	var lock_mark := get_node_or_null(
		"FeedbackVisual/LockMark"
	) as Polygon2D
	if fault_mark != null:
		fault_mark.visible = false
	if lock_mark != null:
		lock_mark.visible = false
	match _feedback_state:
		SliceDeviceFeedbackState.CORE_DAMAGED:
			var fault_on := (
				fmod(_feedback_time, 0.82) < 0.13
				or (fmod(_feedback_time, 0.82) > 0.26
				and fmod(_feedback_time, 0.82) < 0.34)
			)
			segments[0].color = COLOR_WARNING * (1.0 if fault_on else 0.38)
			segments[2].color = COLOR_WARNING * (0.72 if fault_on else 0.28)
			if fault_mark != null:
				fault_mark.visible = true
				fault_mark.color = COLOR_WARNING * (1.0 if fault_on else 0.42)
		SliceDeviceFeedbackState.CORE_REPAIRED:
			var breath := 0.5 + 0.5 * sin(_feedback_time * 2.2)
			segments[1].color = COLOR_AMBER * lerpf(0.42, 0.92, breath)
		SliceDeviceFeedbackState.CORE_CHARGED:
			var active_index := int(floor(_feedback_time * 3.2)) % 3
			for index in range(segments.size()):
				segments[index].color = COLOR_CYAN * (
					1.0 if index == active_index else 0.48
				)
		SliceDeviceFeedbackState.CORE_SAMPLE_INSTALLED:
			for segment in segments:
				segment.color = COLOR_AMBER
			if lock_mark != null:
				lock_mark.visible = true
				lock_mark.color = COLOR_AMBER
	_refresh_pulse()
	_refresh_sprite_tone()


func _refresh_sprite_tone() -> void:
	match _feedback_state:
		SliceDeviceFeedbackState.CORE_CHARGED:
			set_core_modulate(Color(0.92, 1.0, 0.98, 1.0))
		SliceDeviceFeedbackState.CORE_SAMPLE_INSTALLED:
			set_core_modulate(Color(1.0, 0.98, 0.88, 1.0))
		_:
			set_core_modulate(Color.WHITE)


func _refresh_pulse() -> void:
	var pulse := get_node_or_null(
		"FeedbackVisual/TransitionPulse"
	) as Line2D
	if pulse == null:
		return
	pulse.visible = _pulse_remaining > 0.0
	if not pulse.visible:
		return
	var progress := 1.0 - _pulse_remaining / 0.42
	pulse.scale = Vector2.ONE * lerpf(0.82, 1.08, progress)
	pulse.modulate = Color(1.0, 1.0, 1.0, 1.0 - progress)


func _play_feedback(event_id: StringName) -> void:
	var player := get_node_or_null("FeedbackAudio") as AudioStreamPlayer2D
	var stream := SliceFeedbackAudio.stream_for(event_id)
	if player == null or stream == null:
		return
	player.stream = stream
	player.play()
	_audio_play_count += 1
	feedback_event_played.emit(event_id)


func _ensure_feedback_nodes() -> void:
	if get_node_or_null("FeedbackVisual") != null:
		return
	var visual := Node2D.new()
	visual.name = "FeedbackVisual"
	visual.z_index = 6
	add_child(visual)
	for index in range(SEGMENT_POSITIONS.size()):
		var segment := Polygon2D.new()
		segment.name = "Segment%d" % (index + 1)
		segment.polygon = PackedVector2Array([
			Vector2(-5, -3), Vector2(5, -3),
			Vector2(5, 3), Vector2(-5, 3),
		])
		segment.position = SEGMENT_POSITIONS[index]
		segment.color = COLOR_DARK
		visual.add_child(segment)
	var fault_mark := Polygon2D.new()
	fault_mark.name = "FaultMark"
	fault_mark.position = Vector2(-29, -84)
	fault_mark.polygon = PackedVector2Array([
		Vector2(-2, -8), Vector2(4, -8), Vector2(1, -1),
		Vector2(6, -1), Vector2(-3, 9), Vector2(0, 2),
		Vector2(-5, 2),
	])
	visual.add_child(fault_mark)
	var lock_mark := Polygon2D.new()
	lock_mark.name = "LockMark"
	lock_mark.position = Vector2(29, -84)
	lock_mark.polygon = PackedVector2Array([
		Vector2(0, -8), Vector2(6, -3), Vector2(6, 5),
		Vector2(0, 9), Vector2(-6, 5), Vector2(-6, -3),
	])
	visual.add_child(lock_mark)
	var pulse := Line2D.new()
	pulse.name = "TransitionPulse"
	pulse.width = 2.0
	pulse.default_color = COLOR_CYAN
	pulse.closed = true
	pulse.antialiased = false
	pulse.points = PackedVector2Array([
		Vector2(-54, -116), Vector2(54, -116),
		Vector2(62, -18), Vector2(-62, -18),
	])
	pulse.visible = false
	visual.add_child(pulse)
	var player := AudioStreamPlayer2D.new()
	player.name = "FeedbackAudio"
	player.bus = &"SFX"
	player.position = Vector2(0, -64)
	player.max_distance = 640.0
	add_child(player)


func _feedback_segments() -> Array[Polygon2D]:
	var result: Array[Polygon2D] = []
	for index in range(SEGMENT_POSITIONS.size()):
		var segment := get_node_or_null(
			"FeedbackVisual/Segment%d" % (index + 1)
		) as Polygon2D
		if segment != null:
			result.append(segment)
	return result


func _set_docking_patch(
	node_name: String,
	texture: Texture2D,
	local_position: Vector2,
	shown: bool
) -> void:
	var sprite := _sprite()
	if sprite == null:
		return
	var patch := sprite.get_node_or_null(node_name) as Sprite2D
	if patch == null and shown:
		patch = Sprite2D.new()
		patch.name = node_name
		patch.texture = texture
		patch.position = local_position
		patch.z_index = 0
		sprite.add_child(patch)
	if patch != null:
		patch.visible = shown


func _sprite() -> Sprite2D:
	return get_node_or_null("Sprite") as Sprite2D
