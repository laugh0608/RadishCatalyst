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
	"item.phase_splinter",
	"item.phase_lens_blank",
	"item.relay_tuning_lens",
	"item.inner_fault_trace",
	"item.phase_well_coordinate",
	"item.fault_residue",
	"item.stabilized_fault_core",
	"item.phase_well_key",
	"item.phase_well_locator",
	"item.phase_well_route",
	"item.well_flux_shard",
	"item.phase_well_stabilizer",
	"item.phase_well_probe",
	"item.phase_well_core",
	"item.phase_well_spectrum",
	"item.well_ash",
	"item.phase_well_lattice",
	"item.phase_well_pike",
	"item.phase_well_heart",
	"item.phase_well_pulse_sheet",
	"item.heart_spine",
	"item.phase_well_damper",
	"item.phase_well_shunt",
	"item.phase_well_spindle",
	"item.phase_well_warp_sheet",
	"item.weft_bundle",
	"item.phase_well_tension_rib",
	"item.phase_well_shuttle",
	"item.phase_well_weave_core",
	"item.phase_well_pattern_sheet",
	"item.selvedge_strip",
	"item.phase_well_frame_rib",
	"item.phase_well_frame_key",
	"item.phase_well_knot_core",
	"item.phase_well_tether_sheet",
	"item.tether_fiber",
	"item.phase_well_tether_rib",
	"item.phase_well_tether_spike",
	"item.phase_well_anchor_core",
	"item.phase_well_return_sheet",
	"item.anchor_core_dust",
	"item.anchor_field_filter",
	"item.phase_well_anchor_stake",
	"item.phase_well_echo_shard",
	"item.phase_well_stability_readout",
	"item.stability_echo_sample",
	"item.frontline_action_report",
	"item.supply_return_trace",
	"item.short_action_feedback",
	"item.route_signal_trace",
	"item.route_action_feedback",
	"item.steady_supply_trace",
	"item.steady_supply_feedback",
	"item.phase_survey_trace",
	"item.phase_survey_feedback",
	"item.filter_media",
	"item.foundation_material",
	"fluid.basic_solvent",
	"fluid.polluted_slurry"
]
const MAX_VISIBLE_KEY_RESOURCE_COUNT := 2
const MAX_CONTEXT_RESOURCE_COUNT := 3

var objective_source_resolver: QuestObjectiveSourceResolver
var objective_source_registry: DataRegistry


func format_status_text(data_registry: DataRegistry, world_state: WorldState, character_state: CharacterState) -> String:
	_ensure_objective_source_resolver(data_registry)
	var active_quest_id := _get_active_quest_id(world_state)
	return "\n".join(
		["当前目标"]
		+ _format_objective_lines(data_registry, world_state, active_quest_id)
		+ _format_key_resource_lines(data_registry, world_state, character_state, active_quest_id)
		+ ["基地摘要"]
		+ _format_base_summary_lines(data_registry, world_state, character_state, active_quest_id)
		+ ["角色状态"]
		+ _format_character_lines(data_registry, world_state, character_state)
	)


func format_objective_text(
	data_registry: DataRegistry,
	world_state: WorldState,
	character_state: CharacterState = null
) -> String:
	_ensure_objective_source_resolver(data_registry)
	var active_quest_id := _get_active_quest_id(world_state)
	return "\n".join(
		["当前目标"]
		+ _format_objective_lines(data_registry, world_state, active_quest_id, true)
		+ _format_key_resource_lines(data_registry, world_state, character_state, active_quest_id)
	)


func format_vitals_text(data_registry: DataRegistry, world_state: WorldState, character_state: CharacterState) -> String:
	_ensure_objective_source_resolver(data_registry)
	return "\n".join(
		["基地摘要"]
		+ _format_base_summary_lines(data_registry, world_state, character_state, _get_active_quest_id(world_state))
		+ ["角色状态"]
		+ _format_character_lines(data_registry, world_state, character_state)
	)


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
			* FieldOutfittingRuntime.get_pollution_drain_multiplier(character_state, world_state)
		])
		if FieldOutfittingRuntime.has_active_core_archive_maintenance(character_state, world_state):
			parts.append("核心归档维护已接入")

	if character_state.protection < character_state.max_protection * 0.35:
		parts.append("防护危险，先用抗污染药剂或撤回基地")
	elif character_state.protection < character_state.max_protection * 0.5:
		parts.append("防护偏低，建议先补给")
	else:
		parts.append("防护可继续尝试")
	return "；".join(parts)


func _get_active_quest_id(world_state: WorldState) -> String:
	if _is_base_action_choice_state(world_state):
		return ""
	if not world_state.quest_state.active_quest_ids.is_empty():
		return world_state.quest_state.active_quest_ids[0]
	return ""


func _format_objective_lines(
	data_registry: DataRegistry,
	world_state: WorldState,
	active_quest_id: String,
	compact: bool = false
) -> Array[String]:
	var lines: Array[String] = ["目标：%s" % _format_goal_name(data_registry, world_state, active_quest_id)]
	if not compact:
		lines.append("进度：%s" % _format_active_quest_progress(data_registry, world_state, active_quest_id))
		return lines

	var progress_lines := _format_active_quest_progress_lines(data_registry, world_state, active_quest_id)
	if progress_lines.is_empty():
		lines.append("进度：无")
		return lines
	for index in range(progress_lines.size()):
		var prefix := "进度：" if index == 0 else "  "
		lines.append("%s%s" % [prefix, progress_lines[index]])
	return lines


