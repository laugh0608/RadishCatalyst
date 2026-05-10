extends RefCounted
class_name HudRuntimeHintFlowCheck

const PrototypeHudScene := preload("res://scenes/ui/PrototypeHud.tscn")
const VerticalSliceMapScene := preload("res://scenes/maps/VerticalSliceMap.tscn")


func run(root: Window, failures: Array[String], data_registry: DataRegistry) -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	var hud := PrototypeHudScene.instantiate() as PrototypeHud
	root.add_child(map)
	root.add_child(hud)
	hud.configure_map_presenter(data_registry, map)
	var runtime_world := WorldState.create_default()
	var runtime_character := CharacterState.create_default()
	hud.update_status(data_registry, runtime_world, runtime_character)

	_expect_text_contains(
		failures,
		hud.prompt_label.text,
		"方向：检查左侧前哨核心",
		"runtime hint prompt shows direction without interactable"
	)
	_expect_text_contains(
		failures,
		hud.prompt_label.text,
		"提示：先恢复前哨核心",
		"runtime hint prompt shows onboarding without interactable"
	)

	runtime_world.quest_state.active_quest_ids = ["quest.prepare_treatment_supplies"]
	runtime_world.quest_state.set_objective_progress(
		"quest.prepare_treatment_supplies",
		"craft_item",
		"item.repair_gel",
		1.0
	)
	hud.update_status(data_registry, runtime_world, runtime_character)
	_expect_text_contains(
		failures,
		hud.prompt_label.text,
		"处理点北缘",
		"runtime hint prompt follows resolver-backed combat region"
	)
	_expect_text_contains(
		failures,
		hud.prompt_label.text,
		"提示：带上修复凝胶",
		"runtime hint prompt keeps onboarding line"
	)

	var relay_world := WorldState.create_default()
	var relay_character := CharacterState.create_default()
	relay_world.current_region_id = "region.outpost_platform"
	relay_world.quest_state.active_quest_ids = ["quest.reenter_phase_frontline"]
	hud.update_status(data_registry, relay_world, relay_character)
	_expect_text_contains(
		failures,
		hud.prompt_label.text,
		"方向：在基地按 E 使用相位回投台",
		"runtime hint prompt points relay reentry back to outpost pad"
	)
	_expect_text_contains(
		failures,
		hud.prompt_label.text,
		"提示：先真正用一次回投台",
		"runtime hint prompt explains relay reentry purpose"
	)

	var phase_well_world := WorldState.create_default()
	var phase_well_character := CharacterState.create_default()
	phase_well_world.quest_state.active_quest_ids = []
	phase_well_world.quest_state.completed_quest_ids.append("quest.unlock_phase_well")
	hud.update_status(data_registry, phase_well_world, phase_well_character)
	_expect_text_contains(
		failures,
		hud.prompt_label.text,
		"方向：相位井定位器已带回：先回基地解析定位器",
		"runtime hint prompt keeps phase well locator fallback after deep lock"
	)
	_expect_text_contains(
		failures,
		hud.prompt_label.text,
		"提示：相位井定位器不是收尾；先回基地解析它",
		"runtime hint prompt keeps locator analysis explicit after phase well lock"
	)
	var heart_world := WorldState.create_default()
	var heart_character := CharacterState.create_default()
	heart_world.quest_state.active_quest_ids = []
	heart_world.quest_state.completed_quest_ids.append("quest.inspect_phase_well_sink")
	hud.update_status(data_registry, heart_world, heart_character)
	_expect_text_contains(
		failures,
		hud.prompt_label.text,
		"方向：相位井心核已带回：先回基地解析心核",
		"runtime hint prompt keeps phase well heart fallback after sink"
	)
	_expect_text_contains(
		failures,
		hud.prompt_label.text,
		"提示：相位井心核不是收尾；要先回基地把它解析成脉搏片",
		"runtime hint prompt keeps heart analysis explicit after phase well sink"
	)
	var chamber_world := WorldState.create_default()
	var chamber_character := CharacterState.create_default()
	chamber_world.quest_state.active_quest_ids = []
	chamber_world.quest_state.completed_quest_ids.append("quest.inspect_phase_well_chamber")
	hud.update_status(data_registry, chamber_world, chamber_character)
	_expect_text_contains(
		failures,
		hud.prompt_label.text,
		"方向：相位井纺核已带回：先回基地解析纺核",
		"runtime hint prompt keeps phase well spindle fallback after chamber"
	)
	_expect_text_contains(
		failures,
		hud.prompt_label.text,
		"提示：相位井纺核不是收尾；要先回基地把它解析成经片",
		"runtime hint prompt keeps spindle analysis explicit after phase well chamber"
	)
	var loom_world := WorldState.create_default()
	var loom_character := CharacterState.create_default()
	loom_world.quest_state.active_quest_ids = []
	loom_world.quest_state.completed_quest_ids.append("quest.inspect_phase_well_loom")
	hud.update_status(data_registry, loom_world, loom_character)
	_expect_text_contains(
		failures,
		hud.prompt_label.text,
		"方向：井纺室断面已经交出第一份相位井织核",
		"runtime hint prompt summarizes weave core reward after phase well loom"
	)
	hud.update_status(data_registry, relay_world, relay_character)

	var reactor := PrototypeInteractable.new()
	reactor.definition_id = "building.basic_reactor"
	reactor.interaction_type = "process_recipe"
	reactor.recipe_id = "recipe.process_crystal_ore"
	reactor.set_recipe_cycle(["recipe.process_crystal_ore"])
	var formatter := InteractionPromptFormatter.new(
		data_registry,
		ProcessingSystem.new(data_registry),
		BuildSystem.new(data_registry)
	)
	hud.show_prompt(formatter.format_processing_prompt(reactor, runtime_character, runtime_world))
	_expect_text_contains(
		failures,
		hud.prompt_label.text,
		"设备：基础反应器",
		"interaction prompt overrides runtime hint while near device"
	)
	_expect_text_missing(
		failures,
		hud.prompt_label.text,
		"方向：",
		"interaction prompt should replace runtime hint rows"
	)
	if hud.prompt_label.text.split("\n").size() > 6:
		failures.append("interaction prompt should stay compact, got %d lines: %s" % [
			hud.prompt_label.text.split("\n").size(),
			hud.prompt_label.text
		])
	hud.clear_prompt()
	_expect_text_contains(
		failures,
		hud.prompt_label.text,
		"方向：在基地按 E 使用相位回投台",
		"runtime hint returns after interaction clears"
	)

	reactor.free()
	hud.free()
	map.free()


func _expect_text_contains(failures: Array[String], text: String, expected_text: String, label: String) -> void:
	if text.find(expected_text) < 0:
		failures.append("%s should contain %s, got %s" % [label, expected_text, text])


func _expect_text_missing(failures: Array[String], text: String, unexpected_text: String, label: String) -> void:
	if text.find(unexpected_text) >= 0:
		failures.append("%s should not contain %s, got %s" % [label, unexpected_text, text])
