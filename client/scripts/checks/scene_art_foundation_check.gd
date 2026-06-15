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
		print("Scene art foundation checks passed.")
		_cleanup()
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	_cleanup()
	quit(1)


func _run_checks() -> void:
	_check_scene_identity_layer()
	_check_formatter_core_regions()
	_check_hud_and_map_readouts()
	_check_object_prompts()


func _check_scene_identity_layer() -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	var layer := map.get_node("SceneArtFoundationLayer") as Node2D
	var base_band := map.get_node("SceneArtFoundationLayer/SceneArtBaseIdentityBand") as ColorRect
	var crystal_band := map.get_node("SceneArtFoundationLayer/SceneArtCrystalIdentityBand") as ColorRect
	var pollution_band := map.get_node("SceneArtFoundationLayer/SceneArtPollutionIdentityBand") as ColorRect
	var core_band := map.get_node("SceneArtFoundationLayer/SceneArtCoreIdentityBand") as ColorRect
	var base_label := map.get_node("SceneArtFoundationLayer/SceneArtBaseIdentityLabel") as Label
	var crystal_label := map.get_node("SceneArtFoundationLayer/SceneArtCrystalIdentityLabel") as Label
	var pollution_label := map.get_node("SceneArtFoundationLayer/SceneArtPollutionIdentityLabel") as Label
	var core_label := map.get_node("SceneArtFoundationLayer/SceneArtCoreIdentityLabel") as Label

	_expect_equal(layer != null, true, "scene art foundation layer exists")
	_expect_equal(
		base_band.offset_right < VerticalSliceMap.CRYSTAL_REGION_X
			and crystal_band.offset_left >= VerticalSliceMap.CRYSTAL_REGION_X
			and crystal_band.offset_right <= VerticalSliceMap.POLLUTION_REGION_X
			and pollution_band.offset_left >= VerticalSliceMap.POLLUTION_REGION_X
			and pollution_band.offset_right <= VerticalSliceMap.RUIN_OUTER_RING_X
			and core_band.offset_left >= VerticalSliceMap.DEMO_STABILIZATION_CORE_REGION_X,
		true,
		"scene art identity bands stay inside the four core regions"
	)
	_expect_text_contains(base_label.text, "基地整备回路", "base scene art label names preparation loop")
	_expect_text_contains(crystal_label.text, "晶体矿脉", "crystal scene art label names resource line")
	_expect_text_contains(pollution_label.text, "污染边界", "pollution scene art label names filter line")
	_expect_text_contains(core_label.text, "Demo 终点", "core scene art label names demo endpoint")
	map.free()


func _check_formatter_core_regions() -> void:
	var base_hint := SceneArtFoundationFormatter.format_map_route_hint("region.outpost_platform")
	_expect_text_contains(base_hint, "基地整备回路", "formatter names base scene identity")
	_expect_text_contains(base_hint, "出发整备", "formatter explains base preparation route")

	var crystal_hint := SceneArtFoundationFormatter.format_map_route_hint("region.crystal_vein_field")
	_expect_text_contains(crystal_hint, "晶体矿脉资源线", "formatter names crystal resource identity")
	_expect_text_contains(crystal_hint, "基础反应器", "formatter points crystal resources back to reactor")

	var pollution_hint := SceneArtFoundationFormatter.format_map_route_hint("region.pollution_edge")
	_expect_text_contains(pollution_hint, "污染边界过滤线", "formatter names pollution filter identity")
	_expect_text_contains(pollution_hint, "抗污染药剂", "formatter points pollution residue to vial payoff")

	var core_hint := SceneArtFoundationFormatter.format_map_route_hint("region.demo_stabilization_core")
	_expect_text_contains(core_hint, "核心稳定站终点", "formatter names demo core identity")
	_expect_text_contains(core_hint, "Demo 终点", "formatter explains core endpoint role")


func _check_hud_and_map_readouts() -> void:
	var world := WorldState.create_default()
	var character := CharacterState.create_default()
	var map_presenter := HudMapPresenter.new()

	world.current_region_id = "region.crystal_vein_field"
	var crystal_route_hint := map_presenter.format_demo_route_hint(world, "")
	_expect_text_contains(crystal_route_hint, "晶体矿脉资源线", "map route hint shows crystal scene identity")
	_expect_text_contains(crystal_route_hint, "回基地", "map route hint keeps return-to-base reason")

	world.current_region_id = "region.pollution_edge"
	var vitals_text := HudStatusPresenter.new().format_vitals_text(data_registry, world, character)
	_expect_text_contains(vitals_text, "场景识别：污染边界过滤线", "HUD vitals show pollution scene identity")
	_expect_text_contains(vitals_text, "回基地理由", "HUD vitals keeps return-to-base reason")


func _check_object_prompts() -> void:
	var world := WorldState.create_default()
	var character := CharacterState.create_default()
	var formatter := InteractionPromptFormatter.new(
		data_registry,
		ProcessingSystem.new(data_registry),
		BuildSystem.new(data_registry)
	)

	var outpost_prompt := formatter.format_outpost_core_prompt(world, character)
	_expect_text_contains(outpost_prompt, "场景：基地整备回路", "outpost core prompt shows base scene identity")

	world.current_region_id = "region.crystal_vein_field"
	var crystal := _create_interactable("map_object_instance.scene_art_crystal", "map_object.crystal_cluster", "gather")
	var crystal_prompt := formatter.format_general_interaction_prompt(crystal, character, world)
	_expect_text_contains(crystal_prompt, "场景：晶体矿脉资源线", "crystal prompt shows scene identity")
	_expect_text_contains(crystal_prompt, "带回基地", "crystal prompt explains base return value")
	crystal.free()

	world.current_region_id = "region.pollution_edge"
	var pollution := _create_interactable("map_object_instance.scene_art_residue", "map_object.pollution_residue_patch", "gather")
	var pollution_prompt := formatter.format_general_interaction_prompt(pollution, character, world)
	_expect_text_contains(pollution_prompt, "场景：污染边界过滤线", "pollution prompt shows scene identity")
	_expect_text_contains(pollution_prompt, "过滤回基地", "pollution prompt explains filter reason")
	pollution.free()

	world.current_region_id = "region.demo_stabilization_core"
	var core := _create_interactable(
		"map_object_instance.demo_stabilization_core",
		"map_object.demo_stabilization_core",
		"inspect"
	)
	var core_prompt := formatter.format_general_interaction_prompt(core, character, world)
	_expect_text_contains(core_prompt, "场景：核心稳定站终点", "core prompt shows scene identity")
	_expect_text_contains(core_prompt, "首版 Demo 终点", "core prompt explains endpoint role")
	core.free()


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


func _expect_text_contains(text: String, expected: String, context: String) -> void:
	if text.find(expected) >= 0:
		return
	failures.append("%s: expected text to contain '%s', got '%s'" % [context, expected, text])


func _cleanup() -> void:
	data_registry.free()
