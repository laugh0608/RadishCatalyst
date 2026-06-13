extends RefCounted

const VerticalSliceMapScene := preload("res://scenes/maps/VerticalSliceMap.tscn")

var host


func _init(check_host) -> void:
	host = check_host


func run(root: Node) -> void:
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
	host._expect_text_contains(status_text, "整备台：基础过滤模块已生效", "field outfitting station HUD summary")
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
	host._expect_text_contains(supply_status_text, "整备台：基础过滤模块已生效", "field outfitting station keeps module status with supplies")
	host._expect_text_contains(
		supply_status_text,
		"出发补给：回前哨核心补修复凝胶 / 抗污染药剂 x1",
		"field outfitting station HUD summary includes departure supply restock"
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
