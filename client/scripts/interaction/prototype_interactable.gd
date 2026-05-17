extends Area2D
class_name PrototypeInteractable

const DEFAULT_MARKER_COLOR := Color(0.862745, 0.737255, 0.266667, 1)
const RESTORED_OUTPOST_CORE_COLOR := Color(0.18, 0.86, 0.93, 1)
const GATHERED_CRYSTAL_COLOR := Color(0.22, 0.42, 0.58, 1)
const GATHERED_SALVAGE_COLOR := Color(0.48, 0.56, 0.58, 1)
const SAMPLED_ANOMALY_COLOR := Color(0.7, 0.38, 0.82, 1)
const GATHERED_ANOMALY_RESIDUE_COLOR := Color(0.42, 0.52, 0.72, 1)
const GATHERED_RESIDUE_COLOR := Color(0.44, 0.42, 0.2, 1)
const GATHERED_RELAY_SHARD_COLOR := Color(0.54, 0.54, 0.66, 1)
const GATHERED_PHASE_FILAMENT_COLOR := Color(0.66, 0.46, 0.7, 1)
const GATHERED_PHASE_CONDUIT_COLOR := Color(0.56, 0.72, 0.82, 1)
const GATHERED_PHASE_SPLINTER_COLOR := Color(0.78, 0.62, 0.9, 1)
const GATHERED_WELL_FLUX_COLOR := Color(0.74, 0.82, 0.96, 1)
const GATHERED_WELL_ASH_COLOR := Color(0.82, 0.66, 0.42, 1)
const GATHERED_HEART_SPINE_COLOR := Color(0.88, 0.58, 0.48, 1)
const GATHERED_WEFT_BUNDLE_COLOR := Color(0.92, 0.68, 0.6, 1)
const GATHERED_SELVEDGE_STRIP_COLOR := Color(0.96, 0.78, 0.66, 1)
const GATHERED_TETHER_FIBER_COLOR := Color(0.98, 0.84, 0.72, 1)
const CLEARED_GROUND_COLOR := Color(0.42, 0.5, 0.42, 1)
const CONFIRMED_RUIN_SIGNAL_COLOR := Color(0.36, 0.5, 0.68, 1)
const STABILIZED_BARRIER_COLOR := Color(0.42, 0.66, 0.78, 1)
const SECURED_CONSOLE_COLOR := Color(0.34, 0.74, 0.74, 1)
const RECOVERED_SIGNAL_ECHO_COLOR := Color(0.44, 0.78, 0.88, 1)
const OPENED_DEEP_RUIN_DOOR_COLOR := Color(0.62, 0.54, 0.82, 1)
const OVERRIDDEN_DEEP_RUIN_LATCH_COLOR := Color(0.9, 0.62, 0.44, 1)
const ACTIVATED_DEEP_SIGNAL_ARRAY_COLOR := Color(0.72, 0.82, 0.92, 1)
const DEPLOYED_PHASE_RETURN_ANCHOR_COLOR := Color(0.46, 0.84, 0.9, 1)
const STANDBY_PHASE_RETURN_ANCHOR_COLOR := Color(0.34, 0.64, 0.72, 1)
const READY_PHASE_RELAY_PAD_COLOR := Color(0.48, 0.92, 0.72, 1)
const TUNED_PHASE_FAULT_SPIRE_COLOR := Color(0.86, 0.74, 0.42, 1)
const STABILIZED_PHASE_WELL_LOCK_COLOR := Color(0.92, 0.82, 0.52, 1)
const STABILIZED_INNER_PHASE_WELL_COLOR := Color(0.8, 0.92, 0.64, 1)
const STABILIZED_PHASE_WELL_SINK_COLOR := Color(0.94, 0.78, 0.56, 1)
const STABILIZED_PHASE_WELL_CHAMBER_COLOR := Color(0.96, 0.64, 0.58, 1)
const STABILIZED_PHASE_WELL_LOOM_COLOR := Color(0.98, 0.74, 0.64, 1)
const STABILIZED_PHASE_WELL_FRAME_COLOR := Color(0.99, 0.82, 0.68, 1)
const STABILIZED_PHASE_WELL_TETHER_COLOR := Color(1.0, 0.88, 0.72, 1)
const DEPLOYED_PHASE_WELL_ANCHOR_FIELD_COLOR := Color(0.86, 0.86, 0.58, 1)
const READY_PHASE_WELL_ANCHOR_FIELD_COLOR := Color(0.76, 0.96, 0.68, 1)
const STABILIZED_PHASE_WELL_ANCHOR_FIELD_COLOR := Color(0.62, 0.98, 0.82, 1)
const READY_STABILITY_CALIBRATION_COLOR := Color(0.66, 0.9, 0.96, 1)
const CALIBRATED_STABILITY_NODE_COLOR := Color(0.48, 0.82, 0.92, 1)
const COMPLETED_FRONTLINE_ACTION_COLOR := Color(0.56, 0.9, 0.78, 1)
const BUILT_FOUNDATION_COLOR := Color(0.55, 0.6, 0.55, 1)
const BUILT_FILTER_COLOR := Color(0.72, 0.78, 0.38, 1)

