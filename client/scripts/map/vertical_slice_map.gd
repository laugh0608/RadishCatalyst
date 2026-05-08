extends Node2D
class_name VerticalSliceMap

signal interaction_available(interactable: PrototypeInteractable)
signal interaction_cleared(interactable: PrototypeInteractable)
signal region_changed(region_id: String)
signal region_gate_blocked(message: String)

const ATTACK_RANGE := 90.0
const BASE_ATTACK_DAMAGE := 10.0
const PLAYER_INTERACTION_RANGE := 96.0
const POLLUTION_COUNTER_PRESSURE_MULT := 0.5
const OUTPOST_RESPAWN_POSITION := Vector2(-250, -48)
const PLAY_BOUNDS_MIN := Vector2(-360, -200)
const PLAY_BOUNDS_MAX := Vector2(820, 200)
const CRYSTAL_REGION_X := -70.0
const CRYSTAL_GATE_RETURN_X := -85.0
const POLLUTION_REGION_X := 200.0
const POLLUTION_GATE_X := 220.0
const POLLUTION_DEEP_Y := -40.0
const POLLUTION_GATE_RETURN_X := 195.0
const RUIN_OUTER_RING_X := 390.0
const RUIN_GATE_RETURN_X := 355.0
const OUTER_RING_BARRIER_X := 540.0
const OUTER_RING_BARRIER_RETURN_X := 514.0
const DEEP_RUIN_REGION_X := 700.0
const DEEP_RUIN_GATE_RETURN_X := 676.0

@onready var player: PlayerController = $Player
@onready var interactables_root: Node2D = $Interactables
@onready var enemies_root: Node2D = $Enemies

var data_registry: DataRegistry
var current_interactable: PrototypeInteractable
var gather_system: GatherSystem
var last_reported_region_id := "region.outpost_platform"
var last_gate_message := ""


func setup(registry: DataRegistry) -> void:
	data_registry = registry
	gather_system = GatherSystem.new(data_registry)
	_setup_interactable_labels()
	_setup_enemy_labels()


func _ready() -> void:
	for interactable in interactables_root.get_children():
		if interactable is PrototypeInteractable:
			interactable.body_entered.connect(_on_interactable_body_entered.bind(interactable))
			interactable.body_exited.connect(_on_interactable_body_exited.bind(interactable))


func try_interact(character_state: CharacterState, world_state: WorldState) -> Dictionary:
	if current_interactable == null:
		return _failure("附近没有可交互目标。", "交互未执行", "靠近带名称的目标，等待交互提示出现后再按 E。")

	var interacted := current_interactable
	if interacted.definition_id == "map_object.ruin_gate" and interacted.interaction_type == "inspect":
		return _inspect_ruin_gate(world_state)
	if interacted.definition_id == "map_object.outer_ring_barrier" and interacted.interaction_type == "inspect":
		return _inspect_outer_ring_barrier(character_state, world_state)
	if interacted.definition_id == "map_object.outer_ring_console" and interacted.interaction_type == "inspect":
		return _inspect_outer_ring_console(world_state)
	if interacted.definition_id == "map_object.signal_echo_cache" and interacted.interaction_type == "inspect":
		return _inspect_signal_echo_cache(world_state)
	if interacted.definition_id == "map_object.deep_ruin_door" and interacted.interaction_type == "inspect":
		return _inspect_deep_ruin_door(character_state, world_state)
	if interacted.definition_id == "map_object.deep_ruin_latch" and interacted.interaction_type == "inspect":
		return _inspect_deep_ruin_latch(character_state, world_state)

	var action_id := interacted.get_current_recipe_id()
	if interacted.interaction_type == "build":
		action_id = interacted.prerequisite_instance_id
	var result := gather_system.interact_with_object(
		interacted.instance_id,
		interacted.definition_id,
		interacted.interaction_type,
		character_state,
		world_state,
		action_id
	)
	if bool(result.get("success", false)):
		interacted.mark_consumed()
	if not interacted.can_interact():
		current_interactable = null
		interaction_cleared.emit(interacted)
	var evacuation_feedback := _evacuate_if_needed(character_state, world_state, "pollution")
	if not evacuation_feedback.is_empty():
		result["message"] = "%s%s" % [String(result.get("message", "")), String(evacuation_feedback.get("log_message", ""))]
		result["evacuation_feedback"] = evacuation_feedback
	return result