func _format_character_lines(
	data_registry: DataRegistry,
	world_state: WorldState,
	character_state: CharacterState
) -> Array[String]:
	return [
		"生命 / 防护：%.0f / %.0f；%.0f / %.0f" % [
			character_state.health,
			character_state.max_health,
			character_state.protection,
			character_state.max_protection
		],
		"污染：%s" % format_pollution_status(data_registry, world_state, character_state),
		"快捷栏：%s" % _format_quick_slots(data_registry, character_state),
		"模块：%s" % _format_equipment_summary(data_registry, character_state),
		CharacterKitRuntime.format_hud_tool_action_status(character_state, world_state)
	]


func _format_key_resource_lines(
	data_registry: DataRegistry,
	world_state: WorldState,
	character_state: CharacterState,
	active_quest_id: String
) -> Array[String]:
	return ["关键资源：%s" % _format_contextual_key_resources(
		data_registry,
		world_state,
		character_state,
		active_quest_id
	)]


func _format_base_summary_lines(
	data_registry: DataRegistry,
	world_state: WorldState,
	character_state: CharacterState,
	active_quest_id: String
) -> Array[String]:
	var active_structure_summary := _format_active_base_structure(data_registry, world_state)
	if not active_structure_summary.is_empty():
		return active_structure_summary

	var active_quest := data_registry.get_definition(active_quest_id)
	var core_stabilization_summary := CoreStabilizationPressureFormatter.format_hud_summary(world_state, character_state, active_quest_id)
	if not core_stabilization_summary.is_empty():
		return core_stabilization_summary
	var slurry_reclaim_summary := _format_pollution_slurry_reclaim_summary(
		world_state,
		character_state,
		active_quest_id
	)
	if not slurry_reclaim_summary.is_empty():
		return slurry_reclaim_summary
	if not active_quest.is_empty():
		var craft_summary := _format_current_craft_summary(data_registry, active_quest, character_state, world_state)
		if not craft_summary.is_empty():
			return craft_summary
		var build_summary := _format_current_build_summary(data_registry, active_quest, character_state, world_state)
		if not build_summary.is_empty():
			return build_summary
		if active_quest_id == "quest.plan_stability_frontline_action":
			return ["行动台确认稳窗回访：只派发稳窗回波探点"]
		if active_quest_id == "quest.confirm_supply_frontline_action":
			return ["行动台确认补给短行动：只派发补给回执标记"]
		if active_quest_id == "quest.confirm_route_frontline_action":
			return [
				"行动台确认巡线短行动：只派发巡线信标",
				"短行动反馈已归档：第三条行动入口已整理"
			]
	if _is_base_action_choice_state(world_state):
		return [
			"行动方案：稳场补给低风险偏整备资源",
			"相位测绘多读数换路线提示；压力清障高风险换防护收益"
		]
	var outfitting_summary := _format_outfitting_station_summary(world_state, character_state)
	if not outfitting_summary.is_empty():
		return outfitting_summary
	var industrial_summary := IndustrialTechSpineFormatter.format_hud_summary(world_state, character_state)
	if not industrial_summary.is_empty():
		return industrial_summary

	return ["设备：待命；当前目标先外出推进"]


func _is_base_action_choice_state(world_state: WorldState) -> bool:
	if world_state == null:
		return false
	return (
		world_state.quest_state.has_active_quest("quest.choose_steady_supply_action")
		and world_state.quest_state.has_active_quest("quest.choose_phase_survey_action")
		and world_state.quest_state.has_active_quest("quest.choose_pressure_clearance_action")
	)


func _format_pollution_slurry_reclaim_summary(
	world_state: WorldState,
	character_state: CharacterState,
	active_quest_id: String
) -> Array[String]:
	if not ["", "quest.enter_pollution_edge", "quest.unlock_ruin_signal"].has(active_quest_id):
		return []
	if not world_state.quest_state.unlocked_effects.has("recipe.reclaim_basic_parts"):
		return []
	var slurry_amount := float(character_state.inventory.fluids.get("fluid.polluted_slurry", 0.0))
	if slurry_amount <= 0.0:
		return []
	if world_state.has_base_structure_definition("building.slurry_buffer_tank"):
		return [
			"后勤收益：污染浆液缓冲罐已接入前哨补给",
			"前哨核心可把抗污染药剂补到 2 份，再出发承接污染压力"
		]
	if active_quest_id != "quest.unlock_ruin_signal":
		return [
			"二次收益：可用污染浆液 x%s 建污染浆液缓冲罐" % _format_amount(slurry_amount),
			"建成后前哨核心可把抗污染药剂补到 2 份，支撑下一趟污染回访"
		]
	if active_quest_id == "quest.unlock_ruin_signal":
		return [
			"门前整备：基础反应器可回收污染浆液 x%s -> 基础零件" % _format_amount(slurry_amount),
			"回收后带基础过滤模块和抗污染药剂确认封锁入口信号"
		]
	return [
		"副产去向：基础反应器可回收污染浆液 x%s -> 基础零件" % _format_amount(slurry_amount),
		"回收后若还缺药剂 / 浆液，回污染边界副产口袋或药剂储备口袋补沉积物再过滤"
	]


