extends SceneTree

const VerticalSliceMapScene := preload("res://scenes/maps/VerticalSliceMap.tscn")

const REGION_CASES := [
	{
		"region_id": "region.outpost_platform",
		"title": "前哨平台构成",
		"landmark": "前哨核心 / 出发整备台",
		"node_name": "OutpostCore",
		"prompt": "outpost_core"
	},
	{
		"region_id": "region.crystal_vein_field",
		"title": "晶体矿脉构成",
		"landmark": "晶簇 / 残骸口袋",
		"node_name": "CrystalCluster",
		"prompt": "general"
	},
	{
		"region_id": "region.pollution_edge",
		"title": "污染边界构成",
		"landmark": "污染沉积 / 过滤器基座",
		"node_name": "PollutionResidue",
		"prompt": "general"
	},
	{
		"region_id": "region.ruin_outer_ring",
		"title": "封锁遗迹构成",
		"landmark": "遗迹门 / 外圈回波匣",
		"node_name": "SignalEchoCache",
		"prompt": "signal_echo_cache"
	},
	{
		"region_id": "region.deep_ruin_threshold",
		"title": "裂相脊构成",
		"landmark": "裂相阵列 / 回传锚点",
		"node_name": "DeepSignalArray",
		"prompt": "deep_signal_array"
	},
	{
		"region_id": "region.inner_phase_well",
		"title": "回声台地构成",
		"landmark": "回声芯 / 泄压阀",
		"node_name": "InnerPhaseWell",
		"prompt": "inner_phase_well"
	},
	{
		"region_id": "region.phase_well_sink",
		"title": "盐壳浅滩构成",
		"landmark": "盐壳硬壳 / 浅滩裂口",
		"node_name": "PhaseWellSink",
		"prompt": "phase_well_sink"
	},
	{
		"region_id": "region.phase_well_chamber",
		"title": "碎晶沟谷构成",
		"landmark": "碎晶分流 / 相位井腔",
		"node_name": "PhaseWellChamber",
		"prompt": "phase_well_chamber"
	},
	{
		"region_id": "region.phase_well_loom",
		"title": "风蚀管廊构成",
		"landmark": "张力绕轮 / 管廊断面",
		"node_name": "PhaseWellLoom",
		"prompt": "phase_well_loom"
	},
	{
		"region_id": "region.phase_well_frame",
		"title": "锁相框架构成",
		"landmark": "锁相框架 / 侧路障",
		"node_name": "PhaseWellFrame",
		"prompt": "phase_well_frame"
	},
	{
		"region_id": "region.phase_well_tether",
		"title": "锚定桥构成",
		"landmark": "锚定桥 / 锚场回稳窗",
		"node_name": "PhaseWellAnchorField",
		"prompt": "phase_well_anchor_field"
	},
	{
		"region_id": "region.demo_stabilization_core",
		"title": "核心稳定站构成",
		"landmark": "核心稳定站 / 守卫缓存",
		"node_name": "DemoStabilizationCore",
		"prompt": "general"
	}
]

var failures: Array[String] = []
var data_registry := DataRegistry.new()


func _init() -> void:
	if not data_registry.load_all():
		failures.append("data registry should load all static data")
	else:
		_run_checks()

	if failures.is_empty():
		print("Playable scene composition checks passed.")
		_cleanup()
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	_cleanup()
	quit(1)


func _run_checks() -> void:
	_check_formatter_region_coverage()
	_check_map_route_composition()
	_check_object_prompt_composition()
	_check_scene_object_region_placement()


func _check_formatter_region_coverage() -> void:
	var region_ids := PlayableSceneCompositionFormatter.get_region_ids()
	_expect_equal(region_ids.size(), REGION_CASES.size(), "formatter covers twelve playable regions")
	for region_case in REGION_CASES:
		var region_id := String(region_case.get("region_id", ""))
		_expect_array_has(region_ids, region_id, "%s in formatter region list" % region_id)
		var map_hint := PlayableSceneCompositionFormatter.format_map_route_hint(region_id)
		_expect_text_contains(map_hint, "画面构成", "%s formatter map hint has composition" % region_id)
		_expect_text_contains(
			map_hint,
			String(region_case.get("landmark", "")),
			"%s formatter map hint names landmark" % region_id
		)


