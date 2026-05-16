extends RefCounted
class_name PhaseWellFrontierRuntime

const PHASE_WELL_TETHER_SPIKE_QUEST_ID := "quest.assemble_phase_well_tether_spike"
const PHASE_WELL_TETHER_PACKAGE_QUEST_ID := "quest.refine_tether_fiber"
const PHASE_WELL_TETHER_QUEST_ID := "quest.inspect_phase_well_tether"
const PHASE_WELL_TETHER_SPIKE_ITEM_ID := "item.phase_well_tether_spike"

const ANALYZE_ANCHOR_CORE_QUEST_ID := "quest.analyze_phase_well_anchor_core"
const ASSEMBLE_ANCHOR_STAKE_QUEST_ID := "quest.assemble_phase_well_anchor_stake"
const ANCHOR_FIELD_PACKAGE_QUEST_ID := "quest.refine_anchor_core_dust"
const STABILIZE_ANCHOR_FIELD_QUEST_ID := "quest.stabilize_phase_well_anchor_field"
const ANALYZE_ECHO_SHARD_QUEST_ID := "quest.analyze_phase_well_echo_shard"
const CALIBRATE_STABILITY_WINDOW_QUEST_ID := "quest.calibrate_phase_well_stability_window"
const PHASE_WELL_ANCHOR_STAKE_ITEM_ID := "item.phase_well_anchor_stake"
const PHASE_WELL_STABILITY_READOUT_ITEM_ID := "item.phase_well_stability_readout"

const ANCHOR_FIELD_MAP_OBJECT_ID := "map_object.phase_well_anchor_field"
const ANCHOR_FIELD_INSTANCE_ID := "map_object_instance.phase_well_anchor_field"
const ANCHOR_FIELD_REGION_ID := "region.phase_well_tether"
const ANCHOR_FIELD_ENEMY_ID := "enemy.phase_well_warden"
const ANCHOR_FIELD_ENEMY_INSTANCE_ID := "enemy_instance.phase_well_warden"
const STABILITY_WINDOW_CALIBRATION_NODES := [
	{
		"definition_id": "map_object.phase_well_stability_node_west",
		"instance_id": "map_object_instance.phase_well_stability_node_west",
		"label": "西侧稳窗校准点"
	},
	{
		"definition_id": "map_object.phase_well_stability_node_core",
		"instance_id": "map_object_instance.phase_well_stability_node_core",
		"label": "中央稳窗校准点"
	},
	{
		"definition_id": "map_object.phase_well_stability_node_east",
		"instance_id": "map_object_instance.phase_well_stability_node_east",
		"label": "东侧稳窗校准点"
	}
]

const FLAG_ANCHOR_FIELD_DEPLOYED := "anchor_field_deployed"
const FLAG_ANCHOR_FIELD_PRESSURE_ACTIVE := "anchor_field_pressure_active"
const FLAG_ANCHOR_FIELD_PRESSURE_CLEARED := "anchor_field_pressure_cleared"
const FLAG_ANCHOR_FIELD_STABILIZED := "anchor_field_stabilized"
const FLAG_STABILITY_NODE_CALIBRATED := "stability_node_calibrated"
const ANCHOR_FIELD_HEALTH_RECOVERY_RATIO := 0.2
const ANCHOR_FIELD_PROTECTION_RECOVERY_RATIO := 0.35
const STABILITY_READOUT_HEALTH_RECOVERY_RATIO := 0.35
const STABILITY_READOUT_PROTECTION_RECOVERY_RATIO := 0.55

var data_registry: DataRegistry


func _init(registry: DataRegistry) -> void:
	data_registry = registry