@export var definition_id: String = ""
@export var interaction_type: String = "inspect"
@export var recipe_id: String = ""
@export var prerequisite_instance_id: String = ""
@export var single_use: bool = true
@export var label_offset := Vector2(-72.0, 20.0)
@export var label_size := Vector2(144.0, 24.0)

var consumed: bool = false
var instance_id: String = ""
var recipe_ids: Array[String] = []
var recipe_index: int = 0
var display_name_text: String = ""

@onready var label: Label = $Label
@onready var marker: ColorRect = $Marker


func setup(display_name: String) -> void:
	display_name_text = display_name
	label.offset_left = label_offset.x
	label.offset_top = label_offset.y
	label.offset_right = label_offset.x + label_size.x
	_set_label_text(display_name)


func can_interact() -> bool:
	return not consumed and visible and monitoring


func set_recipe_cycle(available_recipe_ids: Array[String]) -> void:
	recipe_ids.clear()
	for available_recipe_id in available_recipe_ids:
		recipe_ids.append(available_recipe_id)
	if recipe_ids.is_empty():
		return

	var existing_index := recipe_ids.find(recipe_id)
	recipe_index = maxi(existing_index, 0)
	recipe_id = recipe_ids[recipe_index]


func get_current_recipe_id() -> String:
	if recipe_ids.is_empty():
		return recipe_id

	recipe_index = clampi(recipe_index, 0, recipe_ids.size() - 1)
	recipe_id = recipe_ids[recipe_index]
	return recipe_id


func select_next_recipe() -> String:
	if recipe_ids.is_empty():
		return get_current_recipe_id()

	recipe_index = (recipe_index + 1) % recipe_ids.size()
	recipe_id = recipe_ids[recipe_index]
	return recipe_id


func select_recipe(target_recipe_id: String) -> bool:
	if target_recipe_id.is_empty():
		return false
	if recipe_ids.is_empty():
		if recipe_id != target_recipe_id:
			return false
		return true

	var target_index := recipe_ids.find(target_recipe_id)
	if target_index < 0:
		return false
	recipe_index = target_index
	recipe_id = recipe_ids[recipe_index]
	return true


func has_recipe(target_recipe_id: String) -> bool:
	if target_recipe_id.is_empty():
		return false
	if recipe_ids.is_empty():
		return recipe_id == target_recipe_id
	return recipe_ids.has(target_recipe_id)


func get_recipe_count() -> int:
	if recipe_ids.is_empty() and not recipe_id.is_empty():
		return 1
	return recipe_ids.size()


func get_recipe_position() -> int:
	if get_recipe_count() <= 0:
		return 0
	return recipe_index + 1


func mark_consumed() -> void:
	if interaction_type == "outpost_core":
		set_restored_outpost_core_visual()
		return
	if interaction_type == "build":
		set_built_visual(definition_id)
		return
	if set_processed_visual():
		return
	if single_use:
		consumed = true
		visible = false
		monitoring = false


func set_interaction_enabled(enabled: bool) -> void:
	visible = enabled
	monitoring = enabled


func set_default_visual() -> void:
	consumed = false
	visible = true
	monitoring = true
	marker.color = DEFAULT_MARKER_COLOR
	_set_label_text(display_name_text)


func set_restored_outpost_core_visual() -> void:
	consumed = false
	visible = true
	monitoring = true
	marker.color = RESTORED_OUTPOST_CORE_COLOR
	_set_label_text("%s\n已恢复，可整备" % display_name_text, 2)


