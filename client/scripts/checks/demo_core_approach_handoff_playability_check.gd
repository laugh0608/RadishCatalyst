extends SceneTree

const VerticalSliceMapScene := preload("res://scenes/maps/VerticalSliceMap.tscn")

var failures: Array[String] = []
var data_registry := DataRegistry.new()
var frontier_runtime: PhaseWellFrontierRuntime


func _init() -> void:
	if not data_registry.load_all():
		failures.append("data registry should load all static data")
	else:
		frontier_runtime = PhaseWellFrontierRuntime.new(data_registry)
		_run_checks()

	if failures.is_empty():
		print("Demo core approach handoff playability checks passed.")
		_cleanup()
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	_cleanup()
	quit(1)


func _run_checks() -> void:
	_check_formatter_tracks_core_approach_handoff()
	_check_scene_layer_marks_core_approach_handoff()
	_check_hud_and_map_core_approach_readouts()
	_check_object_prompts_show_core_approach_handoff()
	_check_runtime_results_keep_core_approach_followup()


func _check_formatter_tracks_core_approach_handoff() -> void:
	var region_ids := DemoCoreApproachHandoffFormatter.get_region_ids()
	_expect_equal(region_ids.size(), 3, "core approach formatter covers focused handoff regions")
	_expect_array_has(region_ids, "region.phase_well_frame", "core approach covers phase well frame")
	_expect_array_has(region_ids, "region.phase_well_tether", "core approach covers phase well tether")
	_expect_array_has(region_ids, "region.demo_stabilization_core", "core approach covers demo stabilization core")

	var tether_hint := DemoCoreApproachHandoffFormatter.format_map_route_hint("region.phase_well_tether")
	_expect_text_contains(tether_hint, "核心入口承接：锚定桥 -> 核心稳定站入口", "tether hint names core approach")
	_expect_text_contains(tether_hint, "锚场回稳窗", "tether hint names anchor field")
	_expect_text_contains(tether_hint, "核心稳定站", "tether hint points to core")

	var tether_anchor := DemoCoreApproachHandoffFormatter.format_static_object_handoff_line(
		"map_object.phase_return_anchor",
		"region.phase_well_tether"
	)
	_expect_text_contains(tether_anchor, "对象落点：回投承接", "tether phase return anchor is scoped to core approach")
	_expect_equal(
		DemoCoreApproachHandoffFormatter.format_static_object_handoff_line(
			"map_object.phase_return_anchor",
			"region.deep_ruin_threshold"
		),
		"",
		"deep phase return anchor does not inherit core approach handoff"
	)

	var core_line := DemoCoreApproachHandoffFormatter.format_static_object_handoff_line(
		"map_object.demo_stabilization_core",
		"region.demo_stabilization_core"
	)
	_expect_text_contains(core_line, "对象落点：核心入口设备", "core device line names entry role")


func _check_scene_layer_marks_core_approach_handoff() -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	var layer := map.get_node("CoreApproachHandoffLayer") as Node2D
	var frame_exit := map.get_node("CoreApproachHandoffLayer/FrameExitHandoff") as ColorRect
	var tether_bridge := map.get_node("CoreApproachHandoffLayer/TetherBridgeHandoff") as ColorRect
	var anchor_field := map.get_node("CoreApproachHandoffLayer/AnchorFieldHandoff") as ColorRect
	var core_entry := map.get_node("CoreApproachHandoffLayer/CoreEntryThreshold") as ColorRect
	var core_device := map.get_node("CoreApproachHandoffLayer/CoreDeviceHandoff") as ColorRect

	_expect_equal(layer != null, true, "core approach scene layer exists")
	_expect_equal(
		frame_exit.offset_left >= VerticalSliceMap.PHASE_WELL_FRAME_REGION_X
			and frame_exit.offset_right < VerticalSliceMap.PHASE_WELL_TETHER_REGION_X,
		true,
		"frame exit handoff stays inside phase well frame"
	)
	_expect_equal(
		tether_bridge.offset_left >= VerticalSliceMap.PHASE_WELL_TETHER_REGION_X
			and anchor_field.offset_right < VerticalSliceMap.DEMO_STABILIZATION_CORE_REGION_X,
		true,
		"tether bridge and anchor field stay inside phase well tether"
	)
	_expect_equal(
		core_entry.offset_left >= VerticalSliceMap.DEMO_STABILIZATION_CORE_REGION_X
			and core_device.offset_left >= VerticalSliceMap.DEMO_STABILIZATION_CORE_REGION_X,
		true,
		"core entry marks stay inside demo stabilization core"
	)
	_expect_equal(frame_exit.color.a > 0.3, true, "frame handoff has visible alpha")
	_expect_equal(anchor_field.color.a > 0.3, true, "anchor field handoff has visible alpha")
	_expect_equal(core_device.color.a > 0.3, true, "core device handoff has visible alpha")
	map.free()