func _format_outfitting_station_summary(world_state: WorldState, character_state: CharacterState) -> Array[String]:
	return DepartureReadinessFormatter.format_hud_summary(world_state, character_state)


func _format_goal_name(data_registry: DataRegistry, world_state: WorldState, quest_id: String) -> String:
	if not quest_id.is_empty():
		return _get_display_name(data_registry, quest_id)
	var action_goal := BaseActionDispatchPlan.format_status_goal(world_state)
	if not action_goal.is_empty():
		return action_goal
	var next_sortie_goal := CoreGuardAftermathFormatter.format_next_sortie_goal_name(world_state)
	if not next_sortie_goal.is_empty():
		return next_sortie_goal
	if _has_completed_phase_survey_feedback(world_state):
		return "相位测绘反馈已归档"
	if _has_completed_steady_supply_feedback(world_state):
		return "稳场补给反馈已归档"
	if _has_completed_route_action_feedback(world_state):
		return "基地行动选择待确认"
	if _has_completed_route_signal_marker(world_state):
		return "巡线读数待解析"
	if _has_completed_route_frontline_action(world_state):
		return "巡线信标待读取"
	if _has_completed_short_action_feedback(world_state):
		return "巡线短行动待确认"
	if _has_completed_supply_return_marker(world_state):
		return "补给回执待解析"
	if _has_completed_supply_frontline_action(world_state):
		return "补给回执标记待读取"
	if _has_completed_stability_echo_report(world_state):
		return "补给短行动待确认"
	if _has_completed_stability_echo_probe(world_state):
		return "稳窗回波样本待解析"
	if _has_completed_stability_frontline_action(world_state):
		return "稳窗回波探点待读取"
	if _has_completed_phase_well_stability_window_calibration(world_state):
		return "前线行动待确认"
	if _has_completed_phase_well_echo_shard_analysis(world_state):
		return "稳窗读数待现场校准"
	if _has_completed_phase_well_anchor_field(world_state):
		return "稳窗余响片已带回"
	if _has_completed_phase_well_tether(world_state):
		return "稳场锚核待解析"
	if _has_completed_phase_well_frame(world_state):
		return "锚定结核待解析"
	if _has_completed_phase_well_loom(world_state):
		return "锁相织构核待解析"
	if _has_completed_phase_well_chamber(world_state):
		return "风蚀张力核待解析"
	if _has_completed_phase_well_sink(world_state):
		return "碎晶心核待解析"
	if _has_completed_inner_phase_well(world_state):
		return "回声芯样本待解析"
	if _has_completed_phase_well_lock(world_state):
		return "回声定位器待解析"
	if _has_completed_phase_fault_spire(world_state):
		return "内层故障轨迹待解析"
	if _has_completed_phase_relay_anchor(world_state):
		return "前线回传锚点已部署"
	if _has_completed_second_deep_pass(world_state):
		return "前线回传锚点待部署"
	if _has_completed_deep_ruin_entry(world_state):
		return "裂相样块待继续解析"
	if _has_completed_deep_signal_analysis(world_state):
		return "裂相坐标待写入门禁"
	if _is_slice_complete(world_state):
		return "封锁遗迹第一版已完成"
	return "无"


func _format_contextual_key_resources(
	data_registry: DataRegistry,
	world_state: WorldState,
	character_state: CharacterState,
	active_quest_id: String
) -> String:
	var active_quest := data_registry.get_definition(active_quest_id)
	var parts: Array[String] = []
	var seen := {}
	if not active_quest.is_empty():
		for objective in active_quest.get("objectives", []):
			if not objective is Dictionary:
				continue
			var objective_type := String(objective.get("type", ""))
			var target_id := String(objective.get("target_id", ""))
			var required_amount := float(objective.get("amount", 1.0))
			if objective_type == "gather_item" or objective_type == "craft_item":
				_append_objective_resource(parts, seen, data_registry, world_state, active_quest_id, objective_type, target_id, required_amount)
			if objective_type == "craft_item":
				var recipe := _find_recipe_for_output(data_registry, target_id)
				_append_recipe_inputs(parts, seen, data_registry, character_state, recipe)
			if objective_type == "build":
				var building := data_registry.get_definition(target_id)
				_append_cost_refs(parts, seen, data_registry, character_state, building.get("build_cost", []))
			if parts.size() >= MAX_CONTEXT_RESOURCE_COUNT:
				break

	if parts.is_empty():
		return _format_fallback_key_resources(data_registry, character_state)
	return "；".join(parts.slice(0, MAX_CONTEXT_RESOURCE_COUNT))


func _format_fallback_key_resources(data_registry: DataRegistry, character_state: CharacterState) -> String:
	if character_state == null:
		return "暂无"
	var parts: Array[String] = []
	var hidden_count := 0
	for definition_id in STATUS_KEY_RESOURCE_IDS:
		var amount := _get_inventory_amount(character_state.inventory, definition_id)
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


