extends RefCounted
class_name CharacterKitRuntime

const BASIC_TOOL_ID := "equipment.basic_tool"
const TACTICAL_SCAN_MARKED_FLAG := "tactical_scan_marked"
const TACTICAL_SCAN_CONSUMED_FLAG := "tactical_scan_consumed"
const TACTICAL_SCAN_BASE_PRESSURE_MULT := 0.9
const TACTICAL_SCAN_MODULE_PRESSURE_MULT := 0.85
const TACTICAL_SCAN_CALIBRATED_PRESSURE_MULT := 0.8

var data_registry: DataRegistry


func _init(registry: DataRegistry) -> void:
	data_registry = registry


func scan_enemy(
	enemy: PrototypeEnemy,
	character_state: CharacterState,
	world_state: WorldState,
	enemy_region_id: String
) -> Dictionary:
	var blocker := _get_tactical_scan_blocker(character_state, world_state)
	if not blocker.is_empty():
		return blocker
	if enemy == null or not enemy.can_be_attacked():
		return _failure("战术扫描未命中：附近没有可锁定敌人。", "扫描未命中", "靠近敌人后再按 C。")
	var enemy_state := world_state.ensure_enemy(enemy.instance_id, enemy.definition_id, enemy_region_id, enemy.max_health)
	if bool(enemy_state.get(TACTICAL_SCAN_MARKED_FLAG, false)):
		return _success("战术扫描保持锁定：%s 的下一次反击仍会被压低。" % enemy.display_name, "enemy")
	enemy_state[TACTICAL_SCAN_MARKED_FLAG] = true
	enemy_state[TACTICAL_SCAN_CONSUMED_FLAG] = false
	enemy.set_tactical_scan_marked(true)
	return _success("战术扫描完成：%s 已锁定，下一次反击承压降低。%s" % [enemy.display_name, _format_scan_payoff(character_state, world_state)], "enemy")


func scan_interactable(
	interactable: PrototypeInteractable,
	character_state: CharacterState,
	world_state: WorldState
) -> Dictionary:
	var blocker := _get_tactical_scan_blocker(character_state, world_state)
	if not blocker.is_empty():
		return blocker
	if interactable == null or not interactable.can_interact():
		return _failure("战术扫描未命中：附近没有可扫描外勤目标。", "扫描未命中", "靠近污染采集点或敌人后再按 C。")
	if interactable.interaction_type != "gather":
		return _failure("战术扫描未执行：当前目标没有可降低的采集压力。", "扫描目标不匹配", "对污染采集点或近身敌人使用战术扫描。")
	var definition := data_registry.get_definition(interactable.definition_id)
	if String(definition.get("pollution_effect", "")).is_empty():
		return _failure("战术扫描未执行：当前采集点没有污染压力。", "扫描目标不匹配", "把扫描留给污染沉积、污染回波或敌人。")
	var object_state := world_state.ensure_map_object(
		interactable.instance_id,
		interactable.definition_id,
		character_state.current_region_id
	)
	if bool(object_state.get("is_gathered", false)):
		return _failure("战术扫描未执行：该采集点已经处理。", "目标已处理", "换一个未处理的污染采集点。")
	if bool(object_state.get(TACTICAL_SCAN_MARKED_FLAG, false)):
		return _success("战术扫描保持锁定：%s 的下一次采集压力仍会被压低。" % _get_display_name(interactable.definition_id), "map_object")
	object_state[TACTICAL_SCAN_MARKED_FLAG] = true
	object_state[TACTICAL_SCAN_CONSUMED_FLAG] = false
	return _success("战术扫描完成：%s 已标记，下一次采集污染压力降低。%s" % [_get_display_name(interactable.definition_id), _format_scan_payoff(character_state, world_state)], "map_object")


func no_target_result(character_state: CharacterState, world_state: WorldState) -> Dictionary:
	var blocker := _get_tactical_scan_blocker(character_state, world_state)
	if not blocker.is_empty():
		return blocker
	return _failure("战术扫描未命中：附近没有敌人或可扫描污染采集点。", "扫描未命中", "靠近敌人或污染采集点后再按 C。")


static func consume_enemy_tactical_scan(
	enemy: PrototypeEnemy,
	world_state: WorldState,
	enemy_region_id: String
) -> bool:
	if enemy == null:
		return false
	var marked := enemy.has_meta(TACTICAL_SCAN_MARKED_FLAG) and bool(enemy.get_meta(TACTICAL_SCAN_MARKED_FLAG))
	if world_state != null and not enemy.instance_id.is_empty():
		var enemy_state := world_state.ensure_enemy(enemy.instance_id, enemy.definition_id, enemy_region_id, enemy.max_health)
		marked = bool(enemy_state.get(TACTICAL_SCAN_MARKED_FLAG, marked))
		if marked:
			enemy_state[TACTICAL_SCAN_MARKED_FLAG] = false
			enemy_state[TACTICAL_SCAN_CONSUMED_FLAG] = true
	if marked:
		enemy.set_tactical_scan_marked(false)
	return marked