func refresh_world_interactables(world_state: WorldState) -> void:
	for interactable in interactables_root.get_children():
		if not interactable is PrototypeInteractable:
			continue

		var object_state := world_state.get_map_object(interactable.instance_id)
		var is_processed := false
		if interactable.interaction_type == "gather":
			is_processed = bool(object_state.get("is_gathered", false))
		if interactable.interaction_type == "sample":
			is_processed = bool(object_state.get("is_sampled", false))
		if interactable.interaction_type == "clear":
			is_processed = bool(object_state.get("is_cleared", false))
		if interactable.interaction_type == "build":
			is_processed = bool(object_state.get("is_built", false))
			if is_processed:
				interactable.set_built_visual(String(object_state.get("built_definition_id", interactable.definition_id)))
				if current_interactable == interactable:
					current_interactable = null
					interaction_cleared.emit(interactable)
				continue

		if interactable.single_use:
			interactable.consumed = is_processed
		if interactable.interaction_type == "outpost_core":
			if world_state.quest_state.has_completed_quest("quest.restore_outpost"):
				interactable.set_restored_outpost_core_visual()
				continue
			interactable.set_default_visual()
		elif interactable.definition_id == "map_object.ruin_gate":
			if world_state.quest_state.has_completed_quest("quest.unlock_ruin_signal"):
				interactable.set_confirmed_ruin_signal_visual()
				if current_interactable == interactable:
					current_interactable = null
					interaction_cleared.emit(interactable)
				continue
			interactable.set_default_visual()
		elif interactable.definition_id == "map_object.outer_ring_barrier":
			if world_state.quest_state.has_completed_quest("quest.stabilize_outer_ring_barrier"):
				interactable.set_stabilized_barrier_visual()
				if current_interactable == interactable:
					current_interactable = null
					interaction_cleared.emit(interactable)
				continue
			interactable.set_default_visual()
		elif interactable.definition_id == "map_object.outer_ring_console":
			if world_state.quest_state.has_completed_quest("quest.secure_outer_ring_signal"):
				interactable.set_secured_console_visual()
				if current_interactable == interactable:
					current_interactable = null
					interaction_cleared.emit(interactable)
				continue
			interactable.set_default_visual()
		elif interactable.definition_id == "map_object.signal_echo_cache":
			if world_state.quest_state.has_completed_quest("quest.salvage_signal_echo"):
				interactable.set_recovered_signal_echo_visual()
				if current_interactable == interactable:
					current_interactable = null
					interaction_cleared.emit(interactable)
				continue
			interactable.set_default_visual()
		elif interactable.definition_id == "map_object.deep_ruin_door":
			if world_state.quest_state.has_completed_quest("quest.unlock_deep_ruin_entrance"):
				interactable.set_opened_deep_ruin_door_visual()
				if current_interactable == interactable:
					current_interactable = null
					interaction_cleared.emit(interactable)
				continue
			interactable.set_default_visual()
		elif interactable.definition_id == "map_object.deep_ruin_latch":
			if world_state.quest_state.has_completed_quest("quest.unlock_deep_ruin_cache"):
				interactable.set_overridden_deep_ruin_latch_visual()
				if current_interactable == interactable:
					current_interactable = null
					interaction_cleared.emit(interactable)
				continue
			interactable.set_default_visual()
		elif is_processed and interactable.set_processed_visual():
			if current_interactable == interactable:
				current_interactable = null
				interaction_cleared.emit(interactable)
			continue
		elif not is_processed:
			interactable.set_default_visual()

		var should_enable: bool = not interactable.consumed
		if interactable.interaction_type == "process_recipe" and interactable.definition_id == "building.pollution_filter":
			should_enable = should_enable and world_state.has_base_structure_definition("building.pollution_filter")

		interactable.set_interaction_enabled(should_enable)
		if current_interactable == interactable and not should_enable:
			current_interactable = null
			interaction_cleared.emit(interactable)
	update_current_interactable()