func _append_objective_resource(
	parts: Array[String],
	seen: Dictionary,
	data_registry: DataRegistry,
	world_state: WorldState,
	quest_id: String,
	objective_type: String,
	target_id: String,
	required_amount: float
) -> void:
	if target_id.is_empty() or seen.has(target_id):
		return
	var current_amount := minf(
		world_state.quest_state.get_objective_progress(quest_id, objective_type, target_id),
		required_amount
	)
	parts.append("%s %s/%s" % [
		_get_display_name(data_registry, target_id),
		_format_amount(current_amount),
		_format_amount(required_amount)
	])
	seen[target_id] = true


func _append_recipe_inputs(
	parts: Array[String],
	seen: Dictionary,
	data_registry: DataRegistry,
	character_state: CharacterState,
	recipe: Dictionary
) -> void:
	if character_state == null or recipe.is_empty():
		return
	_append_cost_refs(parts, seen, data_registry, character_state, recipe.get("inputs", []))


func _append_cost_refs(
	parts: Array[String],
	seen: Dictionary,
	data_registry: DataRegistry,
	character_state: CharacterState,
	refs: Array
) -> void:
	if character_state == null:
		return
	for ref in refs:
		if not ref is Dictionary:
			continue
		var definition_id := String(ref.get("id", ""))
		var required_amount := float(ref.get("amount", 0.0))
		if definition_id.is_empty() or required_amount <= 0.0 or seen.has(definition_id):
			continue
		parts.append("%s %s/%s" % [
			_get_display_name(data_registry, definition_id),
			_format_amount(_get_inventory_amount(character_state.inventory, definition_id)),
			_format_amount(required_amount)
		])
		seen[definition_id] = true
		if parts.size() >= MAX_CONTEXT_RESOURCE_COUNT:
			return


func _get_inventory_amount(inventory: InventoryState, definition_id: String) -> float:
	if definition_id.begins_with("fluid."):
		return float(inventory.fluids.get(definition_id, 0.0))
	if definition_id.begins_with("equipment."):
		return float(inventory.equipment.get(definition_id, 0))
	return float(inventory.items.get(definition_id, 0))


func _format_active_base_structure(data_registry: DataRegistry, world_state: WorldState) -> Array[String]:
	for structure in world_state.base_structures.values():
		if not structure is Dictionary:
			continue
		if String(structure.get("status", "")) != "in_progress":
			continue
		var recipe_id := String(structure.get("active_recipe_id", ""))
		var structure_name := _get_display_name(data_registry, String(structure.get("definition_id", "")))
		var recipe := data_registry.get_definition(recipe_id)
		var duration := _get_recipe_duration(recipe)
		var progress_seconds := clampf(float(structure.get("progress_seconds", 0.0)), 0.0, duration)
		var recipe_name := _get_display_name(data_registry, recipe_id)
		if recipe_name.is_empty():
			recipe_name = "当前配方"
		return [
			"设备：%s -> %s" % [structure_name, recipe_name],
			"进度：%s %s/%s 秒；Q 设备面板" % [
				_format_progress_bar(progress_seconds, duration),
				_format_amount(progress_seconds),
				_format_amount(duration)
			]
		]
	return []


func _format_current_craft_summary(
	data_registry: DataRegistry,
	active_quest: Dictionary,
	character_state: CharacterState,
	world_state: WorldState
) -> Array[String]:
	var quest_id := String(active_quest.get("id", ""))
	var first_hour_summary := _format_first_hour_recommended_craft_summary(
		data_registry,
		quest_id,
		character_state,
		world_state
	)
	if not first_hour_summary.is_empty():
		return first_hour_summary

	for objective in active_quest.get("objectives", []):
		if not objective is Dictionary:
			continue
		if String(objective.get("type", "")) != "craft_item":
			continue
		var target_id := String(objective.get("target_id", ""))
		var required_amount := float(objective.get("amount", 1.0))
		if world_state.quest_state.get_objective_progress(quest_id, "craft_item", target_id) >= required_amount:
			continue
		var recipe := _find_recipe_for_output(data_registry, target_id)
		if recipe.is_empty():
			continue
		return _format_recipe_summary(data_registry, recipe, character_state, world_state, "可制造")
	return []


func _format_current_build_summary(
	data_registry: DataRegistry,
	active_quest: Dictionary,
	character_state: CharacterState,
	world_state: WorldState
) -> Array[String]:
	var quest_id := String(active_quest.get("id", ""))
	for objective in active_quest.get("objectives", []):
		if not objective is Dictionary:
			continue
		if String(objective.get("type", "")) != "build":
			continue
		var building_id := String(objective.get("target_id", ""))
		var required_amount := float(objective.get("amount", 1.0))
		var progress_amount := maxf(
			world_state.quest_state.get_objective_progress(quest_id, "build", building_id),
			float(world_state.count_base_structures(building_id))
		)
		if progress_amount >= required_amount:
			continue
		var building := data_registry.get_definition(building_id)
		if building.is_empty():
			continue
		var missing_costs := _format_missing_refs(data_registry, building.get("build_cost", []), character_state.inventory)
		var result: Array[String] = []
		if missing_costs.is_empty():
			result.append("可建造：%s" % _get_display_name(data_registry, building_id))
		else:
			result.append("待建造：%s；缺 %s" % [_get_display_name(data_registry, building_id), missing_costs])
		var purpose_hint := RecipePurposeHints.format_build_goal_hint(building_id)
		if not purpose_hint.is_empty():
			result.append("用途：%s" % purpose_hint)
		return result
	return []


