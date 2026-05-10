extends RefCounted

var host


func _init(check_host) -> void:
	host = check_host


func run_flow(world_state: WorldState, character_state: CharacterState) -> void:
	host._expect_active_quest("quest.analyze_phase_well_heart", "after phase well sink returns to heart analysis")
	host._complete_active_quest("quest.analyze_phase_well_heart", [{"type": "craft_item", "target_id": "item.phase_well_pulse_sheet", "amount": 1}])
	host._expect_active_quest("quest.collect_heart_spine", "after heart analysis returns to chamber edge")
	host._expect_array_has(world_state.unlocked_region_ids, "region.phase_well_chamber", "phase well heart analysis unlocks phase well chamber region")
	host._complete_active_quest("quest.collect_heart_spine", [
		{"type": "visit_region", "target_id": "region.phase_well_chamber", "amount": 1},
		{"type": "defeat_enemy", "target_id": "enemy.phase_well_reaver", "amount": 1},
		{"type": "gather_item", "target_id": "item.heart_spine", "amount": 2}
	])
	host._expect_active_quest("quest.refine_heart_spine", "after heart spine collection returns to filter")
	host._expect_array_has(world_state.quest_state.unlocked_effects, "recipe.heart_spine_stabilization", "heart spine collection unlocks stabilization recipe")
	host._complete_active_quest("quest.refine_heart_spine", [{"type": "craft_item", "target_id": "item.phase_well_damper", "amount": 1}])
	host._expect_active_quest("quest.assemble_phase_well_shunt", "after heart spine refinement returns to reactor")
	host._expect_array_has(world_state.quest_state.unlocked_effects, "recipe.phase_well_shunt", "heart spine refinement unlocks phase well shunt recipe")
	host._complete_active_quest("quest.assemble_phase_well_shunt", [{"type": "craft_item", "target_id": "item.phase_well_shunt", "amount": 1}])
	host._expect_active_quest("quest.inspect_phase_well_chamber", "after phase well shunt assembly returns to chamber")
	host._complete_active_quest("quest.inspect_phase_well_chamber", [{"type": "inspect", "target_id": "map_object.phase_well_chamber", "amount": 1}])
	host._expect_equal(world_state.quest_state.active_quest_ids, [], "after phase well chamber should have no active quest")
	host._expect_array_has(world_state.quest_state.completed_quest_ids, "quest.inspect_phase_well_chamber", "phase well chamber quest completed")
	host._expect_equal(int(character_state.inventory.items.get("item.phase_well_spindle", 0)), 1, "phase well chamber grants first spindle reward")


func run_hud_and_map_checks() -> void:
	_check_onboarding_hints()
	_check_status_panel_summary()
	_check_region_presence_bounds()
	_check_phase_well_chamber_gate()


func _check_onboarding_hints() -> void:
	var presenter := HudHintPresenter.new()
	var hint_world := WorldState.create_default()
	var hint_character := CharacterState.create_default()
	var heart_completion_world := WorldState.create_default()
	heart_completion_world.quest_state.active_quest_ids.clear()
	heart_completion_world.quest_state.completed_quest_ids.append("quest.inspect_phase_well_sink")
	host._expect_text_contains(presenter.format_direction_hint(heart_completion_world, hint_character, ""), "回基地解析心核", "phase well heart completion direction highlights next base analysis")
	host._expect_text_contains(presenter.format_onboarding_hint(heart_completion_world, hint_character, ""), "相位井心核不是收尾", "phase well heart completion onboarding keeps next package explicit")
	host._expect_hint_contains(presenter, hint_world, hint_character, "quest.analyze_phase_well_heart", "脉搏片", "phase well heart analysis onboarding hint")
	host._expect_hint_contains(presenter, hint_world, hint_character, "quest.collect_heart_spine", "心棘残片", "heart spine collection onboarding hint")
	host._expect_hint_contains(presenter, hint_world, hint_character, "quest.refine_heart_spine", "污染过滤器", "heart spine refinement onboarding hint")
	host._expect_hint_contains(presenter, hint_world, hint_character, "quest.assemble_phase_well_shunt", "井心分流栓", "phase well shunt assembly onboarding hint")
	host._expect_hint_contains(presenter, hint_world, hint_character, "quest.inspect_phase_well_chamber", "井心分流栓", "phase well chamber onboarding hint")
	var chamber_completion_world := WorldState.create_default()
	chamber_completion_world.quest_state.active_quest_ids.clear()
	chamber_completion_world.quest_state.completed_quest_ids.append("quest.inspect_phase_well_chamber")
	host._expect_text_contains(presenter.format_direction_hint(chamber_completion_world, hint_character, ""), "相位井纺核", "phase well chamber completion direction summarizes latest reward anchor")
	host._expect_text_contains(presenter.format_onboarding_hint(chamber_completion_world, hint_character, ""), "相位井纺核已经带回基地", "phase well chamber completion onboarding summarizes latest reward anchor")