func update_current_interactable() -> void:
	var nearest_interactable := _get_nearest_interactable()
	if nearest_interactable == current_interactable:
		return

	var previous_interactable := current_interactable
	current_interactable = nearest_interactable
	if previous_interactable != null:
		interaction_cleared.emit(previous_interactable)
	if current_interactable != null:
		interaction_available.emit(current_interactable)


func try_cycle_recipe() -> Dictionary:
	if current_interactable == null:
		return _failure("附近没有可切换配方的设备。", "配方未切换", "靠近基础反应器等加工设备后再按 R。")
	if current_interactable.interaction_type != "process_recipe":
		return _failure("当前目标不是加工设备。", "配方未切换", "靠近基础反应器或污染过滤器后再切换配方。")
	if current_interactable.get_recipe_count() <= 1:
		return _failure("当前设备没有可轮换配方。", "配方未切换", "该设备只有一个配方，直接按 E 尝试加工。")

	var recipe_id := current_interactable.select_next_recipe()
	return {
		"success": true,
		"message": "当前配方：%s（%d/%d）。" % [
			_get_display_name(recipe_id),
			current_interactable.get_recipe_position(),
			current_interactable.get_recipe_count()
		]
	}


func try_attack(character_state: CharacterState, world_state: WorldState) -> Dictionary:
	var target := _get_nearest_attack_target()
	if target == null:
		return _failure("攻击挥空：附近没有敌人。", "攻击未命中", "靠近敌人后再攻击，或回到当前目标区域。")

	var damage := _get_attack_damage(character_state)
	var result := target.apply_hit(damage)
	world_state.update_enemy_health(
		target.instance_id,
		float(result.get("health", 0.0)),
		bool(result.get("defeated", false))
	)

	if bool(result.get("defeated", false)):
		var drops_message := _grant_enemy_drops(target, character_state, world_state)
		if target.definition_id == "enemy.polluted_skitter":
			return {
				"success": true,
				"message": "击败：%s。%s污染处理点周边暂时安全。" % [
					target.display_name,
					drops_message
				],
				"enemy_definition_id": target.definition_id,
				"enemy_defeated": true
			}
		if target.definition_id == "enemy.ruin_phase_guard":
			return {
				"success": true,
				"message": "击败：%s。%s外圈回波匣附近的干扰守卫已清空。" % [
					target.display_name,
					drops_message
				],
				"enemy_definition_id": target.definition_id,
				"enemy_defeated": true
			}
		if target.definition_id == "enemy.deep_ruin_sentinel":
			return {
				"success": true,
				"message": "击败：%s。%s深段锁扣前的压制守卫已清空，相位纤丝回收线已打开。" % [
					target.display_name,
					drops_message
				],
				"enemy_definition_id": target.definition_id,
				"enemy_defeated": true
			}
		return {
			"success": true,
			"message": "击败：%s。%s" % [target.display_name, drops_message],
			"enemy_definition_id": target.definition_id,
			"enemy_defeated": true
		}

	var counter_message := _apply_enemy_counterattack(target, character_state)
	var evacuation_feedback := _evacuate_if_needed(character_state, world_state, "combat")
	return {
		"success": true,
		"message": "命中：%s，造成 %.0f 伤害，剩余 HP %.0f。%s%s" % [
			target.display_name,
			damage,
			float(result.get("health", 0.0)),
			counter_message,
			String(evacuation_feedback.get("log_message", ""))
		],
		"enemy_definition_id": target.definition_id,
		"enemy_defeated": false,
		"evacuation_feedback": evacuation_feedback
	}


