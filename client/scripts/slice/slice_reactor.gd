class_name SliceReactor
extends SliceBuildingInstance

## Powered fixed-recipe reactor. Input is consumed atomically when a batch
## starts; power loss pauses retained progress, and the one-slot output buffer
## prevents the next batch from starting until catalyst is withdrawn.

const INPUT_CAPACITY := 2
const OUTPUT_CAPACITY := 1
const PROCESS_DURATION := 10.0
const INPUT_ITEM_ID := "crystal"
const OUTPUT_ITEM_ID := "catalyst"
const PROCESSING_OVERLAY_TEXTURES := [
	preload("res://assets/sprites/slice/reactor_processing_pulse_a.png"),
	preload("res://assets/sprites/slice/reactor_processing_pulse_b.png"),
]
const PROCESSING_OVERLAY_TEXTURE_LOCAL_ANCHOR := Vector2(48, 28)
const BLOCKED_WARNING_COOLDOWN := 1.25
const COLOR_DARK := Color(0.055, 0.08, 0.08, 0.76)
const COLOR_CYAN := Color(0.337, 0.784, 0.769, 1.0)
const COLOR_AMBER := Color(0.878, 0.643, 0.235, 1.0)
const COLOR_WARNING := Color(0.78, 0.314, 0.247, 1.0)
const FEEDBACK_SEGMENT_POSITIONS := [
	Vector2(-12, -68),
	Vector2(0, -72),
	Vector2(12, -68),
]

signal feedback_event_played(event_id: StringName)

var input_inventory := Inventory.new(
	SliceInventoryProfiles.device_reactor_input()
)
var output_inventory := Inventory.new(
	SliceInventoryProfiles.device_reactor_output()
)
var processing := false
var production_progress := 0.0
var _feedback_state := &""
var _feedback_time := 0.0
var _pulse_remaining := 0.0
var _blocked_warning_cooldown := 0.0
var _audio_play_count := 0


func _ready() -> void:
	_ensure_feedback_nodes()


func logistics_endpoints() -> Array[SliceLogisticsEndpoint]:
	var result: Array[SliceLogisticsEndpoint] = []
	if definition == null:
		return result
	for port in definition.logistics_ports:
		if port.role == SliceLogisticsPortDefinition.ROLE_INPUT:
			result.append(SliceLogisticsEndpoint.new(
				self,
				port,
				Callable(self, "_accept_logistics_input")
			))
		elif port.role == SliceLogisticsPortDefinition.ROLE_OUTPUT:
			result.append(SliceLogisticsEndpoint.new(
				self,
				port,
				Callable(),
				Callable(self, "_peek_logistics_output"),
				Callable(self, "_take_logistics_output")
			))
	return result


func _process(delta: float) -> void:
	_feedback_time += delta
	_pulse_remaining = maxf(0.0, _pulse_remaining - delta)
	_blocked_warning_cooldown = maxf(
		0.0, _blocked_warning_cooldown - delta
	)
	_refresh_processing_visual()
	refresh_feedback()


func can_start_batch() -> bool:
	return (
		powered
		and not processing
		and input_inventory.count(INPUT_ITEM_ID) >= INPUT_CAPACITY
		and output_inventory.is_empty()
	)


func tick(delta: float) -> Dictionary:
	var result := {
		"changed": false,
		"started": false,
		"completed": false,
		"progressed": false,
	}
	if delta <= 0.0 or not powered:
		return result

	if can_start_batch():
		var consumed := input_inventory.remove(INPUT_ITEM_ID, INPUT_CAPACITY)
		if consumed != INPUT_CAPACITY:
			push_error("Reactor input changed after start validation.")
			input_inventory.restore_existing(INPUT_ITEM_ID, consumed)
			return result
		processing = true
		production_progress = 0.0
		result["changed"] = true
		result["started"] = true

	if not processing:
		return result

	production_progress += delta
	result["changed"] = true
	result["progressed"] = true
	if (
		production_progress < PROCESS_DURATION
		and not is_equal_approx(production_progress, PROCESS_DURATION)
	):
		return result

	var stored := output_inventory.add(OUTPUT_ITEM_ID, 1)
	if stored != 1:
		push_error("Reactor output changed while a batch was processing.")
		production_progress = PROCESS_DURATION - 0.001
		return result
	processing = false
	production_progress = 0.0
	result["completed"] = true
	return result


