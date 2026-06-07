extends RefCounted

var host


func _init(check_host) -> void:
	host = check_host


func run() -> void:
	var processing := ProcessingSystem.new(host.data_registry)
	_check_phase_filament_refining(processing)
	_check_phase_splinter_refining(processing)
	_check_reclaim_basic_parts(processing)
	_check_phase_anchor_reclaim_hint(processing)
	_check_core_stabilization_buffer(processing)
	_check_relay_tuning_lens(processing)
	_check_salt_flat_readability(processing)
	_check_shattered_ravine_readability(processing)
	_check_wind_conduit_readability(processing)
	_check_phase_lock_frame_readability(processing)
	_check_completed_deep_signal_matrix_refreshes_anchor()


func _check_core_stabilization_buffer(processing: ProcessingSystem) -> void:
	host._expect_text_contains(
		RecipePurposeHints.format_recipe_goal_hint("recipe.core_stabilization_buffer"),
		"核心守卫第一段回写压力",
		"core buffer purpose points to guard pressure"
	)
	var world := WorldState.create_default()
	world.quest_state.completed_quest_ids.append("quest.enter_demo_stabilization_core")
	world.quest_state.active_quest_ids = ["quest.prepare_demo_stabilization_buffer"]
	world.quest_state.unlock_effect("recipe.core_stabilization_buffer")
	world.add_base_structure("structure.basic_reactor", "building.basic_reactor", "region.outpost_platform")
	var missing_character := CharacterState.create_default()
	missing_character.inventory.items.erase("item.repair_gel")
	var missing_status := processing.get_recipe_status("recipe.core_stabilization_buffer", missing_character, world)
	host._expect_text_contains(String(missing_status.get("supply_hint", "")), "修复凝胶不足", "core buffer missing repair gel hint")
	var missing_slurry_character := CharacterState.create_default()
	missing_slurry_character.inventory.add_item("item.basic_parts", 2)
	missing_slurry_character.inventory.add_item("item.repair_gel", 1)
	missing_slurry_character.inventory.add_item("item.resistance_vial_t1", 1)
	var missing_slurry_status := processing.get_recipe_status("recipe.core_stabilization_buffer", missing_slurry_character, world)
	host._expect_text_contains(String(missing_slurry_status.get("supply_hint", "")), "污染浆液不足", "core buffer missing slurry hint")
	var reactor := PrototypeInteractable.new()
	reactor.definition_id = "building.basic_reactor"
	reactor.interaction_type = "process_recipe"
	reactor.recipe_id = "recipe.core_stabilization_buffer"
	reactor.set_recipe_cycle(["recipe.core_stabilization_buffer", "recipe.reclaim_basic_parts", "recipe.process_crystal_ore"])
	world.quest_state.unlock_effect("recipe.reclaim_basic_parts")
	var missing_parts_character := CharacterState.create_default()
	missing_parts_character.inventory.add_item("item.repair_gel", 1)
	missing_parts_character.inventory.add_item("item.resistance_vial_t1", 1)
	missing_parts_character.inventory.add_fluid("fluid.polluted_slurry", 1.0)
	missing_parts_character.inventory.items["item.basic_parts"] = 0
	host._expect_equal(
		processing.get_recommended_recipe_id(reactor, missing_parts_character, world),
		"recipe.process_crystal_ore",
		"core buffer prep preserves required slurry when only basic parts are missing"
	)
	missing_parts_character.inventory.add_fluid("fluid.polluted_slurry", 1.0)
	host._expect_equal(
		processing.get_recommended_recipe_id(reactor, missing_parts_character, world),
		"recipe.reclaim_basic_parts",
		"core buffer prep uses extra slurry for basic parts"
	)
	reactor.free()
	var character := CharacterState.create_default()
	character.inventory.add_item("item.basic_parts", 2)
	character.inventory.add_item("item.repair_gel", 1)
	character.inventory.add_item("item.resistance_vial_t1", 1)
	character.inventory.add_fluid("fluid.polluted_slurry", 1.0)
	var start := processing.process_recipe("recipe.core_stabilization_buffer", character, world)
	host._expect_equal(bool(start.get("success", false)), true, "core buffer processing starts")
	var completed := processing.advance_processing(8.0, character, world)
	host._expect_equal(completed.size(), 1, "core buffer processing completes")
	host._expect_equal(int(character.inventory.items.get("item.core_stabilization_buffer", 0)), 1, "core buffer processing grants item")
	host._expect_equal(float(character.inventory.fluids.get("fluid.polluted_slurry", 0.0)), 0.0, "core buffer processing consumes polluted slurry")
	host._expect_text_contains(String(completed[0].get("next_step_text", "")), "带回核心稳定站挑战阶段守卫", "core buffer completion points back to guard")