func _setup_interactable_labels() -> void:
	if data_registry == null:
		return

	for interactable in interactables_root.get_children():
		if not interactable is PrototypeInteractable:
			continue
		if interactable.interaction_type == "process_recipe":
			interactable.set_recipe_cycle(_get_recipes_for_building(interactable.definition_id))
		interactable.instance_id = "map_object_instance.%s" % String(interactable.name).to_snake_case()
		interactable.setup(_get_display_name(interactable.definition_id))


func _setup_enemy_labels() -> void:
	if data_registry == null:
		return

	for enemy in enemies_root.get_children():
		if not enemy is PrototypeEnemy:
			continue

		var definition := data_registry.get_definition(enemy.definition_id)
		var max_health := float(definition.get("base_stats", {}).get("max_health", 20.0))
		enemy.instance_id = _get_enemy_instance_id(enemy)
		enemy.setup(_get_display_name(enemy.definition_id), max_health, String(definition.get("category", "basic")))


func sync_enemy_states(world_state: WorldState) -> void:
	for enemy in enemies_root.get_children():
		if not enemy is PrototypeEnemy:
			continue

		var definition := data_registry.get_definition(enemy.definition_id)
		var max_health := float(definition.get("base_stats", {}).get("max_health", 20.0))
		enemy.instance_id = _get_enemy_instance_id(enemy)
		var enemy_state := world_state.ensure_enemy(
			enemy.instance_id,
			enemy.definition_id,
			_get_region_id_for_position(enemy.position),
			max_health
		)
		enemy.apply_saved_state(enemy_state)
		enemy.set_spawn_enabled(_should_enemy_spawn(enemy, world_state))


func refresh_enemy_spawns(world_state: WorldState) -> void:
	for enemy in enemies_root.get_children():
		if not enemy is PrototypeEnemy:
			continue
		enemy.set_spawn_enabled(_should_enemy_spawn(enemy, world_state))


func apply_runtime_state(world_state: WorldState, character_state: CharacterState) -> void:
	current_interactable = null
	player.position = character_state.position
	player.clear_positive_x_block()
	last_reported_region_id = world_state.current_region_id
	last_gate_message = ""
	sync_enemy_states(world_state)
	refresh_world_interactables(world_state)


func get_player_position() -> Vector2:
	return player.position


func update_region_presence(world_state: WorldState, character_state: CharacterState) -> void:
	player.clamp_to_play_bounds(PLAY_BOUNDS_MIN, PLAY_BOUNDS_MAX)
	var gate_message := apply_region_gate_bounds(world_state)
	if not gate_message.is_empty():
		var clamped_region_id := _get_region_id_for_position(player.position)
		last_reported_region_id = clamped_region_id
		world_state.current_region_id = clamped_region_id
		character_state.current_region_id = clamped_region_id
		if gate_message != last_gate_message:
			last_gate_message = gate_message
			region_gate_blocked.emit(gate_message)
		return

	player.clear_positive_x_block()
	var region_id := _get_region_id_for_position(player.position)
	last_gate_message = ""
	if region_id == last_reported_region_id:
		return

	last_reported_region_id = region_id
	world_state.current_region_id = region_id
	character_state.current_region_id = region_id
	region_changed.emit(region_id)


