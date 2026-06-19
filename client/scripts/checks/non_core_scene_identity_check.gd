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
		print("Non-core scene identity checks passed.")
		_cleanup()
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	_cleanup()
	quit(1)


func _run_checks() -> void:
	_check_scene_identity_layer()
	_check_formatter_non_core_regions()
	_check_hud_and_map_readouts()
	_check_object_prompts()


func _check_scene_identity_layer() -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	var layer := map.get_node("NonCoreSceneIdentityLayer") as Node2D
	var ruin_band := map.get_node("NonCoreSceneIdentityLayer/NonCoreRuinIdentityBand") as ColorRect
	var ridge_band := map.get_node("NonCoreSceneIdentityLayer/NonCoreRidgeIdentityBand") as ColorRect
	var echo_band := map.get_node("NonCoreSceneIdentityLayer/NonCoreEchoIdentityBand") as ColorRect
	var salt_band := map.get_node("NonCoreSceneIdentityLayer/NonCoreSaltIdentityBand") as ColorRect
	var chamber_band := map.get_node("NonCoreSceneIdentityLayer/NonCoreCrystalRavineIdentityBand") as ColorRect
	var loom_band := map.get_node("NonCoreSceneIdentityLayer/NonCoreWindCorridorIdentityBand") as ColorRect
	var frame_band := map.get_node("NonCoreSceneIdentityLayer/NonCorePhaseFrameIdentityBand") as ColorRect
	var tether_band := map.get_node("NonCoreSceneIdentityLayer/NonCoreAnchorBridgeIdentityBand") as ColorRect

	_expect_equal(layer != null, true, "non-core scene identity layer exists")
	_expect_equal(
		ruin_band.offset_left >= VerticalSliceMap.RUIN_OUTER_RING_X
			and ridge_band.offset_left >= VerticalSliceMap.DEEP_RUIN_REGION_X
			and ridge_band.offset_right <= VerticalSliceMap.INNER_PHASE_WELL_REGION_X
			and echo_band.offset_left >= VerticalSliceMap.INNER_PHASE_WELL_REGION_X
			and salt_band.offset_left >= VerticalSliceMap.PHASE_WELL_SINK_REGION_X
			and chamber_band.offset_left >= VerticalSliceMap.PHASE_WELL_CHAMBER_REGION_X
			and loom_band.offset_left >= VerticalSliceMap.PHASE_WELL_LOOM_REGION_X
			and frame_band.offset_left >= VerticalSliceMap.PHASE_WELL_FRAME_REGION_X
			and tether_band.offset_left >= VerticalSliceMap.PHASE_WELL_TETHER_REGION_X
			and tether_band.offset_right <= VerticalSliceMap.DEMO_STABILIZATION_CORE_REGION_X,
		true,
		"non-core identity bands stay inside functional and transition regions"
	)

	_expect_text_contains(
		(map.get_node("NonCoreSceneIdentityLayer/NonCoreRuinIdentityLabel") as Label).text,
		"封锁遗迹",
		"ruin scene label names locked ruin"
	)
	_expect_text_contains(
		(map.get_node("NonCoreSceneIdentityLayer/NonCoreRidgeIdentityLabel") as Label).text,
		"裂相脊",
		"ridge scene label names fractured ridge"
	)
	_expect_text_contains(
		(map.get_node("NonCoreSceneIdentityLayer/NonCoreAnchorBridgeIdentityLabel") as Label).text,
		"锚定桥",
		"anchor bridge scene label names bridge"
	)
	map.free()


func _check_formatter_non_core_regions() -> void:
	var region_ids := NonCoreSceneIdentityFormatter.get_region_ids()
	_expect_equal(region_ids.size(), 8, "formatter covers eight non-core regions")

	var ruin_hint := NonCoreSceneIdentityFormatter.format_map_route_hint("region.ruin_outer_ring")
	_expect_text_contains(ruin_hint, "封锁遗迹旧设施区", "formatter names ruin scene identity")
	_expect_text_contains(ruin_hint, "旧设施短副本入口", "formatter explains ruin visual identity")

	var salt_hint := NonCoreSceneIdentityFormatter.format_map_route_hint("region.phase_well_sink")
	_expect_text_contains(salt_hint, "盐壳浅滩化学沉积", "formatter names salt-flat scene identity")

	var tether_hint := NonCoreSceneIdentityFormatter.format_map_route_hint("region.phase_well_tether")
	_expect_text_contains(tether_hint, "锚定桥稳定接入区", "formatter names anchor bridge scene identity")
	_expect_text_contains(tether_hint, "桥体", "formatter explains bridge visual identity")


func _check_hud_and_map_readouts() -> void:
	var world := WorldState.create_default()
	var character := CharacterState.create_default()
	var map_presenter := HudMapPresenter.new()

	world.current_region_id = "region.phase_well_frame"
	var map_hint := map_presenter.format_demo_route_hint(world, "")
	_expect_text_contains(map_hint, "场景：锁相框架压相设施", "map route hint shows non-core scene identity")
	_expect_text_contains(map_hint, "路线：锁相框架终点前压强线", "map route hint keeps route support")

	var vitals_text := HudStatusPresenter.new().format_vitals_text(data_registry, world, character)
	_expect_text_contains(vitals_text, "路线支撑：锁相框架终点前压强线", "HUD vitals keeps route support")


func _check_object_prompts() -> void:
	var world := WorldState.create_default()
	var character := CharacterState.create_default()
	var formatter := InteractionPromptFormatter.new(
		data_registry,
		ProcessingSystem.new(data_registry),
		BuildSystem.new(data_registry)
	)

	world.current_region_id = "region.locked_ruin_gate"
	_expect_text_contains(
		formatter.format_ruin_gate_prompt(world, character),
		"场景：封锁遗迹旧设施区",
		"ruin gate prompt shows non-core scene identity"
	)

	world.current_region_id = "region.deep_ruin_threshold"
	_expect_text_contains(
		formatter.format_phase_return_anchor_prompt(world, character),
		"场景：裂相脊撕裂地貌",
		"phase return anchor prompt shows ridge scene identity"
	)

	world.current_region_id = "region.inner_phase_well"
	_expect_text_contains(
		formatter.format_inner_phase_well_prompt(world, character),
		"场景：回声台地观测残响",
		"inner phase well prompt shows echo scene identity"
	)

	world.current_region_id = "region.phase_well_sink"
	_expect_text_contains(
		formatter.format_phase_well_sink_prompt(world, character),
		"场景：盐壳浅滩化学沉积",
		"sink prompt shows salt-flat scene identity"
	)

	world.current_region_id = "region.phase_well_tether"
	_expect_text_contains(
		formatter.format_phase_well_tether_prompt(world, character),
		"场景：锚定桥稳定接入区",
		"tether prompt shows anchor bridge scene identity"
	)

	var shunt := _create_interactable(
		"map_object_instance.non_core_scene_shunt",
		"map_object.phase_well_chamber_shunt_node",
		"inspect"
	)
	world.current_region_id = "region.phase_well_chamber"
	var shunt_prompt := formatter.format_field_reading_prompt(shunt, world)
	_expect_text_contains(shunt_prompt, "场景：碎晶沟谷晶体耦合", "field reading prompt shows scene identity")
	_expect_text_contains(shunt_prompt, "路线支撑：碎晶沟谷资源耦合线", "field reading prompt keeps route support")
	shunt.free()


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