func _format_first_hour_recommended_craft_summary(
	data_registry: DataRegistry,
	quest_id: String,
	character_state: CharacterState,
	world_state: WorldState
) -> Array[String]:
	match quest_id:
		"quest.make_filter_module":
			if not character_state.inventory.has_ref("item.filter_media", 1):
				return _format_recipe_summary(
					data_registry,
					data_registry.get_definition("recipe.make_filter_media"),
					character_state,
					world_state,
					"建议配方"
				)
		"quest.expand_treatment_point":
			var foundation_progress := maxf(
				world_state.quest_state.get_objective_progress(quest_id, "build", "building.foundation_t1"),
				float(world_state.count_base_structures("building.foundation_t1"))
			)
			var pending_foundations := maxi(0, 2 - int(foundation_progress))
			if _get_inventory_amount(character_state.inventory, "item.foundation_material") < float(pending_foundations):
				return _format_recipe_summary(
					data_registry,
					data_registry.get_definition("recipe.foundation_t1"),
					character_state,
					world_state,
					"建议配方"
				)
			if not world_state.has_base_structure_definition("building.pollution_filter"):
				if _get_build_cost_shortage("building.pollution_filter", "item.filter_media", data_registry, character_state) > 0.0:
					return _format_recipe_summary(
						data_registry,
						data_registry.get_definition("recipe.make_filter_media"),
						character_state,
						world_state,
						"建议配方"
					)
				if _get_build_cost_shortage("building.pollution_filter", "item.basic_parts", data_registry, character_state) > 0.0:
					return _format_recipe_summary(
						data_registry,
						data_registry.get_definition("recipe.process_crystal_ore"),
						character_state,
						world_state,
						"建议配方"
					)
		"quest.enter_pollution_edge":
			if _has_pollution_vial_ready(world_state, character_state):
				return [
					"外出链：带药剂回污染边界",
					"下一步：%s" % _format_pollution_vial_field_step(world_state)
				]
	return []


func _format_recipe_summary(
	data_registry: DataRegistry,
	recipe: Dictionary,
	character_state: CharacterState,
	world_state: WorldState,
	ready_prefix: String
) -> Array[String]:
	if recipe.is_empty():
		return []
	var recipe_id := String(recipe.get("id", ""))
	var missing_inputs := _format_missing_recipe_inputs(data_registry, recipe, character_state.inventory)
	var recipe_name := _get_display_name(data_registry, recipe_id)
	var building_name := _get_display_name(data_registry, String(recipe.get("required_building_id", "")))
	var line := "%s：%s（%s）" % [ready_prefix, recipe_name, building_name]
	if not missing_inputs.is_empty():
		line = "待制造：%s；缺 %s" % [recipe_name, missing_inputs]
	var result: Array[String] = [line]
	var output_summary := _format_refs(data_registry, recipe.get("outputs", []), "")
	if not output_summary.is_empty():
		result.append("完成后：获得 %s" % output_summary)
	var purpose_hint := RecipePurposeHints.format_recipe_goal_hint(recipe_id, world_state)
	if not purpose_hint.is_empty():
		result.append("用途：%s" % purpose_hint)
	var industrial_chain_hint := IndustrialTechSpineFormatter.format_recipe_chain_hint(
		recipe_id,
		world_state,
		character_state
	)
	if not industrial_chain_hint.is_empty():
		result.append("工艺主干：%s" % industrial_chain_hint)
	return result


func _get_build_cost_shortage(
	building_id: String,
	definition_id: String,
	data_registry: DataRegistry,
	character_state: CharacterState
) -> float:
	var building := data_registry.get_definition(building_id)
	for ref in building.get("build_cost", []):
		if not ref is Dictionary:
			continue
		if String(ref.get("id", "")) != definition_id:
			continue
		return maxf(0.0, float(ref.get("amount", 0.0)) - _get_inventory_amount(character_state.inventory, definition_id))
	return 0.0


func _find_recipe_for_output(data_registry: DataRegistry, target_id: String) -> Dictionary:
	if target_id.is_empty():
		return {}
	for recipe in data_registry.get_table("recipes"):
		if not recipe is Dictionary:
			continue
		for output_ref in recipe.get("outputs", []):
			if not output_ref is Dictionary:
				continue
			if String(output_ref.get("id", "")) == target_id:
				return recipe
	return {}


func _format_missing_recipe_inputs(data_registry: DataRegistry, recipe: Dictionary, inventory: InventoryState) -> String:
	return _format_missing_refs(data_registry, recipe.get("inputs", []), inventory)