func apply_region_gate_bounds(world_state: WorldState) -> String:
	if not world_state.unlocked_region_ids.has("region.crystal_vein_field") and player.position.x > CRYSTAL_GATE_RETURN_X:
		player.position.x = CRYSTAL_GATE_RETURN_X
		player.stop_positive_x_until_release()
		return "晶体矿脉区尚未标记：先检查前哨核心，恢复基础导航。"

	if (
		not world_state.unlocked_region_ids.has("region.pollution_edge")
		and player.position.x > POLLUTION_GATE_RETURN_X
		and player.position.y >= POLLUTION_DEEP_Y
	):
		player.position.x = POLLUTION_GATE_RETURN_X
		player.stop_positive_x_until_release()
		return "污染边界尚未稳定：先扩建处理点并启用基础过滤模块。"

	if not world_state.unlocked_region_ids.has("region.ruin_outer_ring") and player.position.x > RUIN_GATE_RETURN_X:
		player.position.x = RUIN_GATE_RETURN_X
		player.stop_positive_x_until_release()
		return "遗迹外圈仍被封锁：先检查封锁遗迹入口，确认外圈通路。"

	if _is_outer_ring_barrier_locked(world_state) and player.position.x > OUTER_RING_BARRIER_X:
		player.position.x = OUTER_RING_BARRIER_RETURN_X
		player.stop_positive_x_until_release()
		return "遗迹外圈深段仍被抖动雾幕阻断：先回基地组装稳相信标，再返回部署。"

	if _is_deep_ruin_gate_locked(world_state) and player.position.x > DEEP_RUIN_GATE_RETURN_X:
		player.position.x = DEEP_RUIN_GATE_RETURN_X
		player.stop_positive_x_until_release()
		return "深段入口仍未校准：先带着更深遗迹坐标回到门禁写入。"

	return ""


func _get_display_name(definition_id: String) -> String:
	var definition := data_registry.get_definition(definition_id)
	if definition.is_empty():
		return definition_id
	return data_registry.get_text(String(definition.get("display_name_key", definition_id)))


func _get_recipes_for_building(building_id: String) -> Array[String]:
	var recipe_ids: Array[String] = []
	if data_registry == null:
		return recipe_ids

	for recipe in data_registry.get_table("recipes"):
		if not recipe is Dictionary:
			continue
		if String(recipe.get("required_building_id", "")) != building_id:
			continue
		recipe_ids.append(String(recipe.get("id", "")))

	return recipe_ids


func _on_interactable_body_entered(body: Node2D, interactable: PrototypeInteractable) -> void:
	if body != player or not interactable.can_interact():
		return
	update_current_interactable()


func _on_interactable_body_exited(body: Node2D, interactable: PrototypeInteractable) -> void:
	if body != player or current_interactable != interactable:
		return
	update_current_interactable()


func _get_nearest_interactable() -> PrototypeInteractable:
	var nearest_interactable: PrototypeInteractable = null
	var nearest_distance := INF

	for interactable in interactables_root.get_children():
		if not interactable is PrototypeInteractable or not interactable.can_interact():
			continue

		var distance := player.position.distance_to(interactable.position)
		if distance > PLAYER_INTERACTION_RANGE or distance >= nearest_distance:
			continue

		nearest_interactable = interactable
		nearest_distance = distance

	return nearest_interactable


func _get_nearest_attack_target() -> PrototypeEnemy:
	var nearest_enemy: PrototypeEnemy = null
	var nearest_distance := INF

	for enemy in enemies_root.get_children():
		if not enemy is PrototypeEnemy or not enemy.can_be_attacked():
			continue

		var distance := player.position.distance_to(enemy.position)
		if distance > ATTACK_RANGE or distance >= nearest_distance:
			continue

		nearest_enemy = enemy
		nearest_distance = distance

	return nearest_enemy


func _should_enemy_spawn(enemy: PrototypeEnemy, world_state: WorldState) -> bool:
	if enemy.definition_id == "enemy.elite_residue_node":
		return (
			world_state.quest_state.has_active_quest("quest.defeat_elite_node")
			or world_state.quest_state.has_completed_quest("quest.defeat_elite_node")
		)
	if enemy.definition_id == "enemy.ruin_phase_guard":
		return (
			world_state.quest_state.has_active_quest("quest.salvage_signal_echo")
			or world_state.quest_state.has_completed_quest("quest.salvage_signal_echo")
		)
	if enemy.definition_id == "enemy.deep_ruin_sentinel":
		return (
			world_state.quest_state.has_active_quest("quest.harvest_phase_filament")
			or world_state.quest_state.has_completed_quest("quest.harvest_phase_filament")
		)
	if enemy.definition_id != "enemy.treatment_skitter":
		return true
	var quest_state := world_state.quest_state
	var quest_id := "quest.prepare_treatment_supplies"
	if quest_state.has_completed_quest(quest_id):
		return true
	if not quest_state.has_active_quest(quest_id):
		return false
	return quest_state.get_objective_progress(quest_id, "craft_item", "item.repair_gel") >= 1.0