func _check_map_route_composition() -> void:
	var map_presenter := HudMapPresenter.new()
	for region_case in REGION_CASES:
		var region_id := String(region_case.get("region_id", ""))
		var world := WorldState.create_default()
		world.current_region_id = region_id
		var map_hint := map_presenter.format_demo_route_hint(world, "")
		_expect_text_contains(map_hint, "画面构成", "%s HUD map hint has composition" % region_id)
		_expect_text_contains(
			map_hint,
			String(region_case.get("title", "")),
			"%s HUD map hint names composition title" % region_id
		)
		_expect_text_contains(
			map_hint,
			String(region_case.get("landmark", "")),
			"%s HUD map hint names landmark" % region_id
		)


func _check_object_prompt_composition() -> void:
	var formatter := InteractionPromptFormatter.new(
		data_registry,
		ProcessingSystem.new(data_registry),
		BuildSystem.new(data_registry)
	)
	for region_case in REGION_CASES:
		var region_id := String(region_case.get("region_id", ""))
		var world := WorldState.create_default()
		var character := CharacterState.create_default()
		world.current_region_id = region_id
		character.current_region_id = region_id
		var prompt := _format_region_prompt(formatter, region_case, world, character)
		_expect_text_contains(prompt, "画面构成", "%s object prompt has composition" % region_id)
		_expect_text_contains(
			prompt,
			String(region_case.get("title", "")),
			"%s object prompt names composition title" % region_id
		)


func _check_scene_object_region_placement() -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	map.setup(data_registry)
	for region_case in REGION_CASES:
		var region_id := String(region_case.get("region_id", ""))
		var node_name := String(region_case.get("node_name", ""))
		var interactable := map.get_node("Interactables/%s" % node_name) as PrototypeInteractable
		_expect_equal(interactable != null, true, "%s representative object exists" % node_name)
		if interactable == null:
			continue
		_expect_equal(
			map._get_region_id_for_position(interactable.position),
			region_id,
			"%s representative object sits in expected region" % node_name
		)
		_expect_equal(
			PlayableSceneCompositionFormatter.get_region_id_for_definition(interactable.definition_id),
			region_id,
			"%s representative definition maps to expected region" % node_name
		)
	map.free()


func _format_region_prompt(
	formatter: InteractionPromptFormatter,
	region_case: Dictionary,
	world: WorldState,
	character: CharacterState
) -> String:
	var prompt_type := String(region_case.get("prompt", "general"))
	match prompt_type:
		"outpost_core":
			return formatter.format_outpost_core_prompt(world, character)
		"signal_echo_cache":
			return formatter.format_signal_echo_cache_prompt(world, character)
		"deep_signal_array":
			return formatter.format_deep_signal_array_prompt(world, character)
		"inner_phase_well":
			return formatter.format_inner_phase_well_prompt(world, character)
		"phase_well_sink":
			return formatter.format_phase_well_sink_prompt(world, character)
		"phase_well_chamber":
			return formatter.format_phase_well_chamber_prompt(world, character)
		"phase_well_loom":
			return formatter.format_phase_well_loom_prompt(world, character)
		"phase_well_frame":
			return formatter.format_phase_well_frame_prompt(world, character)
		"phase_well_anchor_field":
			return formatter.format_phase_well_anchor_field_prompt(world, character)
		_:
			var interactable := _create_interactable_for_case(region_case)
			var prompt := formatter.format_general_interaction_prompt(interactable, character, world)
			interactable.free()
			return prompt


func _create_interactable_for_case(region_case: Dictionary) -> PrototypeInteractable:
	var interactable := PrototypeInteractable.new()
	var node_name := String(region_case.get("node_name", "")).to_snake_case()
	interactable.instance_id = "map_object_instance.%s" % node_name
	interactable.definition_id = _get_definition_id_for_node_name(String(region_case.get("node_name", "")))
	interactable.interaction_type = _get_interaction_type(interactable.definition_id)
	interactable.single_use = false
	return interactable


func _get_definition_id_for_node_name(node_name: String) -> String:
	match node_name:
		"CrystalCluster":
			return "map_object.crystal_cluster"
		"PollutionResidue":
			return "map_object.pollution_residue_patch"
		"DemoStabilizationCore":
			return "map_object.demo_stabilization_core"
		_:
			return "building.outpost_core"


func _get_interaction_type(definition_id: String) -> String:
	if definition_id.begins_with("building."):
		return "inspect"
	if definition_id == "map_object.demo_stabilization_core":
		return "inspect"
	return "gather"


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