func set_processed_visual() -> bool:
	if interaction_type == "gather" and (definition_id == "map_object.crystal_cluster" or definition_id == "map_object.rich_crystal_vein"):
		consumed = true
		visible = true
		monitoring = false
		marker.color = GATHERED_CRYSTAL_COLOR
		_set_label_text("%s\n已采集" % display_name_text, 2)
		return true
	if interaction_type == "gather" and definition_id == "map_object.field_wreckage":
		consumed = true
		visible = true
		monitoring = false
		marker.color = GATHERED_SALVAGE_COLOR
		_set_label_text("%s\n已回收" % display_name_text, 2)
		return true
	if interaction_type == "gather" and definition_id == "map_object.anomaly_residue_patch":
		consumed = true
		visible = true
		monitoring = false
		marker.color = GATHERED_ANOMALY_RESIDUE_COLOR
		_set_label_text("%s\n已回收" % display_name_text, 2)
		return true
	if interaction_type == "gather" and definition_id == "map_object.pollution_residue_patch":
		consumed = true
		visible = true
		monitoring = false
		marker.color = GATHERED_RESIDUE_COLOR
		_set_label_text("%s\n已回收" % display_name_text, 2)
		return true
	if interaction_type == "gather" and definition_id == "map_object.relay_shard_cache":
		consumed = true
		visible = true
		monitoring = false
		marker.color = GATHERED_RELAY_SHARD_COLOR
		_set_label_text("%s\n已回收" % display_name_text, 2)
		return true
	if interaction_type == "gather" and definition_id == "map_object.phase_filament_cluster":
		consumed = true
		visible = true
		monitoring = false
		marker.color = GATHERED_PHASE_FILAMENT_COLOR
		_set_label_text("%s\n已回收" % display_name_text, 2)
		return true
	if interaction_type == "gather" and definition_id == "map_object.phase_conduit_cluster":
		consumed = true
		visible = true
		monitoring = false
		marker.color = GATHERED_PHASE_CONDUIT_COLOR
		_set_label_text("%s\n已回收" % display_name_text, 2)
		return true
	if interaction_type == "gather" and definition_id == "map_object.phase_splinter_cluster":
		consumed = true
		visible = true
		monitoring = false
		marker.color = GATHERED_PHASE_SPLINTER_COLOR
		_set_label_text("%s\n已回收" % display_name_text, 2)
		return true
	if interaction_type == "gather" and definition_id == "map_object.fault_residue_cluster":
		consumed = true
		visible = true
		monitoring = false
		marker.color = GATHERED_PHASE_SPLINTER_COLOR
		_set_label_text("%s\n已回收" % display_name_text, 2)
		return true
	if interaction_type == "gather" and definition_id == "map_object.well_flux_cluster":
		consumed = true
		visible = true
		monitoring = false
		marker.color = GATHERED_WELL_FLUX_COLOR
		_set_label_text("%s\n已回收" % display_name_text, 2)
		return true
	if interaction_type == "gather" and definition_id == "map_object.well_ash_cluster":
		consumed = true
		visible = true
		monitoring = false
		marker.color = GATHERED_WELL_ASH_COLOR
		_set_label_text("%s\n已回收" % display_name_text, 2)
		return true
	if interaction_type == "gather" and definition_id == "map_object.heart_spine_cluster":
		consumed = true
		visible = true
		monitoring = false
		marker.color = GATHERED_HEART_SPINE_COLOR
		_set_label_text("%s\n已回收" % display_name_text, 2)
		return true
	if interaction_type == "gather" and definition_id == "map_object.weft_bundle_cluster":
		consumed = true
		visible = true
		monitoring = false
		marker.color = GATHERED_WEFT_BUNDLE_COLOR
		_set_label_text("%s\n已回收" % display_name_text, 2)
		return true
	if interaction_type == "gather" and definition_id == "map_object.selvedge_strip_cluster":
		consumed = true
		visible = true
		monitoring = false
		marker.color = GATHERED_SELVEDGE_STRIP_COLOR
		_set_label_text("%s\n已回收" % display_name_text, 2)
		return true
	if interaction_type == "gather" and definition_id == "map_object.tether_fiber_cluster":
		consumed = true
		visible = true
		monitoring = false
		marker.color = GATHERED_TETHER_FIBER_COLOR
		_set_label_text("%s\n已回收" % display_name_text, 2)
		return true
	if interaction_type == "sample" and definition_id == "map_object.anomaly_crystal":
		consumed = true
		visible = true
		monitoring = false
		marker.color = SAMPLED_ANOMALY_COLOR
		_set_label_text("%s\n已采样" % display_name_text, 2)
		return true
	if interaction_type == "clear" and definition_id == "map_object.rough_ground":
		consumed = true
		visible = true
		monitoring = false
		marker.color = CLEARED_GROUND_COLOR
		_set_label_text("%s\n已清理" % display_name_text, 2)
		return true
	if interaction_type == "clear" and definition_id == "map_object.phase_well_frame_route_blocker":
		consumed = true
		visible = true
		monitoring = false
		marker.color = CLEARED_GROUND_COLOR
		_set_label_text("%s\n已清理" % display_name_text, 2)
		return true
	if interaction_type == "clear" and definition_id == "map_object.phase_well_anchor_pressure_pin":
		consumed = true
		visible = true
		monitoring = false
		marker.color = CLEARED_GROUND_COLOR
		_set_label_text("%s\n已清理" % display_name_text, 2)
		return true
	if interaction_type == "clear" and definition_id == "map_object.well_ash_crust_blocker":
		consumed = true
		visible = true
		monitoring = false
		marker.color = CLEARED_GROUND_COLOR
		_set_label_text("%s\n已清理" % display_name_text, 2)
		return true
	if interaction_type == "inspect" and (
		definition_id == "map_object.phase_splinter_resonance_node"
		or definition_id == "map_object.fault_residue_pulse_node"
		or definition_id == "map_object.well_flux_pressure_vent"
		or definition_id == "map_object.phase_well_chamber_shunt_node"
		or definition_id == "map_object.phase_well_loom_tension_spool"
		or definition_id == "map_object.phase_well_tether_knot_node"
	):
		consumed = true
		visible = true
		monitoring = false
		marker.color = READY_STABILITY_CALIBRATION_COLOR
		_set_label_text("%s\n读数已写入" % display_name_text, 2)
		return true
	if interaction_type == "inspect" and definition_id == "map_object.frontline_action_console":
		consumed = true
		visible = true
		monitoring = false
		marker.color = COMPLETED_FRONTLINE_ACTION_COLOR
		_set_label_text("%s\n行动已确认" % display_name_text, 2)
		return true
	if interaction_type == "inspect" and definition_id == "map_object.stability_echo_probe":
		consumed = true
		visible = true
		monitoring = false
		marker.color = COMPLETED_FRONTLINE_ACTION_COLOR
		_set_label_text("%s\n样本已读取" % display_name_text, 2)
		return true
	return false