func _check_completed_deep_signal_matrix_refreshes_anchor() -> void:
	var world := WorldState.create_default()
	world.unlock_region("region.deep_ruin_threshold")
	world.current_region_id = "region.deep_ruin_threshold"
	world.quest_state.active_quest_ids = ["quest.assemble_deep_signal_matrix"]
	world.quest_state.unlock_effect("recipe.deep_signal_matrix")
	world.set_base_structure_status("structure.basic_reactor", "in_progress", "recipe.deep_signal_matrix")
	var character := CharacterState.create_default()
	character.current_region_id = "region.deep_ruin_threshold"
	character.position = Vector2(854, 96)
	var processing := ProcessingSystem.new(host.data_registry)
	var completed := processing.advance_processing(20.0, character, world)
	host._expect_equal(completed.size(), 1, "deep signal matrix processing should complete")
	var quest_runtime := QuestRuntime.new(host.data_registry)
	if not completed.is_empty():
		quest_runtime.advance_for_interaction(
			world,
			character,
			{
				"definition_id": "building.basic_reactor",
				"interaction_type": "process_recipe",
				"recipe_id": "recipe.deep_signal_matrix"
			},
			completed[0]
		)
	host._expect_array_has(world.quest_state.active_quest_ids, "quest.deploy_phase_relay_anchor", "deep signal matrix completion activates anchor deployment")


func _check_phase_filament_refining(processing: ProcessingSystem) -> void:
	var world := _create_filter_world("recipe.phase_filament_refining")
	var character := CharacterState.create_default()
	character.inventory.add_item("item.phase_filament", 2)
	var start := processing.process_recipe("recipe.phase_filament_refining", character, world)
	host._expect_equal(bool(start.get("success", false)), true, "phase filament refining should start")
	var completed := processing.advance_processing(20.0, character, world)
	host._expect_equal(completed.size(), 1, "phase filament refining should complete")
	if not completed.is_empty():
		host._expect_text_contains(String(completed[0].get("message", "")), "谐振滤芯 x1", "phase filament refining completion log output destination")
		host._expect_text_contains(String(completed[0].get("message", "")), "污染浆液 x2", "phase filament refining completion log byproduct destination")
	host._expect_equal(int(character.inventory.items.get("item.resonance_filter", 0)), 1, "phase filament refining grants resonance filter")
	host._expect_equal(float(character.inventory.fluids.get("fluid.polluted_slurry", 0.0)), 2.0, "phase filament refining grants enough polluted slurry for deep chain")


func _check_phase_splinter_refining(processing: ProcessingSystem) -> void:
	var world := _create_filter_world("recipe.phase_splinter_refining")
	var character := CharacterState.create_default()
	character.inventory.add_item("item.phase_splinter", 2)
	var start := processing.process_recipe("recipe.phase_splinter_refining", character, world)
	host._expect_equal(bool(start.get("success", false)), true, "phase splinter refining should start")
	var completed := processing.advance_processing(20.0, character, world)
	host._expect_equal(completed.size(), 1, "phase splinter refining should complete")
	if not completed.is_empty():
		host._expect_text_contains(String(completed[0].get("message", "")), "透镜胚片 x1", "phase splinter refining completion log output destination")
		host._expect_text_contains(String(completed[0].get("message", "")), "污染浆液 x1", "phase splinter refining completion log byproduct destination")
		host._expect_text_contains(String(completed[0].get("message", "")), "中继调谐镜", "phase splinter refining completion log next step")
	host._expect_equal(int(character.inventory.items.get("item.phase_lens_blank", 0)), 1, "phase splinter refining grants lens blank")
	host._expect_equal(float(character.inventory.fluids.get("fluid.polluted_slurry", 0.0)), 1.0, "phase splinter refining grants polluted slurry byproduct")
	var status := processing.get_recipe_status("recipe.phase_splinter_refining", character, world)
	host._expect_text_contains(String(status.get("last_next_step", "")), "中继调谐镜", "phase splinter refining panel next step")


