extends RefCounted

var host


func _init(check_host) -> void:
	host = check_host


func run() -> void:
	_check_build_prompts()
	_check_processing_missing_prompt()


func _check_build_prompts() -> void:
	var build_world := WorldState.create_default()
	var build_character := CharacterState.create_default()
	var formatter := _create_formatter()
	var rough_ground := PrototypeInteractable.new()
	rough_ground.definition_id = "map_object.rough_ground"
	rough_ground.interaction_type = "clear"
	rough_ground.instance_id = "map_object_instance.rough_ground_north"
	var rough_prompt := formatter.format_clear_prompt(rough_ground, build_character, build_world)
	host._expect_text_contains(rough_prompt, "阻挡建造", "rough ground prompt")
	host._expect_text_contains(rough_prompt, "下一步：清理后可铺设基础地基", "rough ground next step prompt")

	var foundation_site := PrototypeInteractable.new()
	foundation_site.definition_id = "building.foundation_t1"
	foundation_site.interaction_type = "build"
	foundation_site.instance_id = "map_object_instance.foundation_site_north"
	foundation_site.prerequisite_instance_id = "map_object_instance.rough_ground_north"
	var blocked_foundation_prompt := formatter.format_build_prompt(foundation_site, build_character, build_world)
	host._expect_text_contains(blocked_foundation_prompt, "地面仍然粗糙", "foundation blocked prompt")
	host._expect_text_contains(blocked_foundation_prompt, "下一步：先清理粗糙地块", "foundation blocked next step prompt")

	build_world.ensure_map_object("map_object_instance.rough_ground_north", "map_object.rough_ground", "region.pollution_edge")
	build_world.set_map_object_flag("map_object_instance.rough_ground_north", "is_cleared", true)
	var missing_foundation_prompt := formatter.format_build_prompt(foundation_site, build_character, build_world)
	host._expect_text_contains(missing_foundation_prompt, "缺少建造材料", "foundation missing material prompt")
	host._expect_text_contains(missing_foundation_prompt, "下一步：回晶体区采集资源", "foundation missing material next step prompt")

	build_character.inventory.add_item("item.foundation_material", 1)
	host._expect_text_contains(
		formatter.format_build_prompt(foundation_site, build_character, build_world),
		"按 E 建造",
		"foundation ready prompt"
	)

	var filter_site := PrototypeInteractable.new()
	filter_site.definition_id = "building.pollution_filter"
	filter_site.interaction_type = "build"
	filter_site.instance_id = "map_object_instance.pollution_filter_build_site"
	var blocked_filter_prompt := formatter.format_build_prompt(filter_site, build_character, build_world)
	host._expect_text_contains(blocked_filter_prompt, "基础地基：0 / 2", "pollution filter foundation status")
	host._expect_text_contains(blocked_filter_prompt, "下一步：先铺设 2 块基础地基", "pollution filter foundation next step prompt")

	build_world.add_base_structure("structure.foundation_site_north", "building.foundation_t1", "region.pollution_edge")
	build_world.add_base_structure("structure.foundation_site_south", "building.foundation_t1", "region.pollution_edge")
	host._expect_text_contains(
		formatter.format_build_prompt(filter_site, build_character, build_world),
		"缺少建造材料",
		"pollution filter missing material prompt"
	)
	rough_ground.free()
	foundation_site.free()
	filter_site.free()


func _check_processing_missing_prompt() -> void:
	var formatter := _create_formatter()
	var device_world := WorldState.create_default()
	var device_character := CharacterState.create_default()
	var reactor := PrototypeInteractable.new()
	reactor.definition_id = "building.basic_reactor"
	reactor.interaction_type = "process_recipe"
	reactor.recipe_id = "recipe.process_crystal_ore"
	reactor.set_recipe_cycle([
		"recipe.process_crystal_ore",
		"recipe.reactor_calibrator",
		"recipe.analyze_anomaly_sample",
		"recipe.make_filter_media",
		"recipe.basic_filter_module",
		"recipe.foundation_t1",
		"recipe.repair_gel"
	])
	device_world.quest_state.unlock_effect("recipe.process_crystal_ore")
	var missing_prompt := formatter.format_processing_prompt(reactor, device_character, device_world)
	host._expect_text_contains(missing_prompt, "状态：缺少原料", "processing prompt shows missing inputs")
	host._expect_text_contains(missing_prompt, "下一步：", "processing prompt shows missing input next step")
	host._expect_text_missing(missing_prompt, "E 启动加工", "processing prompt hides process action when blocked")
	reactor.free()


func _create_formatter() -> InteractionPromptFormatter:
	return InteractionPromptFormatter.new(
		host.data_registry,
		ProcessingSystem.new(host.data_registry),
		BuildSystem.new(host.data_registry)
	)