func set_confirmed_ruin_signal_visual() -> void:
	consumed = true
	visible = true
	monitoring = false
	marker.color = CONFIRMED_RUIN_SIGNAL_COLOR
	_set_label_text("%s\n信号已确认" % display_name_text, 2)


func set_stabilized_barrier_visual() -> void:
	consumed = true
	visible = true
	monitoring = false
	marker.color = STABILIZED_BARRIER_COLOR
	_set_label_text("%s\n已稳定" % display_name_text, 2)


func set_secured_console_visual() -> void:
	consumed = true
	visible = true
	monitoring = false
	marker.color = SECURED_CONSOLE_COLOR
	_set_label_text("%s\n数据已读取" % display_name_text, 2)


func set_recovered_signal_echo_visual() -> void:
	consumed = true
	visible = true
	monitoring = false
	marker.color = RECOVERED_SIGNAL_ECHO_COLOR
	_set_label_text("%s\n回波已回收" % display_name_text, 2)


func set_opened_deep_ruin_door_visual() -> void:
	consumed = true
	visible = true
	monitoring = false
	marker.color = OPENED_DEEP_RUIN_DOOR_COLOR
	_set_label_text("%s\n门禁已写入" % display_name_text, 2)


func set_overridden_deep_ruin_latch_visual() -> void:
	consumed = true
	visible = true
	monitoring = false
	marker.color = OVERRIDDEN_DEEP_RUIN_LATCH_COLOR
	_set_label_text("%s\n锁扣已覆写" % display_name_text, 2)


func set_activated_deep_signal_array_visual() -> void:
	consumed = true
	visible = true
	monitoring = false
	marker.color = ACTIVATED_DEEP_SIGNAL_ARRAY_COLOR
	_set_label_text("%s\n阵列已点亮" % display_name_text, 2)


func set_deployed_phase_return_anchor_visual(is_current: bool = true) -> void:
	consumed = false
	visible = true
	monitoring = true
	if is_current:
		marker.color = DEPLOYED_PHASE_RETURN_ANCHOR_COLOR
		_set_label_text("%s\n当前落点" % display_name_text, 2)
		return
	marker.color = STANDBY_PHASE_RETURN_ANCHOR_COLOR
	_set_label_text("%s\n已部署" % display_name_text, 2)


