extends SceneTree

const VerticalSliceMapScene := preload("res://scenes/maps/VerticalSliceMap.tscn")

var failures: Array[String] = []
var data_registry := DataRegistry.new()


func _init() -> void:
	if not data_registry.load_all():
		failures.append("data registry should load all static data")
	else:
		_run_checks()

	if failures.is_empty():
		print("Demo midfield route playability checks passed.")
		_cleanup()
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	_cleanup()
	quit(1)


func _run_checks() -> void:
	_check_formatter_tracks_midfield_route()
	_check_scene_layer_marks_midfield_route()
	_check_hud_and_map_midfield_readouts()
	_check_object_prompts_show_midfield_route()
	_check_runtime_results_keep_midfield_followup()


func _check_formatter_tracks_midfield_route() -> void:
	var region_ids := DemoMidfieldRoutePlayabilityFormatter.get_region_ids()
	_expect_equal(region_ids.size(), 3, "midfield formatter covers three regions")
	_expect_array_has(region_ids, "region.inner_phase_well", "midfield formatter covers inner phase well")
	_expect_array_has(region_ids, "region.phase_well_sink", "midfield formatter covers phase well sink")
	_expect_array_has(region_ids, "region.phase_well_chamber", "midfield formatter covers phase well chamber")

	var echo_hint := DemoMidfieldRoutePlayabilityFormatter.format_map_route_hint("region.inner_phase_well")
	_expect_text_contains(echo_hint, "中段路径：回声台地中段路径", "echo route hint names midfield path")
	_expect_text_contains(echo_hint, "回声泄压阀", "echo route hint names boundary")
	_expect_text_contains(echo_hint, "盐壳浅滩", "echo route hint points to next region")

	var chamber_line := DemoMidfieldRoutePlayabilityFormatter.format_static_object_route_line(
		"map_object.phase_well_chamber_shunt_node",
		"region.phase_well_chamber"
	)
	_expect_text_contains(chamber_line, "碎晶沟谷中段路径", "chamber object line names midfield path")
	_expect_text_contains(chamber_line, "入口边界", "chamber object line names shunt role")


func _check_scene_layer_marks_midfield_route() -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	var layer := map.get_node("MidfieldRoutePlayabilityLayer") as Node2D
	var echo_entry := map.get_node("MidfieldRoutePlayabilityLayer/EchoEntryLane") as ColorRect
	var echo_facility := map.get_node("MidfieldRoutePlayabilityLayer/EchoFacilityPocket") as ColorRect
	var salt_boundary := map.get_node("MidfieldRoutePlayabilityLayer/SaltCrustBoundary") as ColorRect
	var salt_facility := map.get_node("MidfieldRoutePlayabilityLayer/SaltSinkFacilityPocket") as ColorRect
	var crystal_shunt := map.get_node("MidfieldRoutePlayabilityLayer/CrystalShuntBoundary") as ColorRect
	var crystal_facility := map.get_node("MidfieldRoutePlayabilityLayer/CrystalChamberFacilityPocket") as ColorRect

	_expect_equal(layer != null, true, "midfield scene layer exists")
	_expect_equal(
		echo_entry.offset_left >= VerticalSliceMap.INNER_PHASE_WELL_REGION_X
			and echo_facility.offset_right < VerticalSliceMap.PHASE_WELL_SINK_REGION_X,
		true,
		"echo route marks stay inside inner phase well"
	)
	_expect_equal(
		salt_boundary.offset_left >= VerticalSliceMap.PHASE_WELL_SINK_REGION_X
			and salt_facility.offset_right < VerticalSliceMap.PHASE_WELL_CHAMBER_REGION_X,
		true,
		"salt route marks stay inside phase well sink"
	)
	_expect_equal(
		crystal_shunt.offset_left >= VerticalSliceMap.PHASE_WELL_CHAMBER_REGION_X
			and crystal_facility.offset_right < VerticalSliceMap.PHASE_WELL_LOOM_REGION_X,
		true,
		"crystal route marks stay inside phase well chamber"
	)
	_expect_equal(echo_entry.color.a > 0.3, true, "echo entry lane has visible alpha")
	_expect_equal(crystal_facility.color.a > 0.3, true, "crystal facility pocket has visible alpha")
	map.free()


func _check_hud_and_map_midfield_readouts() -> void:
	var world := WorldState.create_default()
	var character := CharacterState.create_default()
	world.current_region_id = "region.inner_phase_well"
	character.current_region_id = "region.inner_phase_well"
	world.ensure_map_object(
		"map_object_instance.midfield_flux_prompt",
		"map_object.well_flux_cluster",
		"region.inner_phase_well"
	)

	var vitals_text := HudStatusPresenter.new().format_vitals_text(data_registry, world, character)
	_expect_text_contains(vitals_text, "路线支撑：回声台地异常读数线", "HUD keeps existing echo route support line")
	_expect_text_contains(vitals_text, "中段路径：回声台地中段路径", "HUD adds midfield route line")
	_expect_text_contains(vitals_text, "路径落点：危险", "HUD names midfield placements")

	var map_hint := HudMapPresenter.new().format_demo_route_hint(world, "", character)
	_expect_text_contains(map_hint, "中段路径：回声台地中段路径", "map route hint includes midfield route")
	_expect_text_contains(map_hint, "回声泄压阀", "map route hint names echo boundary")
	_expect_text_contains(map_hint, "盐壳浅滩", "map route hint names next region")


