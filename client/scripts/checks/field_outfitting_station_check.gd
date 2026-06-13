extends RefCounted

const VerticalSliceMapScene := preload("res://scenes/maps/VerticalSliceMap.tscn")

var host


func _init(check_host) -> void:
	host = check_host


func run(root: Node) -> void:
	_check_slurry_buffer_tank(root)
	var build_system := BuildSystem.new(host.data_registry)
	var outfitting_world := WorldState.create_default()
	var outfitting_character := CharacterState.create_default()
	outfitting_character.inventory.items["item.basic_parts"] = 2
	outfitting_character.inventory.items["item.salvage_scrap"] = 1
	var build_result := build_system.build_structure(
		"map_object_instance.field_outfitting_station_build_site",
		"building.field_outfitting_station",
		outfitting_character,
		outfitting_world
	)
	host._expect_equal(bool(build_result.get("success", false)), true, "field outfitting station build succeeds")
	host._expect_equal(
		outfitting_world.has_base_structure_definition("building.field_outfitting_station"),
		true,
		"field outfitting station writes base structure"
	)
	host._expect_equal(
		int(outfitting_character.inventory.items.get("item.basic_parts", 0)),
		0,
		"field outfitting station consumes basic parts"
	)
	host._expect_equal(
		int(outfitting_character.inventory.items.get("item.salvage_scrap", 0)),
		0,
		"field outfitting station consumes salvage scrap"
	)

	var gather_system := GatherSystem.new(host.data_registry)
	var missing_module := gather_system.interact_with_object(
		"map_object_instance.field_outfitting_station",
		"building.field_outfitting_station",
		"inspect",
		outfitting_character,
		outfitting_world
	)
	host._expect_failure_feedback(missing_module, "整备材料不足", "field outfitting station missing module feedback")
	outfitting_character.inventory.add_equipment("equipment.filter_module_t1", 1)
	var equip_result := gather_system.interact_with_object(
		"map_object_instance.field_outfitting_station",
		"building.field_outfitting_station",
		"inspect",
		outfitting_character,
		outfitting_world
	)
	host._expect_equal(bool(equip_result.get("success", false)), true, "field outfitting station equips module")
	host._expect_equal(
		bool(equip_result.get("outfitting_module_enabled", false)),
		true,
		"field outfitting station returns progression marker"
	)
	host._expect_equal(
		String(outfitting_character.equipment.get("suit_module", "")),
		"equipment.filter_module_t1",
		"field outfitting station writes suit module"
	)
	host._expect_equal(
		int(outfitting_character.inventory.equipment.get("equipment.filter_module_t1", 0)),
		0,
		"field outfitting station consumes inventory module"
	)
	var repeat_result := gather_system.interact_with_object(
		"map_object_instance.field_outfitting_station",
		"building.field_outfitting_station",
		"inspect",
		outfitting_character,
		outfitting_world
	)
	host._expect_text_contains(
		String(repeat_result.get("message", "")),
		"已装入防护服",
		"field outfitting station repeat check keeps equipped status"
	)

	var status_text := HudStatusPresenter.new().format_vitals_text(
		host.data_registry,
		outfitting_world,
		outfitting_character
	)
	host._expect_text_contains(status_text, "出发准备：模块已装", "field outfitting station HUD summary")
	host._expect_text_contains(status_text, "收益：模块装配后会降低污染采集和反击压力", "field outfitting station HUD payoff")
	outfitting_world.add_base_structure(
		"structure.basic_storage_build_site",
		"building.basic_storage",
		"region.outpost_platform",
		"map_object_instance.basic_storage_build_site"
	)
	outfitting_world.add_base_structure(
		"structure.pollution_filter_build_site",
		"building.pollution_filter",
		"region.outpost_platform",
		"map_object_instance.pollution_filter_build_site"
	)
	outfitting_world.quest_state.set_objective_progress("quest.enter_pollution_edge", "craft_item", "item.resistance_vial_t1", 1.0)
	outfitting_character.inventory.consume_ref("item.repair_gel", 1)
	var supply_status_text := HudStatusPresenter.new().format_vitals_text(
		host.data_registry,
		outfitting_world,
		outfitting_character
	)
	host._expect_text_contains(supply_status_text, "出发准备：模块已装", "field outfitting station keeps module status with supplies")
	host._expect_text_contains(
		supply_status_text,
		"回前哨核心补修复凝胶 / 抗污染药剂",
		"field outfitting station HUD summary includes departure supply restock"
	)
	host._expect_text_contains(
		supply_status_text,
		"收益：污染采集和污染战斗承压下降",
		"field outfitting station HUD summary explains pressure payoff"
	)
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	map.setup(host.data_registry)
	map.apply_runtime_state(outfitting_world, outfitting_character)
	var station := map.get_node("Interactables/FieldOutfittingStation") as PrototypeInteractable
	host._expect_equal(station.visible, true, "built field outfitting station is visible")
	host._expect_equal(station.monitoring, true, "built field outfitting station stays interactable")
	host._expect_text_contains(station.label.text, "可整备", "built field outfitting station visual label")
	map.free()