func set_ready_phase_relay_pad_visual(has_multiple_anchors: bool = false) -> void:
	consumed = false
	visible = true
	monitoring = true
	marker.color = READY_PHASE_RELAY_PAD_COLOR
	if has_multiple_anchors:
		_set_label_text("%s\n回投就绪 / R 切换" % display_name_text, 2)
		return
	_set_label_text("%s\n回投就绪" % display_name_text, 2)


func set_tuned_phase_fault_spire_visual() -> void:
	consumed = true
	visible = true
	monitoring = false
	marker.color = TUNED_PHASE_FAULT_SPIRE_COLOR
	_set_label_text("%s\n已校准" % display_name_text, 2)


func set_stabilized_phase_well_lock_visual() -> void:
	consumed = true
	visible = true
	monitoring = false
	marker.color = STABILIZED_PHASE_WELL_LOCK_COLOR
	_set_label_text("%s\n锁位已钉住" % display_name_text, 2)


func set_stabilized_inner_phase_well_visual() -> void:
	consumed = true
	visible = true
	monitoring = false
	marker.color = STABILIZED_INNER_PHASE_WELL_COLOR
	_set_label_text("%s\n井芯已读取" % display_name_text, 2)


func set_stabilized_phase_well_sink_visual() -> void:
	consumed = true
	visible = true
	monitoring = false
	marker.color = STABILIZED_PHASE_WELL_SINK_COLOR
	_set_label_text("%s\n井心核已取出" % display_name_text, 2)


func set_stabilized_phase_well_chamber_visual() -> void:
	consumed = true
	visible = true
	monitoring = false
	marker.color = STABILIZED_PHASE_WELL_CHAMBER_COLOR
	_set_label_text("%s\n纺核已取出" % display_name_text, 2)


func set_stabilized_phase_well_loom_visual() -> void:
	consumed = true
	visible = true
	monitoring = false
	marker.color = STABILIZED_PHASE_WELL_LOOM_COLOR
	_set_label_text("%s\n织核已取出" % display_name_text, 2)


func set_stabilized_phase_well_frame_visual() -> void:
	consumed = true
	visible = true
	monitoring = false
	marker.color = STABILIZED_PHASE_WELL_FRAME_COLOR
	_set_label_text("%s\n结核已取出" % display_name_text, 2)


func set_stabilized_phase_well_tether_visual() -> void:
	consumed = true
	visible = true
	monitoring = false
	marker.color = STABILIZED_PHASE_WELL_TETHER_COLOR
	_set_label_text("%s\n锚核已取出" % display_name_text, 2)


func set_deployed_phase_well_anchor_field_visual() -> void:
	consumed = false
	visible = true
	monitoring = true
	marker.color = DEPLOYED_PHASE_WELL_ANCHOR_FIELD_COLOR
	_set_label_text("%s\n回稳中" % display_name_text, 2)


func set_ready_phase_well_anchor_field_visual() -> void:
	consumed = false
	visible = true
	monitoring = true
	marker.color = READY_PHASE_WELL_ANCHOR_FIELD_COLOR
	_set_label_text("%s\n待收束" % display_name_text, 2)


func set_stabilized_phase_well_anchor_field_visual() -> void:
	consumed = false
	visible = true
	monitoring = true
	marker.color = STABILIZED_PHASE_WELL_ANCHOR_FIELD_COLOR
	_set_label_text("%s\n已稳定" % display_name_text, 2)


func set_ready_stability_calibration_visual() -> void:
	consumed = false
	visible = true
	monitoring = true
	marker.color = READY_STABILITY_CALIBRATION_COLOR
	_set_label_text("%s\n待校准" % display_name_text, 2)


func set_calibrated_stability_node_visual() -> void:
	consumed = true
	visible = true
	monitoring = false
	marker.color = CALIBRATED_STABILITY_NODE_COLOR
	_set_label_text("%s\n已校准" % display_name_text, 2)


func set_built_visual(built_definition_id: String) -> void:
	consumed = true
	visible = true
	monitoring = false
	if built_definition_id == "building.foundation_t1":
		marker.color = BUILT_FOUNDATION_COLOR
		_set_label_text("基础地基")
	elif built_definition_id == "building.pollution_filter":
		marker.color = BUILT_FILTER_COLOR
		_set_label_text("")
	else:
		marker.color = DEFAULT_MARKER_COLOR


func _set_label_text(text: String, min_lines: int = 1) -> void:
	label.text = text
	label.offset_bottom = label_offset.y + label_size.y * maxi(min_lines, 1)