static func consume_map_object_tactical_scan(
	world_state: WorldState,
	instance_id: String,
	definition_id: String,
	region_id: String
) -> bool:
	if world_state == null or instance_id.is_empty():
		return false
	var object_state := world_state.ensure_map_object(instance_id, definition_id, region_id)
	if not bool(object_state.get(TACTICAL_SCAN_MARKED_FLAG, false)):
		return false
	object_state[TACTICAL_SCAN_MARKED_FLAG] = false
	object_state[TACTICAL_SCAN_CONSUMED_FLAG] = true
	return true


static func get_tactical_scan_pressure_multiplier(
	character_state: CharacterState,
	world_state: WorldState
) -> float:
	if FieldOutfittingRuntime.has_active_module_calibration(character_state, world_state):
		return TACTICAL_SCAN_CALIBRATED_PRESSURE_MULT
	if FieldOutfittingRuntime.has_filter_module_equipped(character_state):
		return TACTICAL_SCAN_MODULE_PRESSURE_MULT
	return TACTICAL_SCAN_BASE_PRESSURE_MULT


static func format_enemy_counter_feedback(
	character_state: CharacterState,
	world_state: WorldState
) -> String:
	if FieldOutfittingRuntime.has_active_module_calibration(character_state, world_state):
		return "战术扫描已消耗：校准模块把本次反击压力压低。"
	return "战术扫描已消耗：本次反击压力降低。"


static func format_gather_pressure_feedback(
	character_state: CharacterState,
	world_state: WorldState
) -> String:
	if FieldOutfittingRuntime.has_active_module_calibration(character_state, world_state):
		return "战术扫描已消耗：校准模块把本次采集污染压力压低"
	return "战术扫描已消耗：本次采集污染压力降低"


static func format_hud_tool_action_status(character_state: CharacterState, world_state: WorldState) -> String:
	if String(character_state.equipment.get("tool", "")) != BASIC_TOOL_ID:
		return "工具动作：未装备基础多用工具"
	if not FieldOutfittingRuntime.has_station_built(world_state):
		return "工具动作：战术扫描待整备台上线"
	if FieldOutfittingRuntime.has_active_module_calibration(character_state, world_state):
		return "工具动作：C 战术扫描可用（校准收益）"
	if FieldOutfittingRuntime.has_filter_module_equipped(character_state):
		return "工具动作：C 战术扫描可用（过滤模块接入）"
	return "工具动作：C 战术扫描可用"


func _get_tactical_scan_blocker(character_state: CharacterState, world_state: WorldState) -> Dictionary:
	if String(character_state.equipment.get("tool", "")) != BASIC_TOOL_ID:
		return _failure("战术扫描不可用：当前未装备基础多用工具。", "工具动作不可用", "恢复或装备基础多用工具后再尝试。")
	if not FieldOutfittingRuntime.has_station_built(world_state):
		return _failure("战术扫描不可用：出发整备台尚未上线。", "工具动作未接入", "先建成出发整备台，让基础多用工具接入外勤扫描供能。")
	return {}


func _format_scan_payoff(character_state: CharacterState, world_state: WorldState) -> String:
	if FieldOutfittingRuntime.has_active_module_calibration(character_state, world_state):
		return "整备台校准已接入，扫描收益提高。"
	if FieldOutfittingRuntime.has_filter_module_equipped(character_state):
		return "过滤模块已接入，扫描会压低外勤承压。"
	return "整备台供能已接入，扫描会压低下一次压力。"


func _success(message: String, target_type: String) -> Dictionary:
	return {
		"success": true,
		"message": message,
		"tool_action": "tactical_scan",
		"tactical_scan_target_type": target_type
	}


func _failure(message: String, title: String, detail: String) -> Dictionary:
	return {
		"success": false,
		"message": message,
		"failure_title": title,
		"failure_detail": detail,
		"tool_action": "tactical_scan"
	}


func _get_display_name(definition_id: String) -> String:
	if data_registry == null:
		return definition_id
	var definition := data_registry.get_definition(definition_id)
	if definition.is_empty():
		return definition_id
	return data_registry.get_text(String(definition.get("display_name_key", definition_id)))