func inspect_tether(character_state: CharacterState, world_state: WorldState) -> Dictionary:
	if (
		not world_state.quest_state.has_completed_quest(PHASE_WELL_TETHER_PACKAGE_QUEST_ID)
		and not world_state.quest_state.has_completed_quest(PHASE_WELL_TETHER_SPIKE_QUEST_ID)
	):
		return _failure(
			"井系桥断面仍缺少可执行的系桥读数。",
			"井系桥未勘验",
			"先回基地完成井系整备，把井系定桩带回来勘验断面。"
		)

	if world_state.quest_state.has_completed_quest(PHASE_WELL_TETHER_QUEST_ID):
		return {
			"success": true,
			"message": "井系桥断面已勘验：第一份相位井锚核已经带回基地；下一步回基地解析锚核，并把井系校锚桩带回前线做锚场回稳。"
		}

	if not character_state.inventory.has_ref(PHASE_WELL_TETHER_SPIKE_ITEM_ID, 1):
		return _failure(
			"缺少井系定桩，井系桥断面无法稳定。",
			"缺少井系定桩",
			"回基地确认基础反应器已经完成井系定桩，并带回来勘验井系桥断面。"
		)

	character_state.inventory.consume_ref(PHASE_WELL_TETHER_SPIKE_ITEM_ID, 1)
	return {
		"success": true,
		"message": "井系定桩已写入：井系桥断面开始析出相位井锚核，这条结核后的新收益线已经被真正钉住。"
	}


func inspect_anchor_field(character_state: CharacterState, world_state: WorldState) -> Dictionary:
	var object_state := _ensure_anchor_field_state(world_state)
	sync_anchor_field_progress(world_state)

	if world_state.quest_state.has_completed_quest(STABILIZE_ANCHOR_FIELD_QUEST_ID):
		if _has_stability_readout(character_state, world_state):
			var readout_recovery_message := _apply_anchor_field_recovery(
				character_state,
				STABILITY_READOUT_HEALTH_RECOVERY_RATIO,
				STABILITY_READOUT_PROTECTION_RECOVERY_RATIO,
				" 稳窗读数校准：当前生命与防护已经完整，井系桥东侧可作为前线回稳点。",
				" 稳窗读数校准：生命 +%s，防护 +%s；这处锚场现在可作为前线回稳点。"
			)
			return {
				"success": true,
				"advance_interaction": false,
				"message": "锚场回稳窗已按稳窗读数校准：局部稳定窗口会在前线回充生命与防护。%s" % readout_recovery_message
			}
		return {
			"success": true,
			"advance_interaction": false,
			"message": "锚场回稳窗已稳定：井系桥东侧的局部稳定窗口仍在维持；回基地解析相位井余响片后，可把这里校准成前线回稳点。"
		}

	if (
		not world_state.quest_state.has_completed_quest(ANCHOR_FIELD_PACKAGE_QUEST_ID)
		and not world_state.quest_state.has_completed_quest(ASSEMBLE_ANCHOR_STAKE_QUEST_ID)
	):
		return _failure(
			"锚场回稳窗仍缺少可执行的校锚桩。",
			"锚场未回稳",
			"先回基地完成锚场整备，把井系校锚桩带回来部署。"
		)

	if not is_anchor_field_deployed(world_state):
		if not character_state.inventory.has_ref(PHASE_WELL_ANCHOR_STAKE_ITEM_ID, 1):
			return _failure(
				"缺少井系校锚桩，锚场回稳窗无法启动。",
				"缺少井系校锚桩",
				"回基地确认基础反应器已经完成井系校锚桩，并带回来部署到井系桥东侧。"
			)

		character_state.inventory.consume_ref(PHASE_WELL_ANCHOR_STAKE_ITEM_ID, 1)
		_reset_anchor_field_enemy(world_state)
		object_state[FLAG_ANCHOR_FIELD_DEPLOYED] = true
		object_state[FLAG_ANCHOR_FIELD_PRESSURE_ACTIVE] = true
		object_state[FLAG_ANCHOR_FIELD_PRESSURE_CLEARED] = false
		object_state[FLAG_ANCHOR_FIELD_STABILIZED] = false
		return {
			"success": true,
			"advance_interaction": false,
			"message": "井系校锚桩已部署：锚场回稳开始重写井系桥东侧读数，井系守脉体已被逼出；先清掉压制再回来收束。校锚桩会保留在现场，失败后可直接重试，不必回基地重做。"
		}

	if not is_anchor_field_pressure_cleared(world_state):
		return {
			"success": true,
			"advance_interaction": false,
			"message": "锚场仍在回稳：井系守脉体还在压着回稳窗，先清掉它，再回来收束局部稳定窗口。已部署的校锚桩不会丢失，失败后直接回到这里继续压制即可。"
		}

	object_state[FLAG_ANCHOR_FIELD_DEPLOYED] = true
	object_state[FLAG_ANCHOR_FIELD_PRESSURE_ACTIVE] = false
	object_state[FLAG_ANCHOR_FIELD_PRESSURE_CLEARED] = true
	object_state[FLAG_ANCHOR_FIELD_STABILIZED] = true
	var recovery_message := _apply_anchor_field_recovery(
		character_state,
		ANCHOR_FIELD_HEALTH_RECOVERY_RATIO,
		ANCHOR_FIELD_PROTECTION_RECOVERY_RATIO,
		" 稳定窗口已就绪：当前生命与防护已经完整。",
		" 稳定窗口回充：生命 +%s，防护 +%s。"
	)
	return {
		"success": true,
		"advance_interaction": true,
		"message": "锚场回稳完成：井系桥东侧留下了可持续的局部稳定窗口，第一份相位井余响片已被收束带回基地。%s" % recovery_message
	}


