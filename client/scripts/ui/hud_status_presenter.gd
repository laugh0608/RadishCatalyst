extends RefCounted
class_name HudStatusPresenter

const STATUS_KEY_RESOURCE_IDS: Array[String] = [
	"item.crystal_ore",
	"item.salvage_scrap",
	"item.reactor_calibrator",
	"item.basic_parts",
	"item.polluted_residue",
	"item.relay_shard",
	"item.phase_anchor",
	"item.signal_echo_trace",
	"item.deep_ruin_coordinates",
	"item.phase_filament",
	"item.resonance_filter",
	"item.deep_override_key",
	"item.deep_ruin_core",
	"item.deep_route_imprint",
	"item.phase_conduit",
	"item.deep_signal_matrix",
	"item.filter_media",
	"item.foundation_material",
	"fluid.basic_solvent",
	"fluid.polluted_slurry"
]
const MAX_VISIBLE_KEY_RESOURCE_COUNT := 2

var objective_source_resolver: QuestObjectiveSourceResolver
var objective_source_registry: DataRegistry


func format_status_text(data_registry: DataRegistry, world_state: WorldState, character_state: CharacterState) -> String:
	_ensure_objective_source_resolver(data_registry)
	var active_quest_id := _get_active_quest_id(world_state)
	return "\n".join(
		["RadishCatalyst Prototype"]
		+ _format_objective_lines(data_registry, world_state, active_quest_id)
		+ _format_vital_lines(data_registry, world_state, character_state)
	)


func format_objective_text(data_registry: DataRegistry, world_state: WorldState) -> String:
	_ensure_objective_source_resolver(data_registry)
	var active_quest_id := _get_active_quest_id(world_state)
	return "\n".join(["当前目标"] + _format_objective_lines(data_registry, world_state, active_quest_id))


func format_vitals_text(data_registry: DataRegistry, world_state: WorldState, character_state: CharacterState) -> String:
	_ensure_objective_source_resolver(data_registry)
	return "\n".join(_format_vital_lines(data_registry, world_state, character_state))