func _get_attack_damage(character_state: CharacterState) -> float:
	var tool_id := String(character_state.equipment.get("tool", ""))
	var tool_definition := data_registry.get_definition(tool_id)
	var stat_modifiers: Dictionary = tool_definition.get("stat_modifiers", {})
	var attack_power := float(stat_modifiers.get("attack_power", 1.0))
	return BASE_ATTACK_DAMAGE * attack_power


func _apply_enemy_counterattack(enemy: PrototypeEnemy, character_state: CharacterState) -> String:
	var definition := data_registry.get_definition(enemy.definition_id)
	var base_stats: Dictionary = definition.get("base_stats", {})
	var attack_damage := float(base_stats.get("attack", 0.0))
	var health_damage := character_state.apply_health_damage(attack_damage)
	var protection_damage := 0.0
	var damage_types: Array = definition.get("damage_types", [])

	if damage_types.has("pollution"):
		protection_damage = character_state.apply_protection_damage(
			attack_damage * POLLUTION_COUNTER_PRESSURE_MULT * character_state.get_pollution_drain_multiplier(data_registry)
		)

	if protection_damage > 0.0:
		return "%s 反击，生命 -%s，防护 -%s。" % [
			enemy.display_name,
			_format_amount(health_damage),
			_format_amount(protection_damage)
		]
	var message := "%s 反击，生命 -%s。" % [enemy.display_name, _format_amount(health_damage)]
	if enemy.definition_id == "enemy.treatment_skitter":
		message = "%s生命偏低时按 1 使用修复凝胶，或回基地再调制补给。" % message
	return message


func _grant_enemy_drops(enemy: PrototypeEnemy, character_state: CharacterState, world_state: WorldState) -> String:
	if world_state.has_enemy_drops_granted(enemy.instance_id):
		return ""

	var definition := data_registry.get_definition(enemy.definition_id)
	var drops: Array = definition.get("drops", [])
	if drops.is_empty():
		world_state.set_enemy_drops_granted(enemy.instance_id, true)
		return ""

	var parts: Array[String] = []
	for drop in drops:
		if not drop is Dictionary:
			continue

		var definition_id := String(drop.get("id", ""))
		var amount := float(drop.get("amount", 0.0))
		if definition_id.is_empty() or amount <= 0.0:
			continue

		character_state.inventory.add_ref(definition_id, amount)
		parts.append("%s x%s" % [_get_display_name(definition_id), _format_amount(amount)])

	world_state.set_enemy_drops_granted(enemy.instance_id, true)
	if parts.is_empty():
		return ""
	return "获得：%s。" % ", ".join(parts)


func _inspect_ruin_gate(world_state: WorldState) -> Dictionary:
	if not world_state.quest_state.has_completed_quest("quest.defeat_elite_node"):
		return _failure(
			"封锁遗迹入口仍被污染信号干扰。",
			"入口未解锁",
			"先治理污染源点：采集沉积物、处理药剂并压制污染残核。"
		)

	if world_state.quest_state.has_completed_quest("quest.unlock_ruin_signal"):
		return {
			"success": true,
			"message": "遗迹外圈通路已稳定：继续向东进入外圈，回收继电残片。"
		}

	return {
		"success": true,
		"message": "封锁遗迹入口信号已确认：遗迹外圈通路已恢复。"
	}


