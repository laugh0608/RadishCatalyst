class_name SliceStorage
extends SliceBuildingInstance

## Powered field storage with one authoritative inventory. Supply mode exposes
## only the fixed right OUT endpoint; transfer mode exposes only the fixed left
## IN endpoint and periodically moves transportable contents to the repaired
## core warehouse. Manual access never depends on power.

const CAPACITY := 200
const TYPE_LIMIT := 4
const MODE_SUPPLY := "supply"
const MODE_TRANSFER := "transfer"
const TRANSFER_INTERVAL := 5.0
const TRANSFER_BATCH_SIZE := 50
const BLOCKED_WARNING_COOLDOWN := 1.25
const COLOR_DARK := Color(0.055, 0.08, 0.08, 0.76)
const COLOR_CYAN := Color(0.337, 0.784, 0.769, 1.0)
const COLOR_AMBER := Color(0.878, 0.643, 0.235, 1.0)
const COLOR_WARNING := Color(0.78, 0.314, 0.247, 1.0)
const FEEDBACK_SEGMENT_POSITIONS := [
	Vector2(-14, -67),
	Vector2(0, -71),
	Vector2(14, -67),
]

signal feedback_event_played(event_id: StringName)

var inventory := Inventory.new(SliceInventoryProfiles.category_storage())
var mode := MODE_SUPPLY
var output_item_id := ""
var transfer_cursor := 0
var transfer_progress := 0.0
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
	if not _feedback_state.is_empty():
		_refresh_feedback_frame()


func _exit_tree() -> void:
	_stop_feedback_audio()


func logistics_endpoints() -> Array[SliceLogisticsEndpoint]:
	var result: Array[SliceLogisticsEndpoint] = []
	if definition == null:
		return result
	var active_port_id := "output" if mode == MODE_SUPPLY else "input"
	var port := definition.logistics_port_definition(active_port_id)
	if port == null:
		return result
	result.append(SliceLogisticsEndpoint.new(
		self,
		port,
		Callable(self, "_accept_transfer_item"),
		Callable(self, "_peek_supply_output"),
		Callable(self, "_take_supply_output")
	))
	return result


func content_block_reason() -> String:
	return "" if inventory.is_empty() else "先清空储物箱"


func state_dict(allowed_keys: Array[String]) -> Dictionary:
	var result := {}
	if allowed_keys.has("inventory"):
		result["inventory"] = inventory.to_dict()
	if allowed_keys.has("mode"):
		result["mode"] = mode
	if allowed_keys.has("output_item_id"):
		result["output_item_id"] = output_item_id
	if allowed_keys.has("transfer_cursor"):
		result["transfer_cursor"] = transfer_cursor
	if allowed_keys.has("transfer_progress"):
		result["transfer_progress"] = transfer_progress
	return result


func restore_state(state: Dictionary) -> void:
	inventory = Inventory.from_dict(
		state.get("inventory", {}),
		SliceInventoryProfiles.category_storage()
	)
	mode = String(state.get("mode", MODE_SUPPLY))
	if mode != MODE_SUPPLY and mode != MODE_TRANSFER:
		mode = MODE_SUPPLY
	output_item_id = String(state.get("output_item_id", ""))
	if (
		not output_item_id.is_empty()
		and not SliceItemCatalog.is_transportable(output_item_id)
	):
		output_item_id = ""
	var transportable_count := SliceItemCatalog.transportable_ids().size()
	transfer_cursor = (
		posmod(int(state.get("transfer_cursor", 0)), transportable_count)
		if transportable_count > 0
		else 0
	)
	transfer_progress = clampf(
		float(state.get("transfer_progress", 0.0)),
		0.0,
		TRANSFER_INTERVAL - 0.000001
	)
	if mode != MODE_TRANSFER:
		transfer_progress = 0.0


func set_mode(next_mode: String) -> bool:
	if (
		(next_mode != MODE_SUPPLY and next_mode != MODE_TRANSFER)
		or next_mode == mode
	):
		return false
	if mode == MODE_TRANSFER:
		transfer_progress = 0.0
	mode = next_mode
	if mode == MODE_SUPPLY and output_item_id.is_empty():
		output_item_id = _first_present_transportable()
	return true


func toggle_mode() -> bool:
	return set_mode(
		MODE_TRANSFER if mode == MODE_SUPPLY else MODE_SUPPLY
	)


func set_output_item(next_item_id: String) -> bool:
	if (
		next_item_id == output_item_id
		or (
			not next_item_id.is_empty()
			and not SliceItemCatalog.is_transportable(next_item_id)
		)
	):
		return false
	output_item_id = next_item_id
	return true


func select_next_present_output() -> bool:
	var candidates := present_transportable_ids()
	if candidates.is_empty():
		return set_output_item("")
	var current_index := candidates.find(output_item_id)
	return set_output_item(
		candidates[(current_index + 1) % candidates.size()]
	)


func present_transportable_ids() -> Array[String]:
	var result: Array[String] = []
	for item_id in SliceItemCatalog.transportable_ids():
		if inventory.count(item_id) > 0:
			result.append(item_id)
	return result


