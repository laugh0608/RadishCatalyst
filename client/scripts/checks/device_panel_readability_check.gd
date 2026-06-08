extends RefCounted

var host


func _init(check_host) -> void:
	host = check_host


func run() -> void:
	_check_basic_reactor_panel_hierarchy()
	_check_pollution_filter_panel_hierarchy()
	_check_active_processing_panel_uses_running_recipe()


func _check_basic_reactor_panel_hierarchy() -> void:
	var processing := ProcessingSystem.new(host.data_registry)
	var presenter := HudDevicePanelPresenter.new()
	var reactor := PrototypeInteractable.new()
	reactor.definition_id = "building.basic_reactor"
	reactor.interaction_type = "process_recipe"
	reactor.recipe_id = "recipe.process_crystal_ore"
	reactor.set_recipe_cycle([
		"recipe.process_crystal_ore",
		"recipe.analyze_anomaly_sample",
		"recipe.make_filter_media",
		"recipe.basic_filter_module"
	])
	reactor.select_recipe("recipe.analyze_anomaly_sample")

	var world := WorldState.create_default()
	world.quest_state.active_quest_ids = ["quest.analyze_anomaly_sample"]
	world.quest_state.unlock_effect("recipe.analyze_anomaly_sample")
	world.quest_state.set_objective_progress("quest.analyze_anomaly_sample", "gather_item", "item.anomaly_residue", 2)

	var character := CharacterState.create_default()
	character.inventory.add_item("item.anomaly_sample", 1)
	character.inventory.add_item("item.anomaly_residue", 2)
	var panel_texts := presenter.format_device_panel_texts(
		host.data_registry,
		processing,
		reactor,
		character,
		world
	)
	var status := String(panel_texts.get("status", ""))
	host._expect_text_contains(status, "设备状态：可启动", "reactor panel shows ready state")
	host._expect_text_contains(status, "当前配方：分析异常样本", "reactor panel names current recipe")
	host._expect_text_contains(status, "输入：异常样本 x1", "reactor panel shows current inputs")
	host._expect_text_contains(status, "完成去向：产物入背包：样本分析结果 x1", "reactor panel shows output destination")
	host._expect_text_contains(status, "下一步：样本过滤参数已确认", "reactor panel shows completion next step")
	host._expect_text_contains(
		String(panel_texts.get("recipes", "")),
		"> 2. 分析异常样本（当前目标）：可加工",
		"reactor recipe list marks selected target recipe"
	)
	host._expect_text_contains(
		String(panel_texts.get("operations", "")),
		"E 启动当前配方",
		"reactor panel exposes start action"
	)
	reactor.free()


func _check_pollution_filter_panel_hierarchy() -> void:
	var processing := ProcessingSystem.new(host.data_registry)
	var presenter := HudDevicePanelPresenter.new()
	var filter := PrototypeInteractable.new()
	filter.definition_id = "building.pollution_filter"
	filter.interaction_type = "process_recipe"
	filter.recipe_id = "recipe.cleanse_residue"
	filter.set_recipe_cycle(["recipe.cleanse_residue"])

	var world := WorldState.create_default()
	world.quest_state.active_quest_ids = ["quest.enter_pollution_edge"]
	world.quest_state.unlock_effect("recipe.cleanse_residue")
	world.add_base_structure("structure.pollution_filter_build_site", "building.pollution_filter", "region.pollution_edge")

	var character := CharacterState.create_default()
	character.inventory.add_item("item.polluted_residue", 2)
	var panel_texts := presenter.format_device_panel_texts(
		host.data_registry,
		processing,
		filter,
		character,
		world
	)
	var status := String(panel_texts.get("status", ""))
	host._expect_text_contains(
		String(panel_texts.get("title", "")),
		"设备面板：污染过滤器",
		"pollution filter panel title names device"
	)
	host._expect_text_contains(status, "设备状态：可启动", "pollution filter panel shows ready state")
	host._expect_text_contains(status, "当前配方：处理污染沉积物", "pollution filter panel names current recipe")
	host._expect_text_contains(
		status,
		"浆液可回基础反应器回收成基础零件",
		"pollution filter panel purpose shows slurry reclaim value"
	)
	host._expect_text_contains(status, "副产：污染浆液 x1", "pollution filter panel shows byproduct")
	host._expect_text_contains(
		status,
		"完成去向：产物入背包：抗污染药剂 I x1；副产入背包：污染浆液 x1",
		"pollution filter panel shows output and byproduct destination"
	)
	host._expect_text_contains(status, "下一步：带药剂回污染边界", "pollution filter panel shows field return")
	host._expect_text_contains(status, "清理受扰敌人和门前压力点", "pollution filter panel shows pressure cleanup")
	filter.free()


func _check_active_processing_panel_uses_running_recipe() -> void:
	var processing := ProcessingSystem.new(host.data_registry)
	var presenter := HudDevicePanelPresenter.new()
	var reactor := PrototypeInteractable.new()
	reactor.definition_id = "building.basic_reactor"
	reactor.interaction_type = "process_recipe"
	reactor.recipe_id = "recipe.process_crystal_ore"
	reactor.set_recipe_cycle(["recipe.process_crystal_ore", "recipe.reactor_calibrator"])

	var world := WorldState.create_default()
	world.quest_state.unlock_effect("recipe.process_crystal_ore")
	var character := CharacterState.create_default()
	character.inventory.add_item("item.crystal_ore", 3)
	var start_result := processing.process_recipe("recipe.process_crystal_ore", character, world)
	host._expect_equal(bool(start_result.get("success", false)), true, "reactor starts active processing")
	reactor.select_recipe("recipe.reactor_calibrator")

	var panel_texts := presenter.format_device_panel_texts(
		host.data_registry,
		processing,
		reactor,
		character,
		world
	)
	var status := String(panel_texts.get("status", ""))
	host._expect_text_contains(status, "设备状态：加工中", "active panel shows device busy state")
	host._expect_text_contains(status, "当前配方：处理晶体矿物", "active panel keeps running recipe")
	host._expect_text_contains(status, "进度：0 / 6 秒", "active panel shows progress")
	host._expect_text_contains(status, "下一步：等待设备完成", "active panel shows wait step")
	host._expect_text_contains(status, "完成后：基础零件已补足", "active panel shows completion followup")
	var recipes := String(panel_texts.get("recipes", ""))
	host._expect_text_contains(
		recipes,
		"1. 处理晶体矿物：加工中 0 / 6 秒",
		"active panel recipe list shows progress only on running recipe"
	)
	host._expect_text_contains(
		recipes,
		"> 2. 组装反应器校准件：设备忙碌",
		"active panel recipe list marks selected non-running recipe as busy"
	)
	host._expect_text_missing(
		recipes,
		"组装反应器校准件：加工中",
		"active panel recipe list does not copy progress to inactive recipe"
	)
	host._expect_text_contains(
		String(panel_texts.get("operations", "")),
		"E 等待加工完成",
		"active panel operation points to waiting"
	)
	reactor.free()
