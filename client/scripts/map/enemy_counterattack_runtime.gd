extends RefCounted
class_name EnemyCounterattackRuntime

const POLLUTION_COUNTER_PRESSURE_MULT := 0.5
const POLLUTION_RIDGE_COUNTER_MULT := 1.2
const POLLUTION_REVISIT_COUNTER_MULT := 1.15
const GATE_PRESSURE_COUNTER_MULT := 1.35
const RUIN_PHASE_GUARD_COUNTER_MULT := 1.2
const POLLUTION_PRESSURE_VIAL_DAMAGE_MULT := 0.45
const CORE_STABILIZATION_BUFFER_DAMAGE_MULT := 0.55
const CORE_STABILIZATION_SIDE_SUPPLY_DAMAGE_MULT := 0.8

var data_registry: DataRegistry


func _init(registry: DataRegistry) -> void:
	data_registry = registry


func apply(
	enemy: PrototypeEnemy,
	character_state: CharacterState,
	world_state: WorldState = null,
	enemy_region_id: String = ""
) -> String:
	var definition := data_registry.get_definition(enemy.definition_id)
	var base_stats: Dictionary = definition.get("base_stats", {})
	var attack_damage := float(base_stats.get("attack", 0.0)) * _get_pressure_multiplier(enemy)

	var consumed_core_buffer := _consume_core_stabilization_buffer(enemy, character_state, world_state, enemy_region_id)
	if consumed_core_buffer:
		attack_damage *= CORE_STABILIZATION_BUFFER_DAMAGE_MULT

	var used_core_side_supply := _apply_core_guard_side_supply(enemy, world_state, enemy_region_id)
	if used_core_side_supply:
		attack_damage *= CORE_STABILIZATION_SIDE_SUPPLY_DAMAGE_MULT

	var pressure_vial_spend := _consume_pollution_pressure_vial(enemy, character_state, world_state, enemy_region_id)
	var consumed_pressure_vial := bool(pressure_vial_spend.get("consumed", false))
	if consumed_pressure_vial:
		attack_damage *= POLLUTION_PRESSURE_VIAL_DAMAGE_MULT

	var damage_types: Array = definition.get("damage_types", [])
	if damage_types.has("pollution"):
		attack_damage *= character_state.get_pollution_counter_damage_multiplier(data_registry)
		attack_damage *= FieldOutfittingRuntime.get_pollution_counter_damage_multiplier(character_state, world_state)

	var health_damage := character_state.apply_health_damage(attack_damage)
	var protection_damage := 0.0
	if damage_types.has("pollution"):
		protection_damage = character_state.apply_protection_damage(
			attack_damage
			* POLLUTION_COUNTER_PRESSURE_MULT
			* character_state.get_pollution_drain_multiplier(data_registry)
			* FieldOutfittingRuntime.get_pollution_drain_multiplier(character_state, world_state)
		)

	if protection_damage > 0.0:
		var pollution_message := _format_pollution_counter_message(
			enemy,
			character_state,
			health_damage,
			protection_damage,
			consumed_core_buffer,
			used_core_side_supply,
			pressure_vial_spend,
			world_state
		)
		if enemy.definition_id == "enemy.ruin_phase_guard":
			return pollution_message
		var outfitting_feedback := FieldOutfittingRuntime.format_pollution_pressure_feedback(character_state, world_state)
		if not outfitting_feedback.is_empty():
			return "%s %s" % [pollution_message, outfitting_feedback]
		return pollution_message

	var message := "%s 反击，生命 -%s。" % [enemy.display_name, _format_amount(health_damage)]
	if enemy.definition_id == "enemy.treatment_skitter":
		message = "%s生命偏低时按 1 使用修复凝胶，或回基地再调制补给。" % message
	return message