func _check_reclaim_basic_parts(processing: ProcessingSystem) -> void:
	var world := WorldState.create_default()
	world.quest_state.unlock_effect("recipe.reclaim_basic_parts")
	var character := CharacterState.create_default()
	character.inventory.items["item.basic_parts"] = 0
	character.inventory.add_fluid("fluid.polluted_slurry", 1.0)
	var start := processing.process_recipe("recipe.reclaim_basic_parts", character, world)
	host._expect_equal(bool(start.get("success", false)), true, "basic parts reclaim processing should start")
	var completed := processing.advance_processing(20.0, character, world)
	host._expect_equal(completed.size(), 1, "basic parts reclaim processing should complete")
	if not completed.is_empty():
		host._expect_text_contains(String(completed[0].get("message", "")), "基础零件 x2", "basic parts reclaim completion log output destination")
		host._expect_text_contains(String(completed[0].get("message", "")), "副产物不再只是库存负担", "basic parts reclaim completion log next step")
	host._expect_equal(int(character.inventory.items.get("item.basic_parts", 0)), 2, "basic parts reclaim grants reusable parts")
	host._expect_equal(float(character.inventory.fluids.get("fluid.polluted_slurry", 0.0)), 0.0, "basic parts reclaim consumes polluted slurry")


func _check_phase_anchor_reclaim_hint(processing: ProcessingSystem) -> void:
	var world := WorldState.create_default()
	world.quest_state.unlock_effect("recipe.phase_anchor")
	var character := CharacterState.create_default()
	character.inventory.add_item("item.relay_shard", 2)
	character.inventory.add_fluid("fluid.polluted_slurry", 1.0)
	character.inventory.items["item.basic_parts"] = 1
	var status := processing.get_recipe_status("recipe.phase_anchor", character, world)
	host._expect_text_contains(
		String(status.get("supply_hint", "")),
		"先把一份污染浆液回收成基础零件",
		"phase anchor missing basic parts points to slurry reclaim"
	)


func _check_relay_tuning_lens(processing: ProcessingSystem) -> void:
	var world := WorldState.create_default()
	var character := CharacterState.create_default()
	world.quest_state.unlock_effect("recipe.relay_tuning_lens")
	character.inventory.add_item("item.phase_lens_blank", 1)
	character.inventory.add_fluid("fluid.polluted_slurry", 1.0)
	character.inventory.items["item.basic_parts"] = 2
	var start := processing.process_recipe("recipe.relay_tuning_lens", character, world)
	host._expect_equal(bool(start.get("success", false)), true, "relay tuning lens processing should start")
	var completed := processing.advance_processing(20.0, character, world)
	host._expect_equal(completed.size(), 1, "relay tuning lens processing should complete")
	if not completed.is_empty():
		host._expect_text_contains(String(completed[0].get("message", "")), "中继调谐镜 x1", "relay tuning lens completion log output destination")
		host._expect_text_contains(String(completed[0].get("message", "")), "裂相尖塔", "relay tuning lens completion log next step")
	host._expect_equal(int(character.inventory.items.get("item.relay_tuning_lens", 0)), 1, "relay tuning lens grants calibration item")
	var status := processing.get_recipe_status("recipe.relay_tuning_lens", character, world)
	host._expect_text_contains(String(status.get("last_next_step", "")), "裂相尖塔", "relay tuning lens panel next step")


