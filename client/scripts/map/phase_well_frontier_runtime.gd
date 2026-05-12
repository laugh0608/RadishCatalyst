extends RefCounted
class_name PhaseWellFrontierRuntime

const PHASE_WELL_TETHER_SPIKE_QUEST_ID := "quest.assemble_phase_well_tether_spike"
const PHASE_WELL_TETHER_QUEST_ID := "quest.inspect_phase_well_tether"
const PHASE_WELL_TETHER_SPIKE_ITEM_ID := "item.phase_well_tether_spike"

const ANALYZE_ANCHOR_CORE_QUEST_ID := "quest.analyze_phase_well_anchor_core"
const ASSEMBLE_ANCHOR_STAKE_QUEST_ID := "quest.assemble_phase_well_anchor_stake"
const STABILIZE_ANCHOR_FIELD_QUEST_ID := "quest.stabilize_phase_well_anchor_field"
const PHASE_WELL_ANCHOR_STAKE_ITEM_ID := "item.phase_well_anchor_stake"

const ANCHOR_FIELD_MAP_OBJECT_ID := "map_object.phase_well_anchor_field"
const ANCHOR_FIELD_INSTANCE_ID := "map_object_instance.phase_well_anchor_field"
const ANCHOR_FIELD_REGION_ID := "region.phase_well_tether"
const ANCHOR_FIELD_ENEMY_ID := "enemy.phase_well_warden"
const ANCHOR_FIELD_ENEMY_INSTANCE_ID := "enemy_instance.phase_well_warden"

const FLAG_ANCHOR_FIELD_DEPLOYED := "anchor_field_deployed"
const FLAG_ANCHOR_FIELD_PRESSURE_ACTIVE := "anchor_field_pressure_active"
const FLAG_ANCHOR_FIELD_PRESSURE_CLEARED := "anchor_field_pressure_cleared"
const FLAG_ANCHOR_FIELD_STABILIZED := "anchor_field_stabilized"
const ANCHOR_FIELD_HEALTH_RECOVERY_RATIO := 0.2
const ANCHOR_FIELD_PROTECTION_RECOVERY_RATIO := 0.35

var data_registry: DataRegistry


func _init(registry: DataRegistry) -> void:
	data_registry = registry


func inspect_tether(character_state: CharacterState, world_state: WorldState) -> Dictionary:
	if not world_state.quest_state.has_completed_quest(PHASE_WELL_TETHER_SPIKE_QUEST_ID):
		return _failure(
			"井系桥断面仍缺少可执行的系桥读数。",
			"井系桥未勘验",
			"先回基地用基础反应器，把相位井系谱片、井系固肋和基础零件组装成井系定桩。"
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
		return {
			"success": true,
			"advance_interaction": false,
			"message": "锚场回稳窗已稳定：井系桥东侧的局部稳定窗口仍在维持，相位井余响片已带回基地。"
		}

	if not world_state.quest_state.has_completed_quest(ASSEMBLE_ANCHOR_STAKE_QUEST_ID):
		return _failure(
			"锚场回稳窗仍缺少可执行的校锚桩。",
			"锚场未回稳",
			"先回基地解析相位井锚核、稳定锚核落尘，再把井系校锚桩带回来部署。"
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
	var recovery_message := _apply_anchor_field_recovery(character_state)
	return {
		"success": true,
		"advance_interaction": true,
		"message": "锚场回稳完成：井系桥东侧留下了可持续的局部稳定窗口，第一份相位井余响片已被收束带回基地。%s" % recovery_message
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


func _apply_anchor_field_recovery(character_state: CharacterState) -> String:
	var restored_health := character_state.restore_health(
		character_state.max_health * ANCHOR_FIELD_HEALTH_RECOVERY_RATIO
	)
	var restored_protection := character_state.restore_protection(
		character_state.max_protection * ANCHOR_FIELD_PROTECTION_RECOVERY_RATIO
	)
	if restored_health <= 0.0 and restored_protection <= 0.0:
		return " 稳定窗口已就绪：当前生命与防护已经完整。"
	return " 稳定窗口回充：生命 +%s，防护 +%s。" % [
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