func manual_deposit(
	source: Inventory,
	item_id: String,
	requested_amount: int = -1
) -> int:
	if (
		source == null
		or item_id.is_empty()
		or SliceItemCatalog.find(item_id) == null
	):
		return 0
	var was_empty := inventory.is_empty()
	var moved := source.transfer_up_to(
		inventory,
		item_id,
		source.count(item_id) if requested_amount < 0 else requested_amount
	)
	if (
		moved > 0
		and was_empty
		and output_item_id.is_empty()
		and SliceItemCatalog.is_transportable(item_id)
	):
		output_item_id = item_id
	return moved


func manual_withdraw(
	target: Inventory,
	item_id: String,
	requested_amount: int = -1
) -> int:
	if target == null or item_id.is_empty():
		return 0
	return inventory.transfer_up_to(
		target,
		item_id,
		inventory.count(item_id) if requested_amount < 0 else requested_amount
	)


## Advances transfer time only while at least one transportable item can move.
## A large delta is processed as discrete five-second pulses; time after a
## pulse pauses immediately if the source empties or every core item is full.
func tick_wireless_transfer(
	delta: float,
	core_repaired: bool,
	core_inventory: Inventory
) -> Dictionary:
	refresh_feedback(core_repaired, core_inventory)
	if (
		delta <= 0.0
		or mode != MODE_TRANSFER
		or not powered
		or not core_repaired
		or core_inventory == null
	):
		return _wireless_result(false, 0)

	var remaining_delta := delta
	var changed := false
	var moved_total := 0
	while remaining_delta > 0.0000001:
		if not _has_wireless_candidate(core_inventory):
			break
		var until_pulse := TRANSFER_INTERVAL - transfer_progress
		var advanced := minf(remaining_delta, until_pulse)
		transfer_progress += advanced
		remaining_delta -= advanced
		changed = changed or advanced > 0.0
		if transfer_progress + 0.0000001 < TRANSFER_INTERVAL:
			break
		transfer_progress = 0.0
		var moved := _transfer_wireless_pulse(core_inventory)
		moved_total += moved
		changed = changed or moved > 0
		if moved <= 0:
			break
	refresh_feedback(core_repaired, core_inventory)
	return _wireless_result(changed, moved_total)


func mode_display_name() -> String:
	return "存储模式" if mode == MODE_SUPPLY else "传输模式"


func type_count() -> int:
	return inventory.item_ids().size()