func _check_hud_and_map_core_approach_readouts() -> void:
	var world := WorldState.create_default()
	var character := CharacterState.create_default()
	world.current_region_id = "region.phase_well_tether"
	character.current_region_id = "region.phase_well_tether"
	world.ensure_map_object(
		"map_object_instance.core_approach_anchor_field",
		"map_object.phase_well_anchor_field",
		"region.phase_well_tether"
	)

	var vitals_text := HudStatusPresenter.new().format_vitals_text(data_registry, world, character)
	_expect_text_contains(vitals_text, "现场玩法：锚定桥现场玩法", "HUD keeps existing tether gameplay line")
	_expect_text_contains(vitals_text, "核心入口承接：锚定桥 -> 核心稳定站入口", "HUD adds core approach line")
	_expect_text_contains(vitals_text, "承接证据", "HUD names core approach evidence")

	var map_hint := HudMapPresenter.new().format_demo_route_hint(world, "", character)
	_expect_text_contains(map_hint, "核心入口承接：锚定桥 -> 核心稳定站入口", "map route hint includes core approach")
	_expect_text_contains(map_hint, "锚场回稳窗", "map route hint names anchor field")
	_expect_text_contains(map_hint, "核心稳定站", "map route hint names core entry")


func _check_object_prompts_show_core_approach_handoff() -> void:
	var world := WorldState.create_default()
	var character := CharacterState.create_default()
	var formatter := InteractionPromptFormatter.new(
		data_registry,
		ProcessingSystem.new(data_registry),
		BuildSystem.new(data_registry)
	)

	world.current_region_id = "region.phase_well_frame"
	character.current_region_id = "region.phase_well_frame"
	var frame_prompt := formatter.format_phase_well_frame_prompt(world, character)
	_expect_text_contains(frame_prompt, "核心入口承接：锁相框架 -> 锚定桥承接", "frame prompt shows core approach")
	_expect_text_contains(frame_prompt, "对象落点：锚定桥前置断面", "frame prompt names handoff role")

	world.current_region_id = "region.phase_well_tether"
	character.current_region_id = "region.phase_well_tether"
	var tether_prompt := formatter.format_phase_well_tether_prompt(world, character)
	_expect_text_contains(tether_prompt, "核心入口承接：锚定桥 -> 核心稳定站入口", "tether prompt shows core approach")
	_expect_text_contains(tether_prompt, "对象落点：锚场前置断面", "tether prompt names handoff role")

	world.quest_state.complete_quest("quest.deploy_phase_relay_anchor")
	var anchor_prompt := formatter.format_phase_return_anchor_prompt(
		world,
		character,
		"map_object_instance.phase_return_anchor_tether"
	)
	_expect_text_contains(anchor_prompt, "对象落点：回投承接", "tether return anchor prompt names handoff role")

	var pressure_pin := _create_interactable(
		"map_object_instance.core_pressure_pin_prompt",
		"map_object.phase_well_anchor_pressure_pin",
		"clear"
	)
	var pressure_prompt := formatter.format_clear_prompt(pressure_pin, character, world)
	_expect_text_contains(pressure_prompt, "对象落点：稳窗压力清障", "pressure pin prompt names handoff role")
	pressure_pin.free()

	var anchor_field_prompt := formatter.format_phase_well_anchor_field_prompt(world, character)
	_expect_text_contains(anchor_field_prompt, "对象落点：核心入口稳窗", "anchor field prompt names core entry window")

	var stability_node := _create_interactable(
		"map_object_instance.core_stability_node_prompt",
		"map_object.phase_well_stability_node_west",
		"inspect"
	)
	var node_prompt := formatter.format_stability_calibration_prompt(stability_node, character, world)
	_expect_text_contains(node_prompt, "对象落点：稳窗校准序列", "stability node prompt names calibration sequence")
	stability_node.free()

	world.current_region_id = "region.demo_stabilization_core"
	character.current_region_id = "region.demo_stabilization_core"
	var core_device := _create_interactable(
		"map_object_instance.core_device_prompt",
		"map_object.demo_stabilization_core",
		"inspect"
	)
	var core_prompt := formatter.format_general_interaction_prompt(core_device, character, world)
	_expect_text_contains(core_prompt, "核心入口承接：核心稳定站入口确认", "core device prompt shows handoff")
	_expect_text_contains(core_prompt, "对象落点：核心入口设备", "core device prompt names entry device")
	core_device.free()