func _get_pressure_multiplier(enemy: PrototypeEnemy) -> float:
	if enemy.instance_id == "enemy_instance.polluted_skitter_gate_pressure":
		return GATE_PRESSURE_COUNTER_MULT
	if enemy.instance_id == "enemy_instance.polluted_skitter_vial_return_guard":
		return POLLUTION_REVISIT_COUNTER_MULT
	if enemy.instance_id == "enemy_instance.polluted_skitter_slurry_return_guard":
		return 1.18
	if enemy.instance_id == "enemy_instance.polluted_skitter_vial_reserve_guard":
		return 1.28
	if enemy.instance_id == "enemy_instance.polluted_skitter_core_archive_route_guard":
		return 1.24
	if enemy.instance_id == "enemy_instance.polluted_skitter_core_archive_return_guard":
		return 1.32
	if enemy.instance_id == "enemy_instance.polluted_skitter_core_archive_pressure_retest_guard":
		return 1.38
	if enemy.instance_id == FieldOutfittingRuntime.LOGISTICS_MAINTENANCE_POLLUTION_RETEST_GUARD_INSTANCE_ID:
		return 1.42
	if enemy.instance_id == "enemy_instance.polluted_skitter_logistics_maintenance_retest_guard":
		return 1.45
	if enemy.instance_id == "enemy_instance.polluted_skitter_ridge":
		return POLLUTION_RIDGE_COUNTER_MULT
	if enemy.instance_id == "enemy_instance.core_buffer_polluted_skitter":
		return POLLUTION_RIDGE_COUNTER_MULT
	if enemy.definition_id == "enemy.ruin_phase_guard":
		return RUIN_PHASE_GUARD_COUNTER_MULT
	return 1.0


func _consume_core_stabilization_buffer(
	enemy: PrototypeEnemy,
	character_state: CharacterState,
	world_state: WorldState,
	enemy_region_id: String
) -> bool:
	if enemy.definition_id != "enemy.demo_stabilization_guard":
		return false
	if not character_state.inventory.has_ref("item.core_stabilization_buffer", 1):
		return false
	character_state.inventory.consume_ref("item.core_stabilization_buffer", 1)
	_mark_enemy_state(enemy, world_state, enemy_region_id, "core_buffer_used")
	return true


func _apply_core_guard_side_supply(enemy: PrototypeEnemy, world_state: WorldState, enemy_region_id: String) -> bool:
	if enemy.definition_id != "enemy.demo_stabilization_guard":
		return false
	if world_state == null or enemy.instance_id.is_empty():
		return false
	if not _has_core_stabilization_side_supply(world_state):
		return false
	if bool(world_state.get_enemy(enemy.instance_id).get("core_side_supply_used", false)):
		return false
	_mark_enemy_state(enemy, world_state, enemy_region_id, "core_side_supply_used")
	return true


func _consume_pollution_pressure_vial(
	enemy: PrototypeEnemy,
	character_state: CharacterState,
	world_state: WorldState,
	enemy_region_id: String
) -> Dictionary:
	var empty_spend := {
		"consumed": false,
		"before": DepartureSupplyRuntime.get_resistance_vial_count(character_state),
		"after": DepartureSupplyRuntime.get_resistance_vial_count(character_state),
		"target": DepartureSupplyRuntime.get_resistance_vial_target(world_state),
		"can_outpost_restock": DepartureSupplyRuntime.can_outpost_restock_resistance_vial(world_state, character_state)
	}
	if not _is_pollution_pressure_vial_enemy(enemy):
		return empty_spend
	if not character_state.inventory.has_ref(DepartureSupplyRuntime.RESISTANCE_VIAL_ID, 1):
		return empty_spend
	if world_state != null and not enemy.instance_id.is_empty():
		if bool(world_state.get_enemy(enemy.instance_id).get("pressure_vial_used", false)):
			return empty_spend
	else:
		if enemy.has_meta("pressure_vial_used") and bool(enemy.get_meta("pressure_vial_used")):
			return empty_spend
	var spend := DepartureSupplyRuntime.consume_resistance_vial(character_state, world_state)
	_mark_enemy_state(enemy, world_state, enemy_region_id, "pressure_vial_used")
	return spend


func _mark_enemy_state(enemy: PrototypeEnemy, world_state: WorldState, enemy_region_id: String, flag: String) -> void:
	if world_state != null and not enemy.instance_id.is_empty():
		var region_id := enemy_region_id
		if region_id.is_empty():
			region_id = world_state.current_region_id
		var enemy_state := world_state.ensure_enemy(enemy.instance_id, enemy.definition_id, region_id, enemy.max_health)
		enemy_state[flag] = true
	enemy.set_meta(flag, true)


func _has_core_stabilization_side_supply(world_state: WorldState) -> bool:
	return (
		bool(world_state.get_map_object("map_object_instance.demo_stabilization_recovery_cache").get("is_gathered", false))
		or bool(world_state.get_map_object("map_object_instance.demo_stabilization_recovery_wreckage").get("is_gathered", false))
	)