func _check_salt_flat_readability(processing: ProcessingSystem) -> void:
	host._expect_text_contains(processing._get_completion_next_step("recipe.phase_well_core_analysis"), "盐壳硬壳", "phase well core completion points to salt crust clearing")
	host._expect_text_contains(RecipePurposeHints.format_recipe_goal_hint("recipe.well_ash_stabilization"), "盐壳穿钉", "well ash purpose points to pike assembly")
	host._expect_text_contains(RecipePurposeHints.format_recipe_goal_hint("recipe.phase_well_pike"), "碎晶心核", "phase well pike purpose points to heart reward")
	var ash_world := _create_filter_world("recipe.well_ash_stabilization")
	var ash_status := processing.get_recipe_status("recipe.well_ash_stabilization", CharacterState.create_default(), ash_world)
	host._expect_text_contains(String(ash_status.get("supply_hint", "")), "盐壳硬壳", "well ash missing input points to crust clearing")
	var pike_world := WorldState.create_default()
	pike_world.quest_state.unlock_effect("recipe.phase_well_pike")
	pike_world.add_base_structure("structure.basic_reactor", "building.basic_reactor", "region.outpost_platform")
	var pike_status := processing.get_recipe_status("recipe.phase_well_pike", CharacterState.create_default(), pike_world)
	host._expect_text_contains(String(pike_status.get("supply_hint", "")), "解析回声芯样本", "phase well pike missing spectrum points to core analysis")
	var pike_character := CharacterState.create_default()
	pike_character.inventory.add_item("item.phase_well_spectrum", 1)
	pike_status = processing.get_recipe_status("recipe.phase_well_pike", pike_character, pike_world)
	host._expect_text_contains(String(pike_status.get("supply_hint", "")), "稳定盐壳余烬", "phase well pike missing lattice points to ash stabilization")


func _check_shattered_ravine_readability(processing: ProcessingSystem) -> void:
	host._expect_text_contains(processing._get_completion_next_step("recipe.phase_well_heart_analysis"), "碎晶分流读数", "phase well heart completion points to shunt readings")
	host._expect_text_contains(RecipePurposeHints.format_recipe_goal_hint("recipe.heart_spine_stabilization"), "碎晶分流栓", "heart spine purpose points to shunt assembly")
	host._expect_text_contains(RecipePurposeHints.format_recipe_goal_hint("recipe.phase_well_shunt"), "风蚀张力核", "phase well shunt purpose points to spindle reward")
	var spine_world := _create_filter_world("recipe.heart_spine_stabilization")
	var spine_status := processing.get_recipe_status("recipe.heart_spine_stabilization", CharacterState.create_default(), spine_world)
	host._expect_text_contains(String(spine_status.get("supply_hint", "")), "碎晶分流读数", "heart spine missing input points to shunt readings")
	var shunt_world := WorldState.create_default()
	shunt_world.quest_state.unlock_effect("recipe.phase_well_shunt")
	shunt_world.add_base_structure("structure.basic_reactor", "building.basic_reactor", "region.outpost_platform")
	var shunt_status := processing.get_recipe_status("recipe.phase_well_shunt", CharacterState.create_default(), shunt_world)
	host._expect_text_contains(String(shunt_status.get("supply_hint", "")), "解析碎晶心核", "phase well shunt missing pulse sheet points to heart analysis")
	var shunt_character := CharacterState.create_default()
	shunt_character.inventory.add_item("item.phase_well_pulse_sheet", 1)
	shunt_status = processing.get_recipe_status("recipe.phase_well_shunt", shunt_character, shunt_world)
	host._expect_text_contains(String(shunt_status.get("supply_hint", "")), "稳定心棘残片", "phase well shunt missing damper points to spine stabilization")