func _format_missing_refs(data_registry: DataRegistry, refs: Array, inventory: InventoryState) -> String:
	var parts: Array[String] = []
	for ref in refs:
		if not ref is Dictionary:
			continue
		var definition_id := String(ref.get("id", ""))
		var required_amount := float(ref.get("amount", 0.0))
		if definition_id.is_empty() or required_amount <= 0.0:
			continue
		var shortage := required_amount - _get_inventory_amount(inventory, definition_id)
		if shortage <= 0.0:
			continue
		parts.append("%s x%s" % [_get_display_name(data_registry, definition_id), _format_amount(shortage)])
	if parts.is_empty():
		return ""
	return "，".join(parts)


func _format_refs(data_registry: DataRegistry, refs: Array, empty_text: String = "无") -> String:
	var parts: Array[String] = []
	for ref in refs:
		if not ref is Dictionary:
			continue
		var definition_id := String(ref.get("id", ""))
		var amount := float(ref.get("amount", 0.0))
		if definition_id.is_empty() or amount <= 0.0:
			continue
		parts.append("%s x%s" % [_get_display_name(data_registry, definition_id), _format_amount(amount)])
	if parts.is_empty():
		return empty_text
	return "，".join(parts)


func _format_equipment_summary(data_registry: DataRegistry, character_state: CharacterState) -> String:
	var parts: Array[String] = [
		_get_display_name(data_registry, String(character_state.equipment.get("tool", ""))),
		_get_display_name(data_registry, String(character_state.equipment.get("suit", "")))
	]
	var suit_module_id := String(character_state.equipment.get("suit_module", ""))
	if suit_module_id.is_empty():
		parts.append("未装模块")
	else:
		parts.append(_get_display_name(data_registry, suit_module_id))
	return "；".join(parts)


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
		var action_progress := BaseActionDispatchPlan.format_status_progress(world_state)
		if not action_progress.is_empty():
			return action_progress
		var next_sortie_route := CoreGuardAftermathFormatter.format_next_sortie_route_line(world_state)
		if not next_sortie_route.is_empty():
			return next_sortie_route
		if _has_completed_phase_survey_feedback(world_state):
			return "相位测绘选择闭环已完成；本轮验证了基地选择、两处前线读数和返回提示收益"
		if _has_completed_steady_supply_feedback(world_state):
			return "稳场补给选择闭环已完成；本轮验证了基地选择、低风险前线目标和返回补给收益"
		if _has_completed_route_action_feedback(world_state):
			return "巡线反馈已归档；回基地在行动选择台选择稳场补给、相位测绘或压力清障"
		if _has_completed_route_signal_marker(world_state):
			return "巡线信标读数已带回；回基地基础反应器解析成巡线反馈记录"
		if _has_completed_route_frontline_action(world_state):
			return "巡线短行动已确认；回到锚定桥前线读取巡线信标"
		if _has_completed_short_action_feedback(world_state):
			return "短行动反馈已归档，下一趟巡线目标已整理；回基地前线行动台确认第三条巡线短行动"
		if _has_completed_supply_return_marker(world_state):
			return "补给回执读数已带回；回基地基础反应器解析成短行动反馈记录"
		if _has_completed_supply_frontline_action(world_state):
			return "补给短行动已确认；回到锚定桥前线读取补给回执标记"
		if _has_completed_stability_echo_report(world_state):
			return "前线行动回报已归档，下一趟短行动补给已整理；回基地前线行动台确认第二条轻量行动"
		if _has_completed_stability_echo_probe(world_state):
			return "稳窗回波样本已带回；回基地基础反应器解析成前线行动回报"
		if _has_completed_stability_frontline_action(world_state):
			return "前线行动已确认；回到锚定桥东侧读取稳窗回波探点"
		if _has_completed_phase_well_stability_window_calibration(world_state):
			return "三处稳窗校准点已按顺序写入；回基地在前线行动台确认下一趟外出"
		if _has_completed_phase_well_echo_shard_analysis(world_state):
			return "稳窗读数已解析；返回锚定桥东侧按西侧、中央、东侧顺序校准稳窗节点"
		if _has_completed_phase_well_anchor_field(world_state):
			return "锚定桥东侧稳定窗口已生成；稳窗余响片已带回基地，解析后可校准为可回访的前线回稳点"
		if _has_completed_phase_well_tether(world_state):
			return "锚定桥已勘验；回基地解析稳场锚核后，可继续把锚定桥东侧改成新的短守场稳定窗口"
		if _has_completed_phase_well_frame(world_state):
			return "锁相框架已勘验；回基地解析锚定结核后，可继续把锚定桥转成新的推进包"
		if _has_completed_phase_well_loom(world_state):
			return "风蚀管廊已勘验；回基地解析锁相织构核后，可继续把锁相框架转成新的推进包"
		if _has_completed_phase_well_chamber(world_state):
			return "碎晶沟谷已勘验；回基地解析风蚀张力核后，可继续把风蚀管廊转成新的推进包"
		if _has_completed_phase_well_sink(world_state):
			return "盐壳浅滩已凿开；回基地解析碎晶心核后，可继续把碎晶沟谷转成新的推进包"
		if _has_completed_inner_phase_well(world_state):
			return "回声芯样本已回收；回基地解析后可继续把盐壳浅滩转成新的推进包"
		if _has_completed_phase_well_lock(world_state):
			return "锁相结构已钉住；先回基地解析定位器，再把更东侧回声台地真正转成新推进包"
		if _has_completed_phase_fault_spire(world_state):
			return "裂相尖塔已校准；回基地解析故障轨迹，继续把更东侧锁相结构变成新目标"
		if _has_completed_phase_relay_anchor(world_state):
			if world_state.current_region_id == "region.outpost_platform":
				return "基地相位回投台已锁定当前锚点；当前可按 E 回投返回裂相脊，并继续追踪更东侧裂相碎屑"
			return "基地与裂相脊之间的快速回传已上线；当前可从前线快速回基地，再用回投台重返更东侧裂相脊"
		if _has_completed_second_deep_pass(world_state):
			return "裂相读数矩阵已整理完成；返回裂相脊固定点即可部署前线回传锚点"
		if _has_completed_deep_ruin_entry(world_state):
			return "裂相样块已回收；回基地解析样块后可继续点亮裂相阵列"
		if _has_completed_deep_signal_analysis(world_state):
			return "封锁回波已转成可执行坐标，返回封锁遗迹最东侧即可写入裂相脊入口门禁"
		if _is_slice_complete(world_state):
			return "外圈中继已确认，裂相结构已定位"
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

	if quest_id == "quest.enter_pollution_edge" and _has_pollution_vial_objective_ready(world_state):
		parts.append(_format_pollution_action_chain_line())
	if parts.is_empty():
		return "无"
	return "；".join(parts)