func format_pollution_status(
	data_registry: DataRegistry,
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	var region_id := world_state.current_region_id
	var pollution_level := float(world_state.pollution_levels.get(region_id, 0.0))
	if pollution_level <= 0.0:
		return "当前区域稳定，无持续污染。"

	var parts: Array[String] = [
		"%s 污染 %.0f%%" % [
			_get_display_name(data_registry, region_id),
			pollution_level * 100.0
		]
	]
	var module_id := String(character_state.equipment.get("suit_module", ""))
	if module_id.is_empty():
		parts.append("未启用过滤模块")
	else:
		parts.append("%s 生效，消耗 x%.2f" % [
			_get_display_name(data_registry, module_id),
			character_state.get_pollution_drain_multiplier(data_registry)
		])

	if character_state.protection < character_state.max_protection * 0.35:
		parts.append("防护危险，先用抗污染药剂或撤回基地")
	elif character_state.protection < character_state.max_protection * 0.5:
		parts.append("防护偏低，建议先补给")
	else:
		parts.append("防护可继续尝试")
	return "；".join(parts)


func _get_active_quest_id(world_state: WorldState) -> String:
	if not world_state.quest_state.active_quest_ids.is_empty():
		return world_state.quest_state.active_quest_ids[0]
	return ""


func _format_objective_lines(
	data_registry: DataRegistry,
	world_state: WorldState,
	active_quest_id: String
) -> Array[String]:
	return [
		"目标：%s" % _format_goal_name(data_registry, world_state, active_quest_id),
		"进度：%s" % _format_active_quest_progress(data_registry, world_state, active_quest_id)
	]


func _format_vital_lines(
	data_registry: DataRegistry,
	world_state: WorldState,
	character_state: CharacterState
) -> Array[String]:
	return [
		"状态：生命 %.0f / %.0f；防护 %.0f / %.0f" % [
			character_state.health,
			character_state.max_health,
			character_state.protection,
			character_state.max_protection
		],
		"污染：%s" % format_pollution_status(data_registry, world_state, character_state),
		"快捷栏：%s" % _format_quick_slots(data_registry, character_state),
		"关键物资：%s" % _format_key_resources(data_registry, character_state.inventory)
	]


func _format_goal_name(data_registry: DataRegistry, world_state: WorldState, quest_id: String) -> String:
	if not quest_id.is_empty():
		return _get_display_name(data_registry, quest_id)
	if _has_completed_second_deep_pass(world_state):
		return "深段第二轮闭环已完成"
	if _has_completed_deep_ruin_entry(world_state):
		return "深段样块待继续解析"
	if _has_completed_deep_signal_analysis(world_state):
		return "更深遗迹坐标待写入门禁"
	if _is_slice_complete(world_state):
		return "遗迹外圈第一版已完成"
	return "无"


func _format_key_resources(data_registry: DataRegistry, inventory: InventoryState) -> String:
	var parts: Array[String] = []
	var hidden_count := 0
	for definition_id in STATUS_KEY_RESOURCE_IDS:
		var amount := _get_inventory_amount(inventory, definition_id)
		if amount <= 0.0:
			continue
		if parts.size() >= MAX_VISIBLE_KEY_RESOURCE_COUNT:
			hidden_count += 1
			continue
		parts.append("%sx%s" % [_get_display_name(data_registry, definition_id), _format_amount(amount)])
	if parts.is_empty():
		return "暂无"
	if hidden_count > 0:
		return "%s；其余 %d 项" % ["；".join(parts), hidden_count]
	return "；".join(parts)


func _get_inventory_amount(inventory: InventoryState, definition_id: String) -> float:
	if definition_id.begins_with("fluid."):
		return float(inventory.fluids.get(definition_id, 0.0))
	return float(inventory.items.get(definition_id, 0))


func _format_quick_slots(data_registry: DataRegistry, character_state: CharacterState) -> String:
	var parts: Array[String] = []
	for slot_index in range(character_state.quick_slots.size()):
		var item_id := character_state.quick_slots[slot_index]
		if item_id.is_empty():
			parts.append("%d 空" % (slot_index + 1))
			continue

		parts.append("%d %sx%s" % [
			slot_index + 1,
			_get_display_name(data_registry, item_id),
			int(character_state.inventory.items.get(item_id, 0))
		])
	if parts.is_empty():
		return "无"
	return "；".join(parts)


func _format_active_quest_progress(data_registry: DataRegistry, world_state: WorldState, quest_id: String) -> String:
	if quest_id.is_empty():
		if _has_completed_second_deep_pass(world_state):
			return "深段样块和相位导管都已整理成读数矩阵；第二轮基地 -> 深段 -> 基地闭环已成立"
		if _has_completed_deep_ruin_entry(world_state):
			return "深段样块已回收；回基地解析样块后可继续点亮深段阵列"
		if _has_completed_deep_signal_analysis(world_state):
			return "深段回波已转成可执行坐标，返回遗迹外圈最东侧即可写入深段入口门禁"
		if _is_slice_complete(world_state):
			return "外圈中继已确认，更深遗迹结构已定位"
		return "无"

	var quest := data_registry.get_definition(quest_id)
	if quest.is_empty():
		return "无"

	var parts: Array[String] = []
	for objective in quest.get("objectives", []):
		if not objective is Dictionary:
			continue

		var objective_type := String(objective.get("type", ""))
		var target_id := String(objective.get("target_id", ""))
		var required_amount := float(objective.get("amount", 1.0))
		var current_amount := minf(
			world_state.quest_state.get_objective_progress(quest_id, objective_type, target_id),
			required_amount
		)
		parts.append("%s%s %s/%s" % [
			_get_objective_verb(objective_type),
			_format_objective_target_name(data_registry, quest_id, objective_type, target_id),
			_format_amount(current_amount),
			_format_amount(required_amount)
		])

	if parts.is_empty():
		return "无"
	return "；".join(parts)


func _get_objective_verb(objective_type: String) -> String:
	match objective_type:
		"interact":
			return "交互 "
		"visit_region":
			return "进入 "
		"return_region":
			return "返回 "
		"gather_item":
			return "收集 "
		"sample_object":
			return "采样 "
		"craft_item":
			return "制造 "
		"build":
			return "建造 "
		"defeat_enemy":
			return "击败 "
		"inspect":
			return "检查 "
		_:
			return ""


func _format_objective_target_name(
	data_registry: DataRegistry,
	quest_id: String,
	objective_type: String,
	target_id: String
) -> String:
	var target_name := _get_display_name(data_registry, target_id)
	var source_hint := _get_objective_source_hint(quest_id, objective_type, target_id)
	if source_hint.is_empty():
		return target_name
	return "%s（%s）" % [target_name, source_hint]


func _get_objective_source_hint(_quest_id: String, objective_type: String, target_id: String) -> String:
	if objective_source_resolver == null:
		return ""
	if objective_type != "gather_item":
		return ""
	return objective_source_resolver.resolve_source_hint(objective_type, target_id)


func _format_amount(amount: float) -> String:
	if is_equal_approx(amount, roundf(amount)):
		return str(int(amount))
	return "%.1f" % amount


func _get_display_name(data_registry: DataRegistry, definition_id: String) -> String:
	if definition_id.is_empty():
		return ""
	var definition := data_registry.get_definition(definition_id)
	if definition.is_empty():
		return definition_id
	return data_registry.get_text(String(definition.get("display_name_key", definition_id)))


func _is_slice_complete(world_state: WorldState) -> bool:
	return world_state.quest_state.unlocked_effects.has("slice_01_complete")


func _has_completed_deep_signal_analysis(world_state: WorldState) -> bool:
	return world_state.quest_state.has_completed_quest("quest.analyze_deep_signal")


func _has_completed_deep_ruin_entry(world_state: WorldState) -> bool:
	return world_state.quest_state.has_completed_quest("quest.unlock_deep_ruin_cache")


func _has_completed_second_deep_pass(world_state: WorldState) -> bool:
	return world_state.quest_state.has_completed_quest("quest.assemble_deep_signal_matrix")


func _ensure_objective_source_resolver(data_registry: DataRegistry) -> void:
	if data_registry == null:
		objective_source_resolver = null
		objective_source_registry = null
		return
	if objective_source_resolver != null and objective_source_registry == data_registry:
		return
	objective_source_resolver = QuestObjectiveSourceResolver.new(data_registry)
	objective_source_registry = data_registry
