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