func inspect_stability_calibration_node(
	instance_id: String,
	definition_id: String,
	character_state: CharacterState,
	world_state: WorldState
) -> Dictionary:
	if not world_state.quest_state.has_completed_quest(ANALYZE_ECHO_SHARD_QUEST_ID):
		return _failure(
			"稳窗读数尚未解析，现场校准点没有可写入的读数。",
			"缺少稳窗读数",
			"先回基地用基础反应器解析相位井余响片，再带着稳窗读数返回锚场。"
		)
	if (
		not character_state.inventory.has_ref(PHASE_WELL_STABILITY_READOUT_ITEM_ID, 1)
		and not world_state.quest_state.has_completed_quest(CALIBRATE_STABILITY_WINDOW_QUEST_ID)
	):
		return _failure(
			"背包里没有相位井稳窗读数，无法开始现场校准。",
			"缺少稳窗读数",
			"确认余响片解析产物已放入背包，再从相位回投台返回井系桥东侧。"
		)

	var node_index := _get_stability_node_index(definition_id)
	if node_index < 0:
		return _failure(
			"未知稳窗校准点：%s。" % definition_id,
			"校准点异常",
			"换一个已标记的稳窗校准点，或检查地图对象定义。"
		)

	var node_state := _ensure_stability_node_state(world_state, instance_id, definition_id)
	if bool(node_state.get(FLAG_STABILITY_NODE_CALIBRATED, false)):
		return {
			"success": true,
			"advance_interaction": false,
			"message": "%s 已完成校准；继续检查剩余稳窗校准点。" % _get_stability_node_label(node_index)
		}

	if not _are_previous_stability_nodes_calibrated(world_state, node_index):
		return _failure(
			"%s 的相位序还没有对齐。" % _get_stability_node_label(node_index),
			"校准顺序不匹配",
			"先按西侧、中央、东侧顺序写入稳窗读数，避免回稳窗再次抖动。"
		)

	node_state[FLAG_STABILITY_NODE_CALIBRATED] = true
	if node_index < STABILITY_WINDOW_CALIBRATION_NODES.size() - 1:
		return {
			"success": true,
			"advance_interaction": true,
			"message": "%s 已写入稳窗读数；继续按现场相位序校准下一处节点。" % _get_stability_node_label(node_index)
		}
	return {
		"success": true,
		"advance_interaction": true,
		"message": "三处稳窗校准点已按顺序写入：锚场回稳窗不再只是回充点，后续前线目标可以围绕现场读数顺序展开。"
	}