func refresh_feedback(
	core_repaired: bool,
	core_inventory: Inventory
) -> void:
	_ensure_feedback_nodes()
	var has_contents := not inventory.is_empty()
	var can_transfer := (
		mode == MODE_TRANSFER
		and powered
		and core_repaired
		and core_inventory != null
		and _has_wireless_candidate(core_inventory)
	)
	var next_state := SliceDeviceFeedbackState.storage_state(
		powered,
		mode == MODE_TRANSFER,
		has_contents,
		can_transfer
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
		SliceDeviceFeedbackState.STORAGE_SUPPLY:
			return 1
		SliceDeviceFeedbackState.STORAGE_TRANSFER_IDLE:
			return 2
		SliceDeviceFeedbackState.STORAGE_TRANSFER_RUNNING:
			return 3
		SliceDeviceFeedbackState.STORAGE_BLOCKED:
			return 2
	return 0


func feedback_audio_play_count() -> int:
	return _audio_play_count


func _accept_transfer_item(item_id: String) -> int:
	if mode != MODE_TRANSFER or not SliceItemCatalog.is_transportable(item_id):
		return 0
	return inventory.add(item_id, 1)


func _peek_supply_output() -> String:
	if (
		mode != MODE_SUPPLY
		or not powered
		or output_item_id.is_empty()
		or inventory.count(output_item_id) <= 0
	):
		return ""
	return output_item_id


func _take_supply_output(item_id: String) -> int:
	if (
		mode != MODE_SUPPLY
		or not powered
		or item_id != output_item_id
	):
		return 0
	return inventory.remove(item_id, 1)


func _has_wireless_candidate(core_inventory: Inventory) -> bool:
	for item_id in SliceItemCatalog.transportable_ids():
		if (
			inventory.count(item_id) > 0
			and core_inventory.free_space_for(item_id) > 0
		):
			return true
	return false


func _transfer_wireless_pulse(core_inventory: Inventory) -> int:
	var ordered_ids := SliceItemCatalog.transportable_ids()
	if ordered_ids.is_empty():
		transfer_cursor = 0
		return 0
	var remaining := TRANSFER_BATCH_SIZE
	var moved_total := 0
	var start := posmod(transfer_cursor, ordered_ids.size())
	for offset in range(ordered_ids.size()):
		var index := (start + offset) % ordered_ids.size()
		var item_id := ordered_ids[index]
		var moved := inventory.transfer_up_to(
			core_inventory,
			item_id,
			mini(remaining, inventory.count(item_id))
		)
		moved_total += moved
		remaining -= moved
		transfer_cursor = (index + 1) % ordered_ids.size()
		if remaining <= 0:
			break
	return moved_total


func _first_present_transportable() -> String:
	var present := present_transportable_ids()
	return "" if present.is_empty() else present[0]


func _wireless_result(changed: bool, moved: int) -> Dictionary:
	return {
		"changed": changed,
		"moved": moved,
	}


func _refresh_feedback_frame() -> void:
	var segments := _feedback_segments()
	if segments.size() != FEEDBACK_SEGMENT_POSITIONS.size():
		return
	for segment in segments:
		segment.color = COLOR_DARK
	var disconnect_mark := get_node_or_null(
		"FeedbackVisual/DisconnectMark"
	) as Polygon2D
	var supply_mark := get_node_or_null(
		"FeedbackVisual/SupplyMark"
	) as Polygon2D
	var transfer_mark := get_node_or_null(
		"FeedbackVisual/TransferMark"
	) as Polygon2D
	var blocked_mark := get_node_or_null(
		"FeedbackVisual/BlockedMark"
	) as Polygon2D
	for mark in [disconnect_mark, supply_mark, transfer_mark, blocked_mark]:
		if mark != null:
			mark.visible = false
	match _feedback_state:
		SliceDeviceFeedbackState.STORAGE_UNPOWERED:
			if disconnect_mark != null:
				disconnect_mark.visible = true
				disconnect_mark.color = COLOR_WARNING * 0.58
		SliceDeviceFeedbackState.STORAGE_SUPPLY:
			segments[1].color = COLOR_CYAN * 0.76
			if supply_mark != null:
				supply_mark.visible = true
				supply_mark.color = COLOR_CYAN
		SliceDeviceFeedbackState.STORAGE_TRANSFER_IDLE:
			segments[0].color = COLOR_CYAN * 0.38
			segments[2].color = COLOR_CYAN * 0.38
			if transfer_mark != null:
				transfer_mark.visible = true
				transfer_mark.color = COLOR_CYAN * 0.52
		SliceDeviceFeedbackState.STORAGE_TRANSFER_RUNNING:
			var active_index := int(floor(_feedback_time * 4.0)) % 3
			for index in range(segments.size()):
				segments[index].color = COLOR_CYAN * (
					1.0 if index == active_index else 0.38
				)
			if transfer_mark != null:
				transfer_mark.visible = true
				transfer_mark.color = COLOR_CYAN
		SliceDeviceFeedbackState.STORAGE_BLOCKED:
			var warning_on := fmod(_feedback_time, 0.72) < 0.36
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
	disconnect_mark.position = Vector2(-34, -48)
	disconnect_mark.polygon = PackedVector2Array([
		Vector2(-2, -7), Vector2(4, -7), Vector2(0, -1),
		Vector2(5, -1), Vector2(-4, 8), Vector2(-1, 2),
		Vector2(-6, 2),
	])
	visual.add_child(disconnect_mark)
	var supply_mark := Polygon2D.new()
	supply_mark.name = "SupplyMark"
	supply_mark.position = Vector2(35, -48)
	supply_mark.polygon = PackedVector2Array([
		Vector2(-7, -3), Vector2(1, -3), Vector2(1, -7),
		Vector2(8, 0), Vector2(1, 7), Vector2(1, 3),
		Vector2(-7, 3),
	])
	visual.add_child(supply_mark)
	var transfer_mark := Polygon2D.new()
	transfer_mark.name = "TransferMark"
	transfer_mark.position = Vector2(-34, -48)
	transfer_mark.polygon = PackedVector2Array([
		Vector2(7, -3), Vector2(-1, -3), Vector2(-1, -7),
		Vector2(-8, 0), Vector2(-1, 7), Vector2(-1, 3),
		Vector2(7, 3),
	])
	visual.add_child(transfer_mark)
	var blocked_mark := Polygon2D.new()
	blocked_mark.name = "BlockedMark"
	blocked_mark.position = Vector2(35, -48)
	blocked_mark.polygon = PackedVector2Array([
		Vector2(-7, -5), Vector2(-4, -8), Vector2(0, -3),
		Vector2(4, -8), Vector2(7, -5), Vector2(3, 0),
		Vector2(7, 5), Vector2(4, 8), Vector2(0, 3),
		Vector2(-4, 8), Vector2(-7, 5), Vector2(-3, 0),
	])
	visual.add_child(blocked_mark)
	var pulse := Line2D.new()
	pulse.name = "TransitionPulse"
	pulse.width = 2.0
	pulse.default_color = COLOR_CYAN
	pulse.closed = true
	pulse.antialiased = false
	pulse.points = PackedVector2Array([
		Vector2(-52, -80), Vector2(52, -80),
		Vector2(56, -2), Vector2(-56, -2),
	])
	pulse.visible = false
	visual.add_child(pulse)
	var player := AudioStreamPlayer2D.new()
	player.name = "FeedbackAudio"
	player.bus = &"SFX"
	player.position = Vector2(0, -40)
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