func _check_object_prompts_show_midfield_route() -> void:
	var world := WorldState.create_default()
	var character := CharacterState.create_default()
	var formatter := InteractionPromptFormatter.new(
		data_registry,
		ProcessingSystem.new(data_registry),
		BuildSystem.new(data_registry)
	)
	world.current_region_id = "region.inner_phase_well"
	character.current_region_id = "region.inner_phase_well"

	var flux := _create_interactable(
		"map_object_instance.midfield_flux_prompt",
		"map_object.well_flux_cluster",
		"gather"
	)
	var flux_prompt := formatter.format_general_interaction_prompt(flux, character, world)
	_expect_text_contains(flux_prompt, "中段路径：回声台地中段路径", "general prompt shows echo midfield path")
	_expect_text_contains(flux_prompt, "对象落点：资源", "general prompt names resource role")
	flux.free()

	var vent := _create_interactable(
		"map_object_instance.midfield_vent_prompt",
		"map_object.well_flux_pressure_vent",
		"inspect"
	)
	var vent_prompt := formatter.format_field_reading_prompt(vent, world)
	_expect_text_contains(vent_prompt, "中段路径：回声台地中段路径", "field reading prompt shows echo midfield path")
	_expect_text_contains(vent_prompt, "对象落点：入口边界", "field reading prompt names boundary role")
	vent.free()

	world.current_region_id = "region.phase_well_sink"
	character.current_region_id = "region.phase_well_sink"
	var crust := _create_interactable(
		"map_object_instance.midfield_crust_prompt",
		"map_object.well_ash_crust_blocker",
		"clear"
	)
	var crust_prompt := formatter.format_clear_prompt(crust, character, world)
	_expect_text_contains(crust_prompt, "中段路径：盐壳浅滩中段路径", "clear prompt shows salt midfield path")
	_expect_text_contains(crust_prompt, "对象落点：入口边界", "clear prompt names salt boundary role")
	crust.free()


func _check_runtime_results_keep_midfield_followup() -> void:
	var world := WorldState.create_default()
	var character := CharacterState.create_default()
	var gather_system := GatherSystem.new(data_registry)
	world.current_region_id = "region.inner_phase_well"
	character.current_region_id = "region.inner_phase_well"

	var flux_result := gather_system.interact_with_object(
		"map_object_instance.midfield_flux_result",
		"map_object.well_flux_cluster",
		"gather",
		character,
		world
	)
	_expect_equal(bool(flux_result.get("success", false)), true, "well flux gather succeeds")
	_expect_text_contains(String(flux_result.get("message", "")), "中段路径：资源已处理", "flux result keeps midfield followup")
	_expect_text_contains(String(flux_result.get("message", "")), "回基地稳定回声碎屑", "flux result points back to base")

	world.current_region_id = "region.phase_well_sink"
	character.current_region_id = "region.phase_well_sink"
	var clear_result := gather_system.interact_with_object(
		"map_object_instance.midfield_crust_result",
		"map_object.well_ash_crust_blocker",
		"clear",
		character,
		world
	)
	_expect_equal(bool(clear_result.get("success", false)), true, "well ash crust clear succeeds")
	_expect_text_contains(String(clear_result.get("message", "")), "中段路径：入口边界已处理", "crust result keeps midfield followup")
	_expect_text_contains(String(clear_result.get("message", "")), "碎晶沟谷", "crust result points to next region")

	world.current_region_id = "region.phase_well_chamber"
	character.current_region_id = "region.phase_well_chamber"
	var shunt_result := gather_system.interact_with_object(
		"map_object_instance.midfield_shunt_result",
		"map_object.phase_well_chamber_shunt_node",
		"inspect",
		character,
		world
	)
	_expect_equal(bool(shunt_result.get("success", false)), true, "chamber shunt inspect succeeds")
	_expect_text_contains(String(shunt_result.get("message", "")), "中段路径：入口边界已处理", "shunt result keeps midfield followup")
	_expect_text_contains(String(shunt_result.get("message", "")), "风蚀管廊", "shunt result points to next region")


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
	failures.append("%s: expected array to contain %s, got %s" % [context, str(expected), str(values)])


func _expect_text_contains(text: String, expected: String, context: String) -> void:
	if text.find(expected) >= 0:
		return
	failures.append("%s: expected text to contain '%s', got '%s'" % [context, expected, text])


func _cleanup() -> void:
	data_registry.free()