func _format_active_quest_progress_lines(
	data_registry: DataRegistry,
	world_state: WorldState,
	quest_id: String
) -> Array[String]:
	var quest := data_registry.get_definition(quest_id)
	if quest.is_empty():
		var fallback_progress := _format_active_quest_progress(data_registry, world_state, quest_id)
		if fallback_progress == "无":
			return []
		return [_shorten_visible_text(fallback_progress, 42)]

	var lines: Array[String] = []
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
		lines.append(_shorten_visible_text("%s%s %s/%s" % [
			_get_objective_verb(objective_type),
			_format_objective_target_name(data_registry, quest_id, objective_type, target_id, true),
			_format_amount(current_amount),
			_format_amount(required_amount)
		], 42))
	if quest_id == "quest.enter_pollution_edge" and _has_pollution_vial_objective_ready(world_state):
		lines.append(_shorten_visible_text(_format_pollution_action_chain_line(), 42))
	return lines


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
		"clear":
			return "清理 "
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
	target_id: String,
	compact: bool = false
) -> String:
	var target_name := _get_display_name(data_registry, target_id)
	var source_hint := _get_objective_source_hint(quest_id, objective_type, target_id)
	if source_hint.is_empty():
		return target_name
	if compact:
		source_hint = _compact_source_hint(source_hint)
	return "%s（%s）" % [target_name, source_hint]


func _get_objective_source_hint(quest_id: String, objective_type: String, target_id: String) -> String:
	if objective_source_resolver == null:
		return ""
	if objective_type != "gather_item" and objective_type != "craft_item":
		return ""
	var contextual_source_hint := _get_contextual_objective_source_hint(quest_id, objective_type, target_id)
	if not contextual_source_hint.is_empty():
		return contextual_source_hint
	return objective_source_resolver.resolve_source_hint(objective_type, target_id)


func _get_contextual_objective_source_hint(quest_id: String, objective_type: String, target_id: String) -> String:
	if objective_type != "gather_item" or target_id != "item.polluted_residue":
		return ""
	match quest_id:
		"quest.salvage_signal_echo":
			return "污染回波沉积"
		"quest.prepare_demo_stabilization_buffer":
			return "核心缓冲补料沉积"
		_:
			return ""


func _has_pollution_vial_ready(world_state: WorldState, character_state: CharacterState) -> bool:
	if character_state != null and character_state.inventory.has_ref("item.resistance_vial_t1", 1):
		return true
	return _has_pollution_vial_objective_ready(world_state)


func _has_pollution_vial_objective_ready(world_state: WorldState) -> bool:
	return world_state.quest_state.get_objective_progress(
		"quest.enter_pollution_edge",
		"craft_item",
		"item.resistance_vial_t1"
	) >= 1.0


func _format_pollution_action_chain_line() -> String:
	return "链路：处理药剂->带药剂回污染边界->清理受扰敌人/门前压力点"


func _format_pollution_vial_field_step(world_state: WorldState) -> String:
	if world_state.quest_state.get_objective_progress("quest.enter_pollution_edge", "gather_item", "item.polluted_residue") < 4.0:
		return "补第二批沉积物，再清理受扰敌人和门前压力点"
	return "清理受扰敌人和门前压力点"


func _format_amount(amount: float) -> String:
	if is_equal_approx(amount, roundf(amount)):
		return str(int(amount))
	return "%.1f" % amount


func _compact_source_hint(source_hint: String) -> String:
	match source_hint:
		"基础反应器":
			return "反应器"
		"污染过滤器":
			return "过滤器"
		"异常残留点":
			return "残留点"
		_:
			return source_hint