func _check_status_panel_summary() -> void:
	var presenter := HudStatusPresenter.new()
	var status_character := CharacterState.create_default()
	var phase_well_sink_text_world := WorldState.create_default()
	phase_well_sink_text_world.quest_state.active_quest_ids.clear()
	phase_well_sink_text_world.quest_state.completed_quest_ids.append("quest.inspect_phase_well_sink")
	var phase_well_sink_text := presenter.format_status_text(host.data_registry, phase_well_sink_text_world, status_character)
	host._expect_text_contains(phase_well_sink_text, "目标：相位井心核待解析", "status falls back to phase well heart analysis after sink")
	host._expect_text_contains(phase_well_sink_text, "回基地解析相位井心核后", "status progress keeps phase well heart followup summary")
	var phase_well_chamber_text_world := WorldState.create_default()
	phase_well_chamber_text_world.quest_state.active_quest_ids.clear()
	phase_well_chamber_text_world.quest_state.completed_quest_ids.append("quest.inspect_phase_well_chamber")
	var phase_well_chamber_text := presenter.format_status_text(host.data_registry, phase_well_chamber_text_world, status_character)
	host._expect_text_contains(phase_well_chamber_text, "目标：相位井纺核已带回", "status falls back to phase well spindle summary after chamber")
	host._expect_text_contains(phase_well_chamber_text, "井心室断面已勘验", "status progress keeps phase well chamber summary")


func _check_region_presence_bounds() -> void:
	var map := VerticalSliceMap.new()
	host._expect_equal(map._get_region_id_for_position(Vector2(2282, -18)), "region.phase_well_chamber", "phase well chamber should sit in the new eastern chamber region")
	map.free()


func _check_phase_well_chamber_gate() -> void:
	var map := VerticalSliceMap.new()
	map.player = PlayerController.new()
	var chamber_gate_world := WorldState.create_default()
	chamber_gate_world.unlock_region("region.crystal_vein_field")
	chamber_gate_world.unlock_region("region.pollution_edge")
	chamber_gate_world.unlock_region("region.ruin_outer_ring")
	chamber_gate_world.unlock_region("region.deep_ruin_threshold")
	chamber_gate_world.unlock_region("region.inner_phase_well")
	chamber_gate_world.unlock_region("region.phase_well_sink")
	chamber_gate_world.quest_state.completed_quest_ids.append("quest.stabilize_outer_ring_barrier")
	chamber_gate_world.quest_state.completed_quest_ids.append("quest.unlock_deep_ruin_entrance")
	var chamber_gate_character := CharacterState.create_default()
	map.last_reported_region_id = chamber_gate_world.current_region_id
	map.player.position = Vector2(2106, -96)
	map.update_region_presence(chamber_gate_world, chamber_gate_character)
	host._expect_equal(map.player.position.x, 2012.0, "locked phase well chamber should push player before chamber region")
	host._expect_equal(chamber_gate_world.current_region_id, "region.phase_well_sink", "locked phase well chamber should keep sink region")
	var unlocked_chamber_world := WorldState.create_default()
	unlocked_chamber_world.unlock_region("region.crystal_vein_field")
	unlocked_chamber_world.unlock_region("region.pollution_edge")
	unlocked_chamber_world.unlock_region("region.ruin_outer_ring")
	unlocked_chamber_world.unlock_region("region.deep_ruin_threshold")
	unlocked_chamber_world.unlock_region("region.inner_phase_well")
	unlocked_chamber_world.unlock_region("region.phase_well_sink")
	unlocked_chamber_world.unlock_region("region.phase_well_chamber")
	unlocked_chamber_world.quest_state.completed_quest_ids.append("quest.stabilize_outer_ring_barrier")
	unlocked_chamber_world.quest_state.completed_quest_ids.append("quest.unlock_deep_ruin_entrance")
	var unlocked_chamber_character := CharacterState.create_default()
	map.last_reported_region_id = unlocked_chamber_world.current_region_id
	map.player.position = Vector2(2106, -96)
	map.update_region_presence(unlocked_chamber_world, unlocked_chamber_character)
	host._expect_equal(unlocked_chamber_world.current_region_id, "region.phase_well_chamber", "unlocked phase well chamber should update current region")
	map.player.free()
	map.free()
