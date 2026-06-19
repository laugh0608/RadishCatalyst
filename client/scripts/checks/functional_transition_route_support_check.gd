extends SceneTree

var failures: Array[String] = []
var data_registry := DataRegistry.new()


func _init() -> void:
	if not data_registry.load_all():
		failures.append("data registry should load all static data")
	else:
		_run_checks()

	if failures.is_empty():
		print("Functional transition route support checks passed.")
		_cleanup()
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	_cleanup()
	quit(1)


func _run_checks() -> void:
	_check_formatter_covers_functional_and_transition_regions()
	_check_hud_and_map_readouts()
	_check_object_prompts()
	_check_region_count_boundary()


func _check_formatter_covers_functional_and_transition_regions() -> void:
	var region_ids := FunctionalTransitionRouteSupportFormatter.get_region_ids()
	_expect_equal(region_ids.size(), 8, "formatter covers exactly four functional and four transition regions")
	for region_id in [
		"region.ruin_outer_ring",
		"region.deep_ruin_threshold",
		"region.inner_phase_well",
		"region.phase_well_sink",
		"region.phase_well_chamber",
		"region.phase_well_loom",
		"region.phase_well_frame",
		"region.phase_well_tether"
	]:
		_expect_equal(region_ids.has(region_id), true, "%s is covered by route support formatter" % region_id)

	var ruin_hint := FunctionalTransitionRouteSupportFormatter.format_map_route_hint("region.ruin_outer_ring")
	_expect_text_contains(ruin_hint, "封锁遗迹机制展示线", "ruin outer ring has route support title")
	_expect_text_contains(ruin_hint, "当前危险", "ruin outer ring hint names danger")
	_expect_text_contains(ruin_hint, "回基地", "ruin outer ring hint names return-to-base reason")

	var tether_hint := FunctionalTransitionRouteSupportFormatter.format_map_route_hint("region.phase_well_tether")
	_expect_text_contains(tether_hint, "锚定桥稳定工程接入线", "anchor bridge has route support title")
	_expect_text_contains(tether_hint, "核心稳定工程", "anchor bridge points to stabilization engineering")


func _check_hud_and_map_readouts() -> void:
	var world := WorldState.create_default()
	var character := CharacterState.create_default()
	var map_presenter := HudMapPresenter.new()

	world.current_region_id = "region.phase_well_chamber"
	var map_hint := map_presenter.format_demo_route_hint(world, "")
	_expect_text_contains(map_hint, "碎晶沟谷资源耦合线", "map route hint shows transition route support")
	_expect_text_contains(map_hint, "当前危险", "map route hint shows current danger")
	_expect_text_contains(map_hint, "回基地", "map route hint keeps base return reason")

	var vitals_text := HudStatusPresenter.new().format_vitals_text(data_registry, world, character)
	_expect_text_contains(vitals_text, "路线支撑：碎晶沟谷资源耦合线", "HUD vitals show transition route support")
	_expect_text_contains(vitals_text, "回基地理由", "HUD vitals keeps route return reason")


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
		"路线支撑：封锁遗迹机制展示线",
		"ruin gate prompt shows functional route support"
	)

	world.current_region_id = "region.deep_ruin_threshold"
	_expect_text_contains(
		formatter.format_phase_return_anchor_prompt(world, character),
		"路线支撑：裂相脊前线回传线",
		"phase return anchor prompt shows ridge route support"
	)

	world.current_region_id = "region.inner_phase_well"
	_expect_text_contains(
		formatter.format_inner_phase_well_prompt(world, character),
		"路线支撑：回声台地异常读数线",
		"inner phase well prompt shows echo route support"
	)

	world.current_region_id = "region.phase_well_sink"
	_expect_text_contains(
		formatter.format_phase_well_sink_prompt(world, character),
		"路线支撑：盐壳浅滩污染沉积连接线",
		"sink prompt shows salt-flat route support"
	)

	world.current_region_id = "region.phase_well_chamber"
	_expect_text_contains(
		formatter.format_phase_well_chamber_prompt(world, character),
		"路线支撑：碎晶沟谷资源耦合线",
		"chamber prompt shows crystal ravine route support"
	)

	world.current_region_id = "region.phase_well_loom"
	_expect_text_contains(
		formatter.format_phase_well_loom_prompt(world, character),
		"路线支撑：风蚀管廊旧设施连接线",
		"loom prompt shows wind corridor route support"
	)

	world.current_region_id = "region.phase_well_frame"
	_expect_text_contains(
		formatter.format_phase_well_frame_prompt(world, character),
		"路线支撑：锁相框架终点前压强线",
		"frame prompt shows phase-lock frame route support"
	)

	world.current_region_id = "region.phase_well_tether"
	_expect_text_contains(
		formatter.format_phase_well_tether_prompt(world, character),
		"路线支撑：锚定桥稳定工程接入线",
		"tether prompt shows anchor bridge route support"
	)

	var shunt := _create_interactable(
		"map_object_instance.functional_route_shunt",
		"map_object.phase_well_chamber_shunt_node",
		"inspect"
	)
	var shunt_prompt := formatter.format_field_reading_prompt(shunt, world)
	_expect_text_contains(shunt_prompt, "路线支撑：碎晶沟谷资源耦合线", "field reading prompt shows route support")
	shunt.free()


func _check_region_count_boundary() -> void:
	var world := WorldState.create_default()
	var marker_labels := HudMapPresenter.new().format_map_marker_labels(world, "")
	_expect_equal(marker_labels.size(), 12, "HUD map remains capped at 12 visible demo regions")


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