func state_dict(allowed_keys: Array[String]) -> Dictionary:
	var result := {}
	if allowed_keys.has("input_inventory"):
		result["input_inventory"] = input_inventory.to_dict()
	if allowed_keys.has("output_inventory"):
		result["output_inventory"] = output_inventory.to_dict()
	if allowed_keys.has("processing"):
		result["processing"] = processing
	if allowed_keys.has("production_progress"):
		result["production_progress"] = production_progress
	return result


func content_block_reason() -> String:
	if processing:
		return "反应器正在生产"
	if not input_inventory.is_empty() or not output_inventory.is_empty():
		return "先取空反应器"
	return ""


func operation_status_text(output_can_extract: bool) -> String:
	if not powered:
		return "断电：加工暂停" if processing else "断电"
	if processing:
		return "加工中"
	if not output_inventory.is_empty():
		return "待出料" if output_can_extract else "出料堵塞"
	if input_inventory.count(INPUT_ITEM_ID) < INPUT_CAPACITY:
		return "缺晶体"
	return "就绪"


func refresh_feedback() -> void:
	_ensure_feedback_nodes()
	var next_state := SliceDeviceFeedbackState.reactor_state(
		powered,
		processing,
		not output_inventory.is_empty()
	)
	var event_id := SliceDeviceFeedbackState.reactor_edge_event(
		_feedback_state, next_state
	)
	if _feedback_state != next_state:
		_feedback_state = next_state
		_feedback_time = 0.0
		if (
			event_id != SliceDeviceFeedbackState.EVENT_REACTOR_BLOCKED
			or _blocked_warning_cooldown <= 0.0
		):
			_play_feedback(event_id)
	_refresh_feedback_frame()


func feedback_state() -> StringName:
	return _feedback_state


func feedback_active_segment_count() -> int:
	match _feedback_state:
		SliceDeviceFeedbackState.REACTOR_IDLE:
			return 1
		SliceDeviceFeedbackState.REACTOR_PROCESSING:
			return 3
		SliceDeviceFeedbackState.REACTOR_BLOCKED:
			return 2
	return 0


func feedback_audio_play_count() -> int:
	return _audio_play_count


func _accept_logistics_input(item_id: String) -> int:
	if item_id != INPUT_ITEM_ID:
		return 0
	return input_inventory.add(item_id, 1)


func _peek_logistics_output() -> String:
	return (
		OUTPUT_ITEM_ID
		if output_inventory.count(OUTPUT_ITEM_ID) > 0
		else ""
	)


func _take_logistics_output(item_id: String) -> int:
	if item_id != OUTPUT_ITEM_ID:
		return 0
	return output_inventory.remove(item_id, 1)


func recover_contents_to(target: Inventory) -> Dictionary:
	var crystal_count := input_inventory.count(INPUT_ITEM_ID)
	if processing:
		crystal_count += INPUT_CAPACITY
	var catalyst_count := output_inventory.count(OUTPUT_ITEM_ID)
	var total := crystal_count + catalyst_count
	if total <= 0:
		return {
			"success": false,
			"message": "反应器内没有可回收物料",
		}
	var recovered_items := {}
	if crystal_count > 0:
		recovered_items[INPUT_ITEM_ID] = crystal_count
	if catalyst_count > 0:
		recovered_items[OUTPUT_ITEM_ID] = catalyst_count
	if not target.can_add_batch(recovered_items):
		return {
			"success": false,
			"message": "背包空间不足，未回收任何物料",
		}

	if not target.add_batch(recovered_items):
		push_error("Reactor recovery capacity changed after validation.")
		return {
			"success": false,
			"message": "背包空间变化，未回收任何物料",
		}
	input_inventory.remove(
		INPUT_ITEM_ID, input_inventory.count(INPUT_ITEM_ID)
	)
	output_inventory.remove(
		OUTPUT_ITEM_ID, output_inventory.count(OUTPUT_ITEM_ID)
	)
	processing = false
	production_progress = 0.0
	return {
		"success": true,
		"crystal": crystal_count,
		"catalyst": catalyst_count,
		"message": "已回收晶体 %d、催化剂 %d" % [
			crystal_count,
			catalyst_count,
		],
	}


func _refresh_processing_visual() -> void:
	if definition == null:
		return
	var body_sprite := get_node_or_null("Sprite") as Sprite2D
	if body_sprite == null or body_sprite.texture == null:
		return
	var sprite := get_node_or_null("ProcessingOverlay") as Sprite2D
	if sprite == null:
		sprite = Sprite2D.new()
		sprite.name = "ProcessingOverlay"
		sprite.z_index = 4
		add_child(sprite)
	var texture_origin := body_sprite.position + body_sprite.offset
	if body_sprite.centered:
		texture_origin -= Vector2(body_sprite.texture.get_size()) * 0.5
	sprite.position = (
		texture_origin + PROCESSING_OVERLAY_TEXTURE_LOCAL_ANCHOR
	)
	sprite.visible = processing and powered
	if not sprite.visible:
		return
	var frame := int(floor(production_progress * 4.0)) % 2
	sprite.texture = PROCESSING_OVERLAY_TEXTURES[frame]
	sprite.modulate = Color.WHITE


