extends SceneTree
const VerticalSliceMapScene := preload("res://scenes/maps/VerticalSliceMap.tscn")
var failures: Array[String] = []
var data_registry := DataRegistry.new()
func _init() -> void:
	_run_checks()
	if failures.is_empty():
		print("Onboarding hint runtime checks passed.")
		_cleanup()
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	_cleanup()
	quit(1)
func _run_checks() -> void:
	if not data_registry.load_all():
		failures.append("data registry should load all static data")
		return
	_check_onboarding_hints()
func _check_onboarding_hints() -> void:
	var presenter := HudHintPresenter.new()
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	presenter.configure(data_registry, map)
	var hint_world := WorldState.create_default()
	var hint_character := CharacterState.create_default()
	_expect_hint_contains(presenter, hint_world, hint_character, "quest.restore_outpost", "前哨核心", "restore outpost onboarding hint")
	hint_world.current_region_id = "region.crystal_vein_field"
	_expect_hint_contains(presenter, hint_world, hint_character, "quest.scout_crystal_field", "采集晶体簇", "crystal field onboarding hint")
	_expect_hint_contains(presenter, hint_world, hint_character, "quest.calibrate_reactor", "外勤残骸", "calibration onboarding hint")
	_expect_hint_contains(presenter, hint_world, hint_character, "quest.prepare_treatment_supplies", "修复凝胶", "supply prep onboarding hint")
	hint_world.quest_state.set_objective_progress("quest.prepare_treatment_supplies", "craft_item", "item.repair_gel", 1)
	_expect_text_contains(
		presenter.format_direction_hint(hint_world, hint_character, "quest.prepare_treatment_supplies"),
		"快捷栏 1",
		"supply prep direction mentions quick slot"
	)
	_expect_hint_contains(presenter, hint_world, hint_character, "quest.prepare_treatment_supplies", "生命偏低", "supply prep combat use hint")
	_expect_text_contains(
		presenter.format_direction_hint(hint_world, hint_character, "quest.prepare_treatment_supplies"),
		"处理点北缘",
		"supply prep direction follows treatment point combat region"
	)
	_expect_hint_contains(presenter, hint_world, hint_character, "quest.expand_treatment_point", "一块粗糙地面", "rough ground onboarding hint")
	hint_world.quest_state.set_objective_progress("quest.expand_treatment_point", "clear", "map_object.rough_ground", 1)
	_expect_hint_contains(presenter, hint_world, hint_character, "quest.expand_treatment_point", "基础地基", "foundation onboarding hint")
	_expect_text_contains(
		presenter.format_direction_hint(hint_world, hint_character, "quest.expand_treatment_point"),
		"处理点北缘",
		"expand treatment point direction uses treatment point wording"
	)
	hint_world.add_base_structure("structure.foundation_site_north", "building.foundation_t1", "region.pollution_edge")
	hint_world.add_base_structure("structure.foundation_site_south", "building.foundation_t1", "region.pollution_edge")
	_expect_hint_contains(presenter, hint_world, hint_character, "quest.expand_treatment_point", "污染过滤器", "pollution filter onboarding hint")
	hint_character.equipment["suit_module"] = "equipment.filter_module_t1"
	hint_world.unlock_region("region.pollution_edge")
	hint_world.quest_state.set_objective_progress("quest.enter_pollution_edge", "visit_region", "region.pollution_edge", 1)
	hint_world.quest_state.set_objective_progress("quest.enter_pollution_edge", "gather_item", "item.polluted_residue", 2)
	_expect_text_contains(
		presenter.format_direction_hint(hint_world, hint_character, "quest.enter_pollution_edge"),
		"处理点过滤器",
		"enter pollution direction returns to filter when vial crafting is next"
	)
	_expect_hint_contains(
		presenter,
		hint_world,
		hint_character,
		"quest.enter_pollution_edge",
		"抗污染药剂",
		"enter pollution onboarding returns to filter before pushing deeper"
	)
	hint_character.protection = 30.0
	hint_world.quest_state.set_objective_progress("quest.enter_pollution_edge", "craft_item", "item.resistance_vial_t1", 1)
	_expect_hint_contains(presenter, hint_world, hint_character, "quest.enter_pollution_edge", "过滤器处理沉积物", "low protection onboarding hint")
	_expect_hint_contains(presenter, hint_world, hint_character, "quest.defeat_elite_node", "维持防护", "elite node supply hint")
	hint_world.unlock_region("region.ruin_outer_ring")
	_expect_hint_contains(presenter, hint_world, hint_character, "quest.scout_ruin_outer_ring", "继电残片", "outer ring scouting hint")
	_expect_hint_contains(presenter, hint_world, hint_character, "quest.assemble_phase_anchor", "污染浆液", "phase anchor assembly hint")
	_expect_hint_contains(presenter, hint_world, hint_character, "quest.stabilize_outer_ring_barrier", "稳相信标", "outer ring barrier hint")
	var echo_direction_world := WorldState.create_default()
	echo_direction_world.quest_state.active_quest_ids = ["quest.salvage_signal_echo"]
	echo_direction_world.quest_state.set_objective_progress("quest.salvage_signal_echo", "defeat_enemy", "enemy.ruin_phase_guard", 1)
	echo_direction_world.quest_state.set_objective_progress("quest.salvage_signal_echo", "gather_item", "item.polluted_residue", 2)
	var echo_direction_character := CharacterState.create_default()
	echo_direction_character.inventory.add_item("item.polluted_residue", 2)
	_expect_text_contains(
		presenter.format_direction_hint(echo_direction_world, echo_direction_character, "quest.salvage_signal_echo"),
		"先回处理点污染过滤器处理",
		"signal echo direction returns to filter before cache when residue is unprocessed"
	)
	echo_direction_character.inventory.items.erase("item.polluted_residue")
	echo_direction_character.inventory.add_fluid("fluid.polluted_slurry", 1.0)
	_expect_text_contains(
		presenter.format_direction_hint(echo_direction_world, echo_direction_character, "quest.salvage_signal_echo"),
		"回收封锁回波匣",
		"signal echo direction returns to cache after slurry is ready"
	)
	_expect_hint_contains(presenter, hint_world, hint_character, "quest.salvage_signal_echo", "回波匣", "signal echo salvage hint")
	_expect_hint_contains(presenter, hint_world, hint_character, "quest.analyze_deep_signal", "裂相坐标", "deep signal analysis hint")
	_expect_hint_contains(presenter, hint_world, hint_character, "quest.unlock_deep_ruin_entrance", "门禁", "deep ruin entrance hint")
	_expect_hint_contains(presenter, hint_world, hint_character, "quest.harvest_phase_filament", "相位纤丝", "phase filament salvage hint")
	_expect_hint_contains(presenter, hint_world, hint_character, "quest.refine_phase_filament", "污染过滤器", "phase filament filter hint")
	_expect_hint_contains(presenter, hint_world, hint_character, "quest.assemble_deep_override", "污染浆液", "deep override assembly hint")
	_expect_hint_contains(presenter, hint_world, hint_character, "quest.unlock_deep_ruin_cache", "裂相收益", "deep ruin latch hint")
	_expect_hint_contains(presenter, hint_world, hint_character, "quest.analyze_deep_core", "路由印片", "deep core analysis hint")
	_expect_hint_contains(presenter, hint_world, hint_character, "quest.activate_deep_array", "相位导管", "deep array activation hint")
	_expect_hint_contains(presenter, hint_world, hint_character, "quest.assemble_deep_signal_matrix", "读数矩阵", "deep signal matrix assembly hint")
	_expect_hint_contains(presenter, hint_world, hint_character, "quest.deploy_phase_relay_anchor", "回传锚点", "phase relay anchor deployment hint")
	hint_world.current_region_id = "region.outpost_platform"
	_expect_text_contains(
		presenter.format_direction_hint(hint_world, hint_character, "quest.reenter_phase_frontline"),
		"相位回投台",
		"relay reentry direction returns to outpost relay pad"
	)
	_expect_hint_contains(presenter, hint_world, hint_character, "quest.reenter_phase_frontline", "回投台", "relay reentry onboarding hint")
	hint_world.current_region_id = "region.deep_ruin_threshold"
	_expect_text_contains(
		presenter.format_direction_hint(hint_world, hint_character, "quest.trace_phase_splinters"),
		"裂相猎手",
		"phase splinter tracing direction points to new deep hunter"
	)
	_expect_hint_contains(presenter, hint_world, hint_character, "quest.refine_phase_splinters", "污染过滤器", "phase splinter refinement hint")
	hint_character.inventory.add_item("item.phase_lens_blank", 1)
	hint_character.inventory.add_fluid("fluid.polluted_slurry", 1.0)
	_expect_text_contains(
		presenter.format_direction_hint(hint_world, hint_character, "quest.refine_phase_splinters"),
		"基础反应器",
		"phase splinter expedition prep second step returns to reactor"
	)
	_expect_hint_contains(presenter, hint_world, hint_character, "quest.inspect_phase_fault_spire", "中继调谐镜", "phase fault spire onboarding hint")
	_expect_text_contains(
		presenter.format_direction_hint(hint_world, hint_character, "quest.analyze_inner_fault_trace"),
		"基础反应器",
		"inner fault analysis direction returns to reactor"
	)
	_expect_hint_contains(presenter, hint_world, hint_character, "quest.analyze_inner_fault_trace", "坐标印片", "inner fault analysis onboarding hint")
	_expect_hint_contains(presenter, hint_world, hint_character, "quest.collect_fault_residue", "故障残渣", "fault residue collection onboarding hint")
	_expect_hint_contains(presenter, hint_world, hint_character, "quest.refine_fault_residue", "裂相锁钥", "phase well key prep onboarding hint")
	_expect_hint_contains(presenter, hint_world, hint_character, "quest.unlock_phase_well", "裂相锁钥", "phase well lock onboarding hint")
	hint_world.quest_state.completed_quest_ids.append("quest.analyze_deep_signal")
	hint_world.quest_state.completed_quest_ids.append("quest.unlock_deep_ruin_cache")
	hint_world.quest_state.completed_quest_ids.append("quest.assemble_deep_signal_matrix")
	hint_world.quest_state.completed_quest_ids.append("quest.deploy_phase_relay_anchor")
	hint_world.quest_state.unlocked_effects.append("slice_01_complete")
	hint_world.current_region_id = "region.outpost_platform"
	_expect_text_contains(presenter.format_direction_hint(hint_world, hint_character, ""), "相位回投台", "phase relay completion direction returns to relay pad")
	_expect_text_contains(presenter.format_onboarding_hint(hint_world, hint_character, ""), "相位回投台", "phase relay completion onboarding points to relay pad")
	_expect_hint_contains(presenter, hint_world, hint_character, "", "回传锚点", "phase relay completion onboarding hint")
	var spire_completion_world := WorldState.create_default()
	spire_completion_world.quest_state.active_quest_ids.clear()
	spire_completion_world.quest_state.completed_quest_ids.append("quest.inspect_phase_fault_spire")
	_expect_text_contains(
		presenter.format_direction_hint(spire_completion_world, hint_character, ""),
		"锁相结构",
		"phase fault spire completion direction points to phase well lock"
	)
	_expect_text_contains(
		presenter.format_onboarding_hint(spire_completion_world, hint_character, ""),
		"内层故障轨迹",
		"phase fault spire completion onboarding points to base analysis"
	)
	var phase_well_world := WorldState.create_default()
	phase_well_world.quest_state.active_quest_ids.clear()
	phase_well_world.quest_state.completed_quest_ids.append("quest.unlock_phase_well")
	_expect_text_contains(
		presenter.format_direction_hint(phase_well_world, hint_character, ""),
		"回基地解析定位器",
		"phase well completion direction highlights base analysis followup"
	)
	_expect_text_contains(
		presenter.format_onboarding_hint(phase_well_world, hint_character, ""),
		"先回基地解析它",
		"phase well completion onboarding keeps locator analysis explicit"
	)
	var inner_phase_well_world := WorldState.create_default()
	inner_phase_well_world.quest_state.active_quest_ids.clear()
	inner_phase_well_world.quest_state.completed_quest_ids.append("quest.inspect_inner_phase_well")
	_expect_text_contains(
		presenter.format_direction_hint(inner_phase_well_world, hint_character, ""),
		"回基地解析回声芯样本",
		"inner phase well completion direction highlights next base analysis"
	)
	_expect_text_contains(
		presenter.format_onboarding_hint(inner_phase_well_world, hint_character, ""),
		"回声芯样本只是下一轮的起点",
		"inner phase well completion onboarding keeps next package explicit"
	)
	map.free()
func _expect_hint_contains(
	presenter: HudHintPresenter,
	hint_world: WorldState,
	hint_character: CharacterState,
	quest_id: String,
	expected_text: String,
	label: String
) -> void:
	var hint := presenter.format_onboarding_hint(hint_world, hint_character, quest_id)
	if hint.find(expected_text) < 0:
		failures.append("%s should contain %s, got %s" % [label, expected_text, hint])
func _expect_text_contains(text: String, expected_text: String, label: String) -> void:
	if text.find(expected_text) < 0:
		failures.append("%s should contain %s, got %s" % [label, expected_text, text])
func _cleanup() -> void:
	data_registry.free()