func _check_runtime_results_keep_core_approach_followup() -> void:
	var tether_world := WorldState.create_default()
	var tether_character := CharacterState.create_default()
	tether_world.current_region_id = "region.phase_well_tether"
	tether_character.current_region_id = "region.phase_well_tether"
	tether_world.quest_state.complete_quest("quest.refine_tether_fiber")
	tether_character.inventory.add_item("item.phase_well_tether_spike", 1)
	var tether_result := frontier_runtime.inspect_tether(tether_character, tether_world)
	_expect_equal(bool(tether_result.get("success", false)), true, "tether inspect succeeds")
	_expect_text_contains(String(tether_result.get("message", "")), "核心入口承接：锚场前置断面已处理", "tether result keeps core approach followup")

	var anchor_world := WorldState.create_default()
	var anchor_character := CharacterState.create_default()
	anchor_world.current_region_id = "region.phase_well_tether"
	anchor_character.current_region_id = "region.phase_well_tether"
	anchor_world.quest_state.complete_quest("quest.refine_anchor_core_dust")
	anchor_character.inventory.add_item("item.phase_well_anchor_stake", 1)
	var anchor_result := frontier_runtime.inspect_anchor_field(anchor_character, anchor_world)
	_expect_equal(bool(anchor_result.get("success", false)), true, "anchor field deploy succeeds")
	_expect_text_contains(String(anchor_result.get("message", "")), "核心入口承接：核心入口稳窗已处理", "anchor field result keeps core approach followup")

	var node_world := WorldState.create_default()
	var node_character := CharacterState.create_default()
	node_world.current_region_id = "region.phase_well_tether"
	node_character.current_region_id = "region.phase_well_tether"
	node_world.quest_state.complete_quest("quest.analyze_phase_well_echo_shard")
	node_character.inventory.add_item("item.phase_well_stability_readout", 1)
	var node_result := frontier_runtime.inspect_stability_calibration_node(
		"map_object_instance.core_node_result",
		"map_object.phase_well_stability_node_west",
		node_character,
		node_world
	)
	_expect_equal(bool(node_result.get("success", false)), true, "stability node inspect succeeds")
	_expect_text_contains(String(node_result.get("message", "")), "核心入口承接：稳窗校准序列已处理", "stability node result keeps core approach followup")


func _create_interactable(instance_id: String, definition_id: String, interaction_type: String) -> PrototypeInteractable:
	var interactable := PrototypeInteractable.new()
	interactable.instance_id = instance_id
	interactable.definition_id = definition_id
	interactable.interaction_type = interaction_type
	return interactable


func _expect_equal(actual, expected, context: String) -> void:
	if actual == expected:
		return
	failures.append("%s: expected %s, got %s" % [context, str(expected), str(actual)])


func _expect_array_has(values: Array, expected, context: String) -> void:
	if values.has(expected):
		return
	failures.append("%s: expected array to contain %s, got %s" % [context, expected, str(values)])


func _expect_text_contains(text: String, expected: String, context: String) -> void:
	if text.find(expected) >= 0:
		return
	failures.append("%s: expected text to contain '%s', got '%s'" % [context, expected, text])


func _cleanup() -> void:
	data_registry.free()