func _check_slurry_buffer_tank(root: Node) -> void:
	var build_system := BuildSystem.new(host.data_registry)
	var gather_system := GatherSystem.new(host.data_registry)
	var formatter := InteractionPromptFormatter.new(
		host.data_registry,
		ProcessingSystem.new(host.data_registry),
		build_system
	)
	var tank_site := PrototypeInteractable.new()
	tank_site.definition_id = "building.slurry_buffer_tank"
	tank_site.interaction_type = "build"
	tank_site.instance_id = "map_object_instance.slurry_buffer_tank_build_site"

	var blocked_world := WorldState.create_default()
	var blocked_character := CharacterState.create_default()
	var blocked_result := build_system.build_structure(
		tank_site.instance_id,
		tank_site.definition_id,
		blocked_character,
		blocked_world
	)
	host._expect_failure_feedback(blocked_result, "建造前置不足", "slurry buffer tank blocks before pollution filter")
	host._expect_text_contains(
		String(blocked_result.get("message", "")),
		"需要先建成污染过滤器",
		"slurry buffer tank requires pollution filter"
	)

	blocked_world.add_base_structure(
		"structure.pollution_filter_build_site",
		"building.pollution_filter",
		"region.pollution_edge",
		"map_object_instance.pollution_filter_build_site"
	)
	var first_vial_blocked := build_system.build_structure(
		tank_site.instance_id,
		tank_site.definition_id,
		blocked_character,
		blocked_world
	)
	host._expect_text_contains(
		String(first_vial_blocked.get("message", "")),
		"跑通首支抗污染药剂",
		"slurry buffer tank requires first vial processing"
	)

	var build_world := WorldState.create_default()
	build_world.add_base_structure(
		"structure.pollution_filter_build_site",
		"building.pollution_filter",
		"region.pollution_edge",
		"map_object_instance.pollution_filter_build_site"
	)
	build_world.quest_state.set_objective_progress("quest.enter_pollution_edge", "craft_item", "item.resistance_vial_t1", 1.0)
	var build_character := CharacterState.create_default()
	build_character.inventory.items.clear()
	build_character.inventory.fluids.clear()
	var missing_prompt := formatter.format_build_prompt(tank_site, build_character, build_world)
	host._expect_text_contains(missing_prompt, "污染浆液缓冲罐", "slurry buffer prompt names tank")
	host._expect_text_contains(missing_prompt, "缺少建造材料", "slurry buffer prompt shows missing materials")
	host._expect_text_contains(missing_prompt, "污染过滤器处理出污染浆液", "slurry buffer prompt points to filter byproduct")

	build_character.inventory.add_item("item.basic_parts", 2)
	build_character.inventory.add_fluid("fluid.polluted_slurry", 1.0)
	var build_result := build_system.build_structure(
		tank_site.instance_id,
		tank_site.definition_id,
		build_character,
		build_world
	)
	host._expect_equal(bool(build_result.get("success", false)), true, "slurry buffer tank build succeeds")
	host._expect_equal(
		build_world.has_base_structure_definition("building.slurry_buffer_tank"),
		true,
		"slurry buffer tank registers base structure"
	)
	host._expect_equal(
		int(build_character.inventory.items.get("item.basic_parts", 0)),
		0,
		"slurry buffer tank consumes basic parts"
	)
	host._expect_equal(
		float(build_character.inventory.fluids.get("fluid.polluted_slurry", 0.0)),
		0.0,
		"slurry buffer tank consumes polluted slurry"
	)
	host._expect_text_contains(
		String(build_result.get("message", "")),
		"抗污染药剂可补到 2 份",
		"slurry buffer tank build feedback explains double vial supply"
	)

	build_world.quest_state.complete_quest("quest.restore_outpost")
	build_world.add_base_structure(
		"structure.basic_storage_build_site",
		"building.basic_storage",
		"region.outpost_platform",
		"map_object_instance.basic_storage_build_site"
	)
	var supply_character := CharacterState.create_default()
	supply_character.inventory.items.erase("item.resistance_vial_t1")
	var outpost_result := gather_system.interact_with_object(
		"map_object_instance.outpost_core",
		"building.outpost_core",
		"outpost_core",
		supply_character,
		build_world
	)
	host._expect_text_contains(
		String(outpost_result.get("message", "")),
		"污染浆液缓冲罐补抗污染药剂",
		"slurry buffer tank outpost restock names buffer source"
	)
	host._expect_equal(
		int(supply_character.inventory.items.get("item.resistance_vial_t1", 0)),
		2,
		"slurry buffer tank raises vial restock target to two"
	)

	var hud_text := HudStatusPresenter.new().format_vitals_text(
		host.data_registry,
		build_world,
		supply_character
	)
	host._expect_text_contains(hud_text, "抗污染药剂 x2已备", "slurry buffer tank HUD shows double vial ready")
	host._expect_text_contains(hud_text, "双药剂补给", "slurry buffer tank HUD explains pressure payoff")
	var gate_result := gather_system.interact_with_object(
		"map_object_instance.outpost_departure_gate",
		"map_object.outpost_departure_gate",
		"inspect",
		supply_character,
		build_world
	)
	host._expect_text_contains(
		String(gate_result.get("message", "")),
		"抗污染药剂 x2已备",
		"slurry buffer tank departure gate shows double vial ready"
	)

	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	map.setup(host.data_registry)
	var scene_site := map.get_node("Interactables/SlurryBufferTankBuildSite") as PrototypeInteractable
	var locked_world := WorldState.create_default()
	map.refresh_world_interactables(locked_world)
	host._expect_equal(scene_site.can_interact(), false, "slurry buffer tank site hidden before filter route")
	map.refresh_world_interactables(build_world)
	host._expect_equal(scene_site.can_interact(), false, "slurry buffer tank completed site is no longer interactable")
	host._expect_text_contains(scene_site.label.text, "浆液缓冲罐", "slurry buffer tank built scene label")
	host._expect_text_contains(scene_site.label.text, "已接入", "slurry buffer tank built scene state")
	map.free()
	tank_site.free()