func _is_pollution_pressure_vial_enemy(enemy: PrototypeEnemy) -> bool:
	return (
		enemy.instance_id == "enemy_instance.polluted_skitter_gate_pressure"
		or enemy.instance_id == "enemy_instance.polluted_skitter_vial_return_guard"
		or enemy.instance_id == "enemy_instance.polluted_skitter_slurry_return_guard"
		or enemy.instance_id == "enemy_instance.polluted_skitter_vial_reserve_guard"
		or enemy.instance_id == "enemy_instance.polluted_skitter_core_archive_route_guard"
		or enemy.instance_id == "enemy_instance.polluted_skitter_core_archive_return_guard"
		or enemy.instance_id == "enemy_instance.polluted_skitter_core_archive_pressure_retest_guard"
		or enemy.instance_id == FieldOutfittingRuntime.LOGISTICS_MAINTENANCE_POLLUTION_RETEST_GUARD_INSTANCE_ID
		or enemy.instance_id == "enemy_instance.polluted_skitter_logistics_maintenance_retest_guard"
		or enemy.instance_id == "enemy_instance.polluted_skitter_ridge"
		or enemy.instance_id == "enemy_instance.core_buffer_polluted_skitter"
		or enemy.definition_id == "enemy.demo_stabilization_guard"
	)


func _format_pollution_counter_message(
	enemy: PrototypeEnemy,
	character_state: CharacterState,
	health_damage: float,
	protection_damage: float,
	consumed_core_buffer: bool,
	used_core_side_supply: bool,
	pressure_vial_spend: Dictionary,
	world_state: WorldState
) -> String:
	var message := "%s 反击，生命 -%s，防护 -%s。" % [
		enemy.display_name,
		_format_amount(health_damage),
		_format_amount(protection_damage)
	]
	match enemy.instance_id:
		"enemy_instance.polluted_skitter_gate_pressure":
			return _format_gate_pressure_message(message, pressure_vial_spend, world_state, character_state)
		"enemy_instance.polluted_skitter_vial_return_guard":
			return _format_vial_return_message(message, pressure_vial_spend, world_state, character_state)
		"enemy_instance.polluted_skitter_slurry_return_guard":
			return _format_slurry_return_message(message, pressure_vial_spend, world_state, character_state)
		"enemy_instance.polluted_skitter_vial_reserve_guard":
			return _format_vial_reserve_message(message, pressure_vial_spend, world_state, character_state)
		"enemy_instance.polluted_skitter_core_archive_route_guard":
			return _format_core_archive_route_message(message, pressure_vial_spend, world_state, character_state)
		"enemy_instance.polluted_skitter_core_archive_return_guard":
			return _format_core_archive_return_message(message, pressure_vial_spend, world_state, character_state)
		"enemy_instance.polluted_skitter_core_archive_pressure_retest_guard":
			return _format_core_archive_pressure_retest_message(
				message,
				pressure_vial_spend,
				world_state,
				character_state
			)
		FieldOutfittingRuntime.LOGISTICS_MAINTENANCE_POLLUTION_RETEST_GUARD_INSTANCE_ID:
			return _format_logistics_maintenance_pollution_retest_message(
				message,
				pressure_vial_spend,
				world_state,
				character_state
			)
		"enemy_instance.polluted_skitter_logistics_maintenance_retest_guard":
			return _format_logistics_maintenance_retest_message(
				message,
				pressure_vial_spend,
				world_state,
				character_state
			)
		"enemy_instance.polluted_skitter_ridge":
			return _format_ridge_message(message, pressure_vial_spend, world_state, character_state)
		"enemy_instance.core_buffer_polluted_skitter":
			return _format_core_buffer_supply_message(message, pressure_vial_spend, world_state, character_state)
	if enemy.definition_id == "enemy.ruin_phase_guard":
		return _format_ruin_phase_guard_message(message, character_state, world_state)
	if enemy.definition_id == "enemy.demo_stabilization_guard":
		return _format_core_guard_message(message, consumed_core_buffer, used_core_side_supply, pressure_vial_spend)
	return message