func _format_progress_bar(current: float, total: float) -> String:
	var segment_count := 10
	var ratio := 0.0
	if total > 0.0:
		ratio = clampf(current / total, 0.0, 1.0)
	var filled_count := mini(segment_count, maxi(0, int(floor(ratio * float(segment_count)))))
	if ratio > 0.0 and filled_count == 0:
		filled_count = 1
	return "[%s%s]" % [
		_repeat_text("#", filled_count),
		_repeat_text("-", segment_count - filled_count)
	]


func _get_recipe_duration(recipe: Dictionary) -> float:
	if recipe.is_empty():
		return 0.1
	return maxf(0.1, float(recipe.get("duration", 0.1)))


func _repeat_text(text: String, count: int) -> String:
	var parts: Array[String] = []
	for _index in range(maxi(0, count)):
		parts.append(text)
	return "".join(parts)


func _shorten_visible_text(text: String, max_length: int) -> String:
	if text.length() <= max_length:
		return text
	return "%s..." % text.substr(0, maxi(0, max_length - 3))


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


func _has_completed_phase_relay_anchor(world_state: WorldState) -> bool:
	return world_state.quest_state.has_completed_quest("quest.deploy_phase_relay_anchor")


func _has_completed_phase_well_chamber(world_state: WorldState) -> bool:
	return world_state.quest_state.has_completed_quest("quest.inspect_phase_well_chamber")


func _has_completed_phase_well_tether(world_state: WorldState) -> bool:
	return world_state.quest_state.has_completed_quest("quest.inspect_phase_well_tether")


func _has_completed_phase_well_anchor_field(world_state: WorldState) -> bool:
	return world_state.quest_state.has_completed_quest("quest.stabilize_phase_well_anchor_field")


func _has_completed_phase_well_echo_shard_analysis(world_state: WorldState) -> bool:
	return world_state.quest_state.has_completed_quest("quest.analyze_phase_well_echo_shard")


func _has_completed_phase_well_stability_window_calibration(world_state: WorldState) -> bool:
	return world_state.quest_state.has_completed_quest("quest.calibrate_phase_well_stability_window")


func _has_completed_stability_frontline_action(world_state: WorldState) -> bool:
	return world_state.quest_state.has_completed_quest("quest.plan_stability_frontline_action")


func _has_completed_stability_echo_probe(world_state: WorldState) -> bool:
	return world_state.quest_state.has_completed_quest("quest.survey_stability_echo_probe")


func _has_completed_stability_echo_report(world_state: WorldState) -> bool:
	return world_state.quest_state.has_completed_quest("quest.analyze_stability_echo_sample")


func _has_completed_supply_frontline_action(world_state: WorldState) -> bool:
	return world_state.quest_state.has_completed_quest("quest.confirm_supply_frontline_action")


func _has_completed_supply_return_marker(world_state: WorldState) -> bool:
	return world_state.quest_state.has_completed_quest("quest.inspect_supply_return_marker")


func _has_completed_short_action_feedback(world_state: WorldState) -> bool:
	return world_state.quest_state.has_completed_quest("quest.analyze_supply_return_trace")


func _has_completed_route_frontline_action(world_state: WorldState) -> bool:
	return world_state.quest_state.has_completed_quest("quest.confirm_route_frontline_action")


func _has_completed_route_signal_marker(world_state: WorldState) -> bool:
	return world_state.quest_state.has_completed_quest("quest.inspect_route_signal_marker")


func _has_completed_route_action_feedback(world_state: WorldState) -> bool:
	return world_state.quest_state.has_completed_quest("quest.analyze_route_signal_trace")


func _has_completed_steady_supply_feedback(world_state: WorldState) -> bool:
	return world_state.quest_state.has_completed_quest("quest.analyze_steady_supply_trace")


func _has_completed_phase_survey_feedback(world_state: WorldState) -> bool:
	return world_state.quest_state.has_completed_quest("quest.analyze_phase_survey_trace")


func _has_completed_phase_well_frame(world_state: WorldState) -> bool:
	return world_state.quest_state.has_completed_quest("quest.inspect_phase_well_frame")


func _has_completed_phase_well_loom(world_state: WorldState) -> bool:
	return world_state.quest_state.has_completed_quest("quest.inspect_phase_well_loom")


func _has_completed_phase_well_sink(world_state: WorldState) -> bool:
	return world_state.quest_state.has_completed_quest("quest.inspect_phase_well_sink")


func _has_completed_phase_well_lock(world_state: WorldState) -> bool:
	return world_state.quest_state.has_completed_quest("quest.unlock_phase_well")


func _has_completed_phase_fault_spire(world_state: WorldState) -> bool:
	return world_state.quest_state.has_completed_quest("quest.inspect_phase_fault_spire")


func _has_completed_inner_phase_well(world_state: WorldState) -> bool:
	return world_state.quest_state.has_completed_quest("quest.inspect_inner_phase_well")


func _ensure_objective_source_resolver(data_registry: DataRegistry) -> void:
	if data_registry == null:
		objective_source_resolver = null
		objective_source_registry = null
		return
	if objective_source_resolver != null and objective_source_registry == data_registry:
		return
	objective_source_resolver = QuestObjectiveSourceResolver.new(data_registry)
	objective_source_registry = data_registry