func sync_anchor_field_progress(world_state: WorldState) -> void:
	var object_state := _ensure_anchor_field_state(world_state)
	if world_state.quest_state.has_completed_quest(STABILIZE_ANCHOR_FIELD_QUEST_ID):
		object_state[FLAG_ANCHOR_FIELD_DEPLOYED] = true
		object_state[FLAG_ANCHOR_FIELD_PRESSURE_ACTIVE] = false
		object_state[FLAG_ANCHOR_FIELD_PRESSURE_CLEARED] = true
		object_state[FLAG_ANCHOR_FIELD_STABILIZED] = true
		return
	if not bool(object_state.get(FLAG_ANCHOR_FIELD_DEPLOYED, false)):
		object_state[FLAG_ANCHOR_FIELD_PRESSURE_ACTIVE] = false
		object_state[FLAG_ANCHOR_FIELD_PRESSURE_CLEARED] = false
		object_state[FLAG_ANCHOR_FIELD_STABILIZED] = false
		return

	var enemy_state := _ensure_anchor_field_enemy_state(world_state)
	var pressure_cleared := bool(enemy_state.get("is_defeated", false))
	object_state[FLAG_ANCHOR_FIELD_PRESSURE_CLEARED] = pressure_cleared
	object_state[FLAG_ANCHOR_FIELD_PRESSURE_ACTIVE] = not pressure_cleared


func should_spawn_anchor_field_enemy(world_state: WorldState) -> bool:
	sync_anchor_field_progress(world_state)
	return is_anchor_field_deployed(world_state) and not is_anchor_field_pressure_cleared(world_state) and not is_anchor_field_stabilized(world_state)


func is_anchor_field_deployed(world_state: WorldState) -> bool:
	var object_state := _ensure_anchor_field_state(world_state)
	return bool(object_state.get(FLAG_ANCHOR_FIELD_DEPLOYED, false))


func is_anchor_field_pressure_cleared(world_state: WorldState) -> bool:
	var object_state := _ensure_anchor_field_state(world_state)
	return bool(object_state.get(FLAG_ANCHOR_FIELD_PRESSURE_CLEARED, false))


func is_anchor_field_stabilized(world_state: WorldState) -> bool:
	var object_state := _ensure_anchor_field_state(world_state)
	return bool(object_state.get(FLAG_ANCHOR_FIELD_STABILIZED, false))


func is_stability_calibration_node(definition_id: String) -> bool:
	return _get_stability_node_index(definition_id) >= 0


func is_stability_node_calibrated(world_state: WorldState, instance_id: String, definition_id: String) -> bool:
	var object_state := _ensure_stability_node_state(world_state, instance_id, definition_id)
	return bool(object_state.get(FLAG_STABILITY_NODE_CALIBRATED, false))


func is_stability_calibration_ready(world_state: WorldState, definition_id: String) -> bool:
	var node_index := _get_stability_node_index(definition_id)
	if node_index < 0:
		return false
	if not world_state.quest_state.has_completed_quest(ANALYZE_ECHO_SHARD_QUEST_ID):
		return false
	return _are_previous_stability_nodes_calibrated(world_state, node_index)


func _has_stability_readout(character_state: CharacterState, world_state: WorldState) -> bool:
	return (
		world_state.quest_state.has_completed_quest(ANALYZE_ECHO_SHARD_QUEST_ID)
		or character_state.inventory.has_ref(PHASE_WELL_STABILITY_READOUT_ITEM_ID, 1)
	)