func _format_gate_pressure_message(
	message: String,
	pressure_vial_spend: Dictionary,
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	if bool(pressure_vial_spend.get("consumed", false)):
		return "%s%s，过滤器准备让生命和防护承压降低；继续压制入口信号。" % [
			message,
			DepartureSupplyRuntime.format_resistance_vial_pressure_spend(pressure_vial_spend, "门前")
		]
	return "%s门前污染压力更高，%s；防护偏低时按 2 使用抗污染药剂，生命偏低时按 1 使用修复凝胶。" % [
		message,
		DepartureSupplyRuntime.format_resistance_vial_shortage_for_pressure(world_state, character_state, "门前")
	]


func _format_vial_return_message(
	message: String,
	pressure_vial_spend: Dictionary,
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	if bool(pressure_vial_spend.get("consumed", false)):
		return "%s%s，过滤器准备让这段回访战斗更稳；清完后回收沉积物再回基地处理。" % [
			message,
			DepartureSupplyRuntime.format_resistance_vial_pressure_spend(pressure_vial_spend, "侧翼")
		]
	return "%s侧翼污染压力抬升，过滤模块会降低生命和防护承压；%s。" % [
		message,
		DepartureSupplyRuntime.format_resistance_vial_shortage_for_pressure(world_state, character_state, "侧翼")
	]


func _format_slurry_return_message(
	message: String,
	pressure_vial_spend: Dictionary,
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	if bool(pressure_vial_spend.get("consumed", false)):
		return "%s%s；清完后回收沉积物，回过滤器补浆液，再到基础反应器回收基础零件。" % [
			message,
			DepartureSupplyRuntime.format_resistance_vial_pressure_spend(pressure_vial_spend, "副产口袋")
		]
	return "%s副产口袋污染压力抬升，基础过滤模块会降低承压；%s，清完后补沉积物处理浆液。" % [
		message,
		DepartureSupplyRuntime.format_resistance_vial_shortage_for_pressure(world_state, character_state, "副产口袋")
	]


func _format_vial_reserve_message(
	message: String,
	pressure_vial_spend: Dictionary,
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	if bool(pressure_vial_spend.get("consumed", false)):
		return "%s%s；清完后回收沉积物，回过滤器补下一支药剂和污染浆液。" % [
			message,
			DepartureSupplyRuntime.format_resistance_vial_pressure_spend(pressure_vial_spend, "药剂储备口袋")
		]
	return "%s药剂储备口袋污染压力抬升，%s；清完后补沉积物处理下一支药剂。" % [
		message,
		DepartureSupplyRuntime.format_resistance_vial_shortage_for_pressure(world_state, character_state, "药剂储备口袋")
	]


func _format_core_archive_route_message(
	message: String,
	pressure_vial_spend: Dictionary,
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	if bool(pressure_vial_spend.get("consumed", false)):
		return "%s%s；核心归档维护会继续降低这段出发路线承压，清完后回收沉积物补满药剂。" % [
			message,
			DepartureSupplyRuntime.format_resistance_vial_pressure_spend(pressure_vial_spend, "出发路线回访")
		]
	return "%s出发路线回访口袋污染压力抬升，%s；清完后回过滤器补药剂，再从出发口复测核心站。" % [
		message,
		DepartureSupplyRuntime.format_resistance_vial_shortage_for_pressure(world_state, character_state, "出发路线回访")
	]


func _format_core_archive_return_message(
	message: String,
	pressure_vial_spend: Dictionary,
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	if bool(pressure_vial_spend.get("consumed", false)):
		return "%s%s；核心归档维护会继续降低这段回访承压，清完后回收沉积物补药剂和污染浆液。" % [
			message,
			DepartureSupplyRuntime.format_resistance_vial_pressure_spend(pressure_vial_spend, "归档维护回访")
		]
	return "%s归档维护回访口袋污染压力抬升，%s；清完后回收沉积物验证基地维护反哺外勤。" % [
		message,
		DepartureSupplyRuntime.format_resistance_vial_shortage_for_pressure(world_state, character_state, "归档维护回访")
	]


func _format_core_archive_pressure_retest_message(
	message: String,
	pressure_vial_spend: Dictionary,
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	if bool(pressure_vial_spend.get("consumed", false)):
		return "%s%s；核心归档维护和双药剂会继续降低复测压力点承压，清完后回收沉积物处理成下一趟补给。" % [
			message,
			DepartureSupplyRuntime.format_resistance_vial_pressure_spend(pressure_vial_spend, "复测压力点")
		]
	return "%s复测压力点污染反扑更强，%s；清完后回收沉积物，回过滤器处理成药剂和污染浆液。" % [
		message,
		DepartureSupplyRuntime.format_resistance_vial_shortage_for_pressure(world_state, character_state, "复测压力点")
	]


func _format_logistics_maintenance_retest_message(
	message: String,
	pressure_vial_spend: Dictionary,
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	if bool(pressure_vial_spend.get("consumed", false)):
		return "%s%s；整备台后勤维护已压低本次核心站复测承压，清完后回收沉积物回过滤器处理。" % [
			message,
			DepartureSupplyRuntime.format_resistance_vial_pressure_spend(pressure_vial_spend, "后勤维护复测")
		]
	return "%s后勤维护复测压力抬升，但整备台维护已压低本次基础承压；%s；清完后回收沉积物，回过滤器处理成药剂和污染浆液。" % [
		message,
		DepartureSupplyRuntime.format_resistance_vial_shortage_for_pressure(world_state, character_state, "后勤维护复测")
	]


func _format_logistics_maintenance_pollution_retest_message(
	message: String,
	pressure_vial_spend: Dictionary,
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	if bool(pressure_vial_spend.get("consumed", false)):
		return "%s%s；整备台后勤维护已压低污染边界复测承压，清完后回收沉积物回过滤器处理。" % [
			message,
			DepartureSupplyRuntime.format_resistance_vial_pressure_spend(pressure_vial_spend, "污染边界后勤复测")
		]
	return "%s污染边界后勤维护复测压力抬升，但整备台维护已压低本次基础承压；%s；清完后回收沉积物，回过滤器处理成药剂和污染浆液。" % [
		message,
		DepartureSupplyRuntime.format_resistance_vial_shortage_for_pressure(world_state, character_state, "污染边界后勤复测")
	]


func _format_ridge_message(
	message: String,
	pressure_vial_spend: Dictionary,
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	if bool(pressure_vial_spend.get("consumed", false)):
		return "%s%s，过滤器准备让这段回访战斗更稳；清完后把沉积物带回过滤器处理。" % [
			message,
			DepartureSupplyRuntime.format_resistance_vial_pressure_spend(pressure_vial_spend, "污染脊")
		]
	return "%s污染脊守卫压迫更强，过滤模块会降低生命和防护承压；%s。" % [
		message,
		DepartureSupplyRuntime.format_resistance_vial_shortage_for_pressure(world_state, character_state, "污染脊")
	]


func _format_core_buffer_supply_message(
	message: String,
	pressure_vial_spend: Dictionary,
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	if bool(pressure_vial_spend.get("consumed", false)):
		return "%s%s，过滤器准备让这场回访战斗更稳；清完后把沉积物带回过滤器处理。" % [
			message,
			DepartureSupplyRuntime.format_resistance_vial_pressure_spend(pressure_vial_spend, "补料点")
		]
	return "%s补料点污染压力更强，过滤模块会降低生命和防护承压；%s，清完后把沉积物带回过滤器处理。" % [
		message,
		DepartureSupplyRuntime.format_resistance_vial_shortage_for_pressure(world_state, character_state, "补料点")
	]


func _format_ruin_phase_guard_message(
	message: String,
	character_state: CharacterState,
	world_state: WorldState
) -> String:
	if String(character_state.equipment.get("suit_module", "")) == "equipment.filter_module_t1":
		return "%s基础过滤模块缓冲了外圈回波反击；%s；战后回收污染回波沉积，再回过滤器处理副产。" % [
			message,
			FieldOutfittingRuntime.format_ruin_outer_ring_pressure_feedback(character_state, world_state).trim_suffix("。")
		]
	return "%s相位守卫回波夹带污染压力；基础过滤模块可降低生命和防护承压，战后仍要回收沉积物处理副产。" % message


func _format_core_guard_message(
	message: String,
	consumed_core_buffer: bool,
	used_core_side_supply: bool,
	pressure_vial_spend: Dictionary
) -> String:
	var core_guard_pressure_parts: Array[String] = []
	if consumed_core_buffer:
		core_guard_pressure_parts.append("核心稳压缓冲包已消耗")
	if used_core_side_supply:
		core_guard_pressure_parts.append("侧边补给已接入守卫战稳压")
	if bool(pressure_vial_spend.get("consumed", false)):
		core_guard_pressure_parts.append(DepartureSupplyRuntime.format_resistance_vial_pressure_spend(pressure_vial_spend, "守卫"))
	if not core_guard_pressure_parts.is_empty():
		return "%s%s，第一段回写压力被削弱；击败守卫后回收缓存，补给会继续支撑核心写入。" % [
			message,
			"，".join(core_guard_pressure_parts)
		]
	return "%s没有核心稳压缓冲包或药剂排压，回写压力完整命中；建议回基地整备后再战。" % message


func _format_amount(amount: float) -> String:
	if is_equal_approx(amount, roundf(amount)):
		return str(int(amount))
	return "%.1f" % amount