func _check_wind_conduit_readability(processing: ProcessingSystem) -> void:
	host._expect_text_contains(processing._get_completion_next_step("recipe.phase_well_spindle_analysis"), "风蚀张力绕轮", "phase well spindle completion points to tension spools")
	host._expect_text_contains(RecipePurposeHints.format_recipe_goal_hint("recipe.weft_bundle_stabilization"), "风蚀梭栓", "weft bundle purpose points to shuttle assembly")
	host._expect_text_contains(RecipePurposeHints.format_recipe_goal_hint("recipe.phase_well_shuttle"), "锁相织构核", "phase well shuttle purpose points to weave core reward")
	var weft_world := _create_filter_world("recipe.weft_bundle_stabilization")
	var weft_status := processing.get_recipe_status("recipe.weft_bundle_stabilization", CharacterState.create_default(), weft_world)
	host._expect_text_contains(String(weft_status.get("supply_hint", "")), "风蚀张力绕轮", "weft bundle missing input points to tension spools")
	var shuttle_world := WorldState.create_default()
	shuttle_world.quest_state.unlock_effect("recipe.phase_well_shuttle")
	shuttle_world.add_base_structure("structure.basic_reactor", "building.basic_reactor", "region.outpost_platform")
	var shuttle_status := processing.get_recipe_status("recipe.phase_well_shuttle", CharacterState.create_default(), shuttle_world)
	host._expect_text_contains(String(shuttle_status.get("supply_hint", "")), "解析风蚀张力核", "phase well shuttle missing warp sheet points to spindle analysis")
	var shuttle_character := CharacterState.create_default()
	shuttle_character.inventory.add_item("item.phase_well_warp_sheet", 1)
	shuttle_status = processing.get_recipe_status("recipe.phase_well_shuttle", shuttle_character, shuttle_world)
	host._expect_text_contains(String(shuttle_status.get("supply_hint", "")), "稳定纬束残团", "phase well shuttle missing rib points to weft stabilization")


func _check_phase_lock_frame_readability(processing: ProcessingSystem) -> void:
	host._expect_text_contains(processing._get_completion_next_step("recipe.phase_well_weave_core_analysis"), "锁相侧路障", "phase well weave core completion points to frame route blocker")
	host._expect_text_contains(RecipePurposeHints.format_recipe_goal_hint("recipe.selvedge_strip_stabilization"), "锁相键栓", "selvedge strip purpose points to frame key assembly")
	host._expect_text_contains(RecipePurposeHints.format_recipe_goal_hint("recipe.phase_well_frame_key"), "锚定结核", "phase well frame key purpose points to knot core reward")
	var selvedge_world := _create_filter_world("recipe.selvedge_strip_stabilization")
	var selvedge_status := processing.get_recipe_status("recipe.selvedge_strip_stabilization", CharacterState.create_default(), selvedge_world)
	host._expect_text_contains(String(selvedge_status.get("supply_hint", "")), "锁相侧路障", "selvedge strip missing input points to route blocker")
	var frame_world := WorldState.create_default()
	frame_world.quest_state.unlock_effect("recipe.phase_well_frame_key")
	frame_world.add_base_structure("structure.basic_reactor", "building.basic_reactor", "region.outpost_platform")
	var frame_status := processing.get_recipe_status("recipe.phase_well_frame_key", CharacterState.create_default(), frame_world)
	host._expect_text_contains(String(frame_status.get("supply_hint", "")), "解析锁相织构核", "phase well frame key missing pattern sheet points to weave core analysis")
	var frame_character := CharacterState.create_default()
	frame_character.inventory.add_item("item.phase_well_pattern_sheet", 1)
	frame_status = processing.get_recipe_status("recipe.phase_well_frame_key", frame_character, frame_world)
	host._expect_text_contains(String(frame_status.get("supply_hint", "")), "稳定边缕残条", "phase well frame key missing rib points to selvedge stabilization")


func _create_filter_world(recipe_id: String) -> WorldState:
	var world := WorldState.create_default()
	world.quest_state.unlock_effect(recipe_id)
	world.add_base_structure(
		"structure.pollution_filter_build_site",
		"building.pollution_filter",
		"region.pollution_edge",
		"map_object_instance.pollution_filter_build_site"
	)
	return world