func _ensure_anchor_field_state(world_state: WorldState) -> Dictionary:
	var object_state := world_state.ensure_map_object(
		ANCHOR_FIELD_INSTANCE_ID,
		ANCHOR_FIELD_MAP_OBJECT_ID,
		ANCHOR_FIELD_REGION_ID
	)
	if not object_state.has(FLAG_ANCHOR_FIELD_DEPLOYED):
		object_state[FLAG_ANCHOR_FIELD_DEPLOYED] = false
	if not object_state.has(FLAG_ANCHOR_FIELD_PRESSURE_ACTIVE):
		object_state[FLAG_ANCHOR_FIELD_PRESSURE_ACTIVE] = false
	if not object_state.has(FLAG_ANCHOR_FIELD_PRESSURE_CLEARED):
		object_state[FLAG_ANCHOR_FIELD_PRESSURE_CLEARED] = false
	if not object_state.has(FLAG_ANCHOR_FIELD_STABILIZED):
		object_state[FLAG_ANCHOR_FIELD_STABILIZED] = false
	return object_state


func _ensure_stability_node_state(world_state: WorldState, instance_id: String, definition_id: String) -> Dictionary:
	var object_state := world_state.ensure_map_object(
		instance_id,
		definition_id,
		ANCHOR_FIELD_REGION_ID
	)
	if not object_state.has(FLAG_STABILITY_NODE_CALIBRATED):
		object_state[FLAG_STABILITY_NODE_CALIBRATED] = false
	return object_state


func _are_previous_stability_nodes_calibrated(world_state: WorldState, node_index: int) -> bool:
	for index in range(node_index):
		var node: Dictionary = STABILITY_WINDOW_CALIBRATION_NODES[index]
		var node_state := _ensure_stability_node_state(
			world_state,
			String(node.get("instance_id", "")),
			String(node.get("definition_id", ""))
		)
		if not bool(node_state.get(FLAG_STABILITY_NODE_CALIBRATED, false)):
			return false
	return true


func _get_stability_node_index(definition_id: String) -> int:
	for index in range(STABILITY_WINDOW_CALIBRATION_NODES.size()):
		var node: Dictionary = STABILITY_WINDOW_CALIBRATION_NODES[index]
		if String(node.get("definition_id", "")) == definition_id:
			return index
	return -1


func _get_stability_node_label(node_index: int) -> String:
	if node_index < 0 or node_index >= STABILITY_WINDOW_CALIBRATION_NODES.size():
		return "稳窗校准点"
	var node: Dictionary = STABILITY_WINDOW_CALIBRATION_NODES[node_index]
	return String(node.get("label", "稳窗校准点"))


func _ensure_anchor_field_enemy_state(world_state: WorldState) -> Dictionary:
	var definition := data_registry.get_definition(ANCHOR_FIELD_ENEMY_ID)
	var max_health := float(definition.get("base_stats", {}).get("max_health", 20.0))
	return world_state.ensure_enemy(
		ANCHOR_FIELD_ENEMY_INSTANCE_ID,
		ANCHOR_FIELD_ENEMY_ID,
		ANCHOR_FIELD_REGION_ID,
		max_health
	)


func _reset_anchor_field_enemy(world_state: WorldState) -> void:
	var enemy_state := _ensure_anchor_field_enemy_state(world_state)
	var max_health := float(enemy_state.get("max_health", 20.0))
	enemy_state["health"] = max_health
	enemy_state["is_defeated"] = false
	enemy_state["drops_granted"] = false


func _apply_anchor_field_recovery(
	character_state: CharacterState,
	health_recovery_ratio: float,
	protection_recovery_ratio: float,
	full_vitals_message: String,
	recovery_message_template: String
) -> String:
	var restored_health := character_state.restore_health(
		character_state.max_health * health_recovery_ratio
	)
	var restored_protection := character_state.restore_protection(
		character_state.max_protection * protection_recovery_ratio
	)
	if restored_health <= 0.0 and restored_protection <= 0.0:
		return full_vitals_message
	return recovery_message_template % [
		_format_amount(restored_health),
		_format_amount(restored_protection)
	]


func _failure(message: String, title: String, detail: String) -> Dictionary:
	return {
		"success": false,
		"message": message,
		"title": title,
		"detail": detail
	}


func _format_amount(amount: float) -> String:
	if is_equal_approx(amount, roundf(amount)):
		return str(int(amount))
	return "%.1f" % amount