func _inspect_outer_ring_barrier(character_state: CharacterState, world_state: WorldState) -> Dictionary:
	if not world_state.quest_state.has_completed_quest("quest.assemble_phase_anchor"):
		return _failure(
			"抖动雾幕仍在扩散，临时无法通过。",
			"通路未稳定",
			"先回基地组装稳相信标，再返回遗迹外圈部署。"
		)

	if world_state.quest_state.has_completed_quest("quest.stabilize_outer_ring_barrier"):
		return {
			"success": true,
			"message": "抖动雾幕已稳定，外圈深段通路保持开启。"
		}

	if not character_state.inventory.has_ref("item.phase_anchor", 1):
		return _failure(
			"缺少稳相信标，抖动雾幕无法稳定。",
			"缺少开路物",
			"回基地用基础反应器，把继电残片和污染浆液组装成稳相信标。"
		)

	character_state.inventory.consume_ref("item.phase_anchor", 1)
	return {
		"success": true,
		"message": "已部署稳相信标：抖动雾幕回落，外圈深段通路开启。"
	}


func _inspect_outer_ring_console(world_state: WorldState) -> Dictionary:
	if not world_state.quest_state.has_completed_quest("quest.stabilize_outer_ring_barrier"):
		return _failure(
			"外圈中继台仍被抖动雾幕隔开。",
			"目标未就绪",
			"先在雾幕前部署稳相信标，再进入外圈深段。"
		)

	if world_state.quest_state.has_completed_quest("quest.secure_outer_ring_signal"):
		return {
			"success": true,
			"message": "外圈中继台数据已读取：更深遗迹结构坐标已保留。"
		}

	return {
		"success": true,
		"message": "外圈中继台已接管：更深遗迹结构的稳定回波已定位。"
	}


func _inspect_signal_echo_cache(world_state: WorldState) -> Dictionary:
	if not world_state.quest_state.has_completed_quest("quest.secure_outer_ring_signal"):
		return _failure(
			"外圈回波匣仍处于锁定状态。",
			"目标未就绪",
			"先检查外圈中继台，锁定深段稳定回波。"
		)

	if world_state.quest_state.has_completed_quest("quest.salvage_signal_echo"):
		return {
			"success": true,
			"message": "外圈回波匣已回收：返回基地解析深段回波。"
		}

	return {
		"success": true,
		"message": "已回收外圈回波匣：回基地用基础反应器整理更深遗迹坐标。"
	}


func _inspect_deep_ruin_door(character_state: CharacterState, world_state: WorldState) -> Dictionary:
	if not world_state.quest_state.has_completed_quest("quest.analyze_deep_signal"):
		return _failure(
			"深段入口门禁仍没有可执行坐标。",
			"入口未校准",
			"先回基地解析深段回波，整理出更深遗迹坐标。"
		)

	if world_state.quest_state.has_completed_quest("quest.unlock_deep_ruin_entrance"):
		return {
			"success": true,
			"message": "深段入口门禁已写入：继续向东进入深段，回收相位纤丝。"
		}

	if not character_state.inventory.has_ref("item.deep_ruin_coordinates", 1):
		return _failure(
			"缺少更深遗迹坐标，门禁无法写入。",
			"缺少开门坐标",
			"回基地确认基础反应器已完成深段回波解析，并带上更深遗迹坐标返回。"
		)

	character_state.inventory.consume_ref("item.deep_ruin_coordinates", 1)
	return {
		"success": true,
		"message": "更深遗迹坐标已写入：深段入口门禁开启。"
	}


func _inspect_deep_ruin_latch(character_state: CharacterState, world_state: WorldState) -> Dictionary:
	if not world_state.quest_state.has_completed_quest("quest.assemble_deep_override"):
		return _failure(
			"深段锁扣仍被相位回路封住。",
			"锁扣未覆写",
			"先回基地用污染过滤器精炼相位纤丝，再用基础反应器组装深段覆写栓。"
		)

	if world_state.quest_state.has_completed_quest("quest.unlock_deep_ruin_cache"):
		return {
			"success": true,
			"message": "深段锁扣已覆写：深段样块已经回收。"
		}

	if not character_state.inventory.has_ref("item.deep_override_key", 1):
		return _failure(
			"缺少深段覆写栓，锁扣无法解除。",
			"缺少覆写栓",
			"回处理点过滤器精炼相位纤丝，再去基础反应器组装深段覆写栓。"
		)

	character_state.inventory.consume_ref("item.deep_override_key", 1)
	return {
		"success": true,
		"message": "已覆写深段锁扣：深段样块匣解封，可带回新的深段样块。"
	}


