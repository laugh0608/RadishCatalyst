extends Node2D
class_name VerticalSliceMap

signal interaction_available(interactable: PrototypeInteractable)
signal interaction_cleared(interactable: PrototypeInteractable)

const ATTACK_RANGE := 90.0
const BASE_ATTACK_DAMAGE := 10.0
const POLLUTION_COUNTER_PRESSURE_MULT := 0.5

@onready var player: PlayerController = $Player
@onready var interactables_root: Node2D = $Interactables
@onready var enemies_root: Node2D = $Enemies

var data_registry: DataRegistry
var current_interactable: PrototypeInteractable
var gather_system: GatherSystem


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
		return {
			"success": false,
			"message": "附近没有可交互目标。"
		}

	var interacted := current_interactable
	var result := gather_system.interact_with_object(
		interacted.instance_id,
		interacted.definition_id,
		interacted.interaction_type,
		character_state,
		world_state,
		interacted.get_current_recipe_id()
	)
	if bool(result.get("success", false)):
		interacted.mark_consumed()
	if not interacted.can_interact():
		current_interactable = null
		interaction_cleared.emit(interacted)
	return result


func try_cycle_recipe() -> Dictionary:
	if current_interactable == null:
		return {
			"success": false,
			"message": "附近没有可切换配方的设备。"
		}
	if current_interactable.interaction_type != "process_recipe":
		return {
			"success": false,
			"message": "当前目标不是加工设备。"
		}
	if current_interactable.get_recipe_count() <= 1:
		return {
			"success": false,
			"message": "当前设备没有可轮换配方。"
		}

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
		return {
			"success": false,
			"message": "攻击挥空：附近没有敌人。"
		}

	var damage := _get_attack_damage(character_state)
	var result := target.apply_hit(damage)
	world_state.update_enemy_health(
		target.instance_id,
		float(result.get("health", 0.0)),
		bool(result.get("defeated", false))
	)

	if bool(result.get("defeated", false)):
		if target.definition_id == "enemy.polluted_skitter":
			return {
				"success": true,
				"message": "击败：%s。污染处理点周边暂时安全。" % target.display_name,
				"enemy_definition_id": target.definition_id,
				"enemy_defeated": true
			}
		return {
			"success": true,
			"message": "击败：%s。" % target.display_name,
			"enemy_definition_id": target.definition_id,
			"enemy_defeated": true
		}

	var counter_message := _apply_enemy_counterattack(target, character_state)
	return {
		"success": true,
		"message": "命中：%s，造成 %.0f 伤害，剩余 HP %.0f。%s" % [
			target.display_name,
			damage,
			float(result.get("health", 0.0)),
			counter_message
		],
		"enemy_definition_id": target.definition_id,
		"enemy_defeated": false
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
			_get_enemy_region_id(definition),
			max_health
		)
		enemy.apply_saved_state(enemy_state)


func _get_display_name(definition_id: String) -> String:
	var definition := data_registry.get_definition(definition_id)
	if definition.is_empty():
		return definition_id
	return data_registry.get_text(String(definition.get("display_name_key", definition_id)))


func _get_enemy_region_id(definition: Dictionary) -> String:
	var spawn_regions: Array = definition.get("spawn_regions", [])
	if spawn_regions.is_empty():
		return ""
	return String(spawn_regions[0])


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
	current_interactable = interactable
	interaction_available.emit(interactable)


func _on_interactable_body_exited(body: Node2D, interactable: PrototypeInteractable) -> void:
	if body != player or current_interactable != interactable:
		return
	current_interactable = null
	interaction_cleared.emit(interactable)


func _get_nearest_attack_target() -> PrototypeEnemy:
	var nearest_enemy: PrototypeEnemy = null
	var nearest_distance := INF

	for enemy in enemies_root.get_children():
		if not enemy is PrototypeEnemy or not enemy.can_be_attacked():
			continue

		var distance := player.global_position.distance_to(enemy.global_position)
		if distance > ATTACK_RANGE or distance >= nearest_distance:
			continue

		nearest_enemy = enemy
		nearest_distance = distance

	return nearest_enemy


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
	return "%s 反击，生命 -%s。" % [enemy.display_name, _format_amount(health_damage)]


func _format_amount(amount: float) -> String:
	if is_equal_approx(amount, roundf(amount)):
		return str(int(amount))
	return "%.1f" % amount


func _get_enemy_instance_id(enemy: PrototypeEnemy) -> String:
	return "enemy_instance.%s" % String(enemy.name).to_snake_case()