func _refresh_feedback_frame() -> void:
	var segments := _feedback_segments()
	if segments.size() != FEEDBACK_SEGMENT_POSITIONS.size():
		return
	for segment in segments:
		segment.color = COLOR_DARK
	var disconnect_mark := get_node_or_null(
		"FeedbackVisual/DisconnectMark"
	) as Polygon2D
	var blocked_mark := get_node_or_null(
		"FeedbackVisual/BlockedMark"
	) as Polygon2D
	if disconnect_mark != null:
		disconnect_mark.visible = false
	if blocked_mark != null:
		blocked_mark.visible = false
	match _feedback_state:
		SliceDeviceFeedbackState.REACTOR_UNPOWERED:
			if disconnect_mark != null:
				disconnect_mark.visible = true
				disconnect_mark.color = COLOR_WARNING * 0.56
		SliceDeviceFeedbackState.REACTOR_IDLE:
			segments[1].color = COLOR_CYAN * 0.72
		SliceDeviceFeedbackState.REACTOR_PROCESSING:
			var active_index := int(floor(_feedback_time * 4.0)) % 3
			for index in range(segments.size()):
				segments[index].color = COLOR_CYAN * (
					1.0 if index == active_index else 0.42
				)
		SliceDeviceFeedbackState.REACTOR_BLOCKED:
			var warning_on := fmod(_feedback_time, 0.64) < 0.32
			segments[0].color = COLOR_WARNING * (
				1.0 if warning_on else 0.36
			)
			segments[2].color = COLOR_AMBER * (
				0.42 if warning_on else 1.0
			)
			if blocked_mark != null:
				blocked_mark.visible = true
				blocked_mark.color = COLOR_WARNING
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
	var progress := 1.0 - _pulse_remaining / 0.34
	pulse.scale = Vector2.ONE * lerpf(0.84, 1.08, progress)
	pulse.modulate = Color(1.0, 1.0, 1.0, 1.0 - progress)


func _play_feedback(event_id: StringName) -> void:
	if event_id.is_empty():
		return
	var player := get_node_or_null("FeedbackAudio") as AudioStreamPlayer2D
	var stream := SliceFeedbackAudio.stream_for(event_id)
	if player == null or stream == null:
		return
	player.stream = stream
	player.play()
	_audio_play_count += 1
	_pulse_remaining = 0.34
	_refresh_transition_pulse()
	if event_id == SliceDeviceFeedbackState.EVENT_REACTOR_BLOCKED:
		_blocked_warning_cooldown = BLOCKED_WARNING_COOLDOWN
	feedback_event_played.emit(event_id)


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
	disconnect_mark.position = Vector2(-27, -55)
	disconnect_mark.polygon = PackedVector2Array([
		Vector2(-2, -7), Vector2(4, -7), Vector2(0, -1),
		Vector2(5, -1), Vector2(-4, 8), Vector2(-1, 2),
		Vector2(-6, 2),
	])
	visual.add_child(disconnect_mark)
	var blocked_mark := Polygon2D.new()
	blocked_mark.name = "BlockedMark"
	blocked_mark.position = Vector2(27, -55)
	blocked_mark.polygon = PackedVector2Array([
		Vector2(-6, -7), Vector2(-2, -7), Vector2(-2, 7),
		Vector2(-6, 7), Vector2(-6, -7), Vector2(2, -7),
		Vector2(6, -7), Vector2(6, 7), Vector2(2, 7),
		Vector2(2, -7),
	])
	visual.add_child(blocked_mark)
	var pulse := Line2D.new()
	pulse.name = "TransitionPulse"
	pulse.width = 2.0
	pulse.default_color = COLOR_CYAN
	pulse.closed = true
	pulse.antialiased = false
	pulse.points = PackedVector2Array([
		Vector2(-42, -84), Vector2(42, -84),
		Vector2(48, -3), Vector2(-48, -3),
	])
	pulse.visible = false
	visual.add_child(pulse)
	var player := AudioStreamPlayer2D.new()
	player.name = "FeedbackAudio"
	player.bus = &"SFX"
	player.position = Vector2(0, -44)
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