func _evacuate_if_needed(character_state: CharacterState, world_state: WorldState, reason: String) -> Dictionary:
	if character_state.health > 0.0 and character_state.protection > 0.0:
		return {}

	var health_depleted := character_state.health <= 0.0
	var protection_depleted := character_state.protection <= 0.0
	var reason_text := _get_evacuation_reason(health_depleted, protection_depleted)
	character_state.current_region_id = "region.outpost_platform"
	world_state.current_region_id = "region.outpost_platform"
	character_state.health = maxf(character_state.health, character_state.max_health * 0.6)
	character_state.protection = maxf(character_state.protection, character_state.max_protection * 0.4)
	player.position = OUTPOST_RESPAWN_POSITION
	var recovery_text := "已撤回前哨；生命恢复到 %s，防护恢复到 %s" % [
		_format_amount(character_state.health),
		_format_amount(character_state.protection)
	]
	var retry_text := _get_retry_hint(reason, health_depleted, protection_depleted)

	return {
		"title": "撤离前哨",
		"reason_text": reason_text.trim_suffix("，"),
		"recovery_text": recovery_text,
		"retry_text": retry_text,
		"log_message": " %s%s。%s" % [reason_text, recovery_text, retry_text]
	}


func _get_evacuation_reason(health_depleted: bool, protection_depleted: bool) -> String:
	if health_depleted and protection_depleted:
		return "生命和防护耗尽，"
	if health_depleted:
		return "生命耗尽，"
	if protection_depleted:
		return "防护耗尽，"
	return "状态过低，"


func _get_retry_hint(reason: String, health_depleted: bool, protection_depleted: bool) -> String:
	if protection_depleted:
		return "再尝试前：启用过滤模块，按 2 使用抗污染药剂，或回基地处理污染沉积物补充药剂。"
	if health_depleted:
		return "再尝试前：按 1 使用修复凝胶，或回基地用基础反应器调制补给。"
	if reason == "pollution":
		return "再尝试前：检查防护和抗污染药剂。"
	return "再尝试前：补充快捷栏物品。"


func _format_amount(amount: float) -> String:
	if is_equal_approx(amount, roundf(amount)):
		return str(int(amount))
	return "%.1f" % amount


func _failure(message: String, title: String, detail: String) -> Dictionary:
	return {
		"success": false,
		"message": message,
		"failure_feedback": {
			"title": title,
			"detail": detail
		}
	}


func _get_enemy_instance_id(enemy: PrototypeEnemy) -> String:
	return "enemy_instance.%s" % String(enemy.name).to_snake_case()


func _get_region_id_for_position(map_position: Vector2) -> String:
	if map_position.x >= DEEP_RUIN_REGION_X:
		return "region.deep_ruin_threshold"
	if map_position.x >= RUIN_OUTER_RING_X:
		return "region.ruin_outer_ring"
	if map_position.x >= POLLUTION_REGION_X and map_position.y >= POLLUTION_DEEP_Y:
		return "region.pollution_edge"
	if map_position.x >= CRYSTAL_REGION_X:
		return "region.crystal_vein_field"
	return "region.outpost_platform"


func _is_outer_ring_barrier_locked(world_state: WorldState) -> bool:
	return not world_state.quest_state.has_completed_quest("quest.stabilize_outer_ring_barrier")


func _is_deep_ruin_gate_locked(world_state: WorldState) -> bool:
	return not world_state.quest_state.has_completed_quest("quest.unlock_deep_ruin_entrance")
