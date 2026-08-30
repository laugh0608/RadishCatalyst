class_name SliceWorld
extends Node2D

## Authoritative runtime for the seamless base / expedition map. Narrow
## collaborators own placement queries, logistics, presentation and save timing;
## startup_load selects deterministic restoration before the first save.

const MAP_SCENE := "res://scenes/slice/SliceMap.tscn"
const PLAYER_SCENE := "res://scenes/slice/SlicePlayer.tscn"
const HUD_SCENE := "res://scenes/slice/SliceHud.tscn"
const CRAFT_PANEL_SCENE := "res://scenes/slice/SliceCraftPanel.tscn"
const CORE_STORAGE_PANEL_SCENE := "res://scenes/slice/SliceCoreStoragePanel.tscn"
const CORE_CHARGE_PANEL_SCENE := "res://scenes/slice/SliceCoreChargePanel.tscn"
const BUILDING_ACTION_PANEL_SCENE := "res://scenes/slice/SliceBuildingActionPanel.tscn"
const PAUSE_MENU_SCENE := "res://scenes/slice/SlicePauseMenu.tscn"
const COMBAT_CONTROLLER_SCENE := "res://scenes/slice/SliceCombatController.tscn"
const DEMO_COMPLETION_CARD_SCENE := "res://scenes/slice/SliceDemoCompletionCard.tscn"
const REPAIRED_CORE_TEXTURE := preload("res://assets/sprites/slice/outpost_core_repaired.png")
const MAP_PIXEL_SIZE := Vector2i(2560, 768)
const START_SPAWN := Vector2(400, 576)
const TILE_SIZE := 32.0

const ITEM_CRYSTAL := SliceItemCatalog.CRYSTAL_ID
const ITEM_CATALYST := SliceItemCatalog.CATALYST_ID
const ITEM_PART := SliceItemCatalog.PART_ID
const ITEM_PULSE_RIFLE := SliceItemCatalog.PULSE_RIFLE_ID
const ITEM_PULSE_CELL := SliceItemCatalog.PULSE_CELL_ID
const ITEM_FLOOR_KIT := SliceBuildingCatalog.FLOOR_ID
const ITEM_COLLECTOR_KIT := SliceBuildingCatalog.COLLECTOR_ID
const ITEM_REACTOR_KIT := SliceBuildingCatalog.REACTOR_ID
const ITEM_POWER_RELAY_KIT := SliceBuildingCatalog.POWER_RELAY_ID
const ITEM_CONVEYOR_KIT := SliceBuildingCatalog.CONVEYOR_ID
const ITEM_STORAGE_KIT := SliceBuildingCatalog.STORAGE_ID
const POCKET_CAPACITY := 30
const CORE_STORAGE_CAPACITY := 120
const CORE_DIRECT_POWER_RANGE := 192.0

const COLLECTOR_PRODUCE_INTERVAL := 1.0
const REACTOR_INPUT_PER_BATCH := 2
const REACTOR_OUTPUT_PER_BATCH := 1
const REACTOR_PRODUCE_INTERVAL := 10.0
const CORE_CHARGE_TARGET := 2
const ROCK_GROUND_SOURCE_ID := 0
const CRYSTAL_GROUND_SOURCE_ID := 2
const CORE_LINK_ANCHOR_OFFSET := SliceCoreLogistics.POWER_VISUAL_ANCHOR_OFFSET
const RELAY_LINK_ANCHOR_OFFSET := Vector2(0, -44)

## Emitted whenever the player backpack contents change (drives HUD refresh).
signal inventory_changed
signal core_storage_changed
signal building_storage_changed(instance_id: String)
signal core_charge_changed(energy: int)
signal core_repair_completed
signal placement_changed
signal return_to_startup_requested

## Set by Boot before add_child: true loads the saved slice, false starts fresh.
var startup_load := false

## Player backpack (spatial crystal/catalyst store, capacity-limited).
var pocket := Inventory.new(SliceInventoryProfiles.category_pocket())
var core_storage := Inventory.new(SliceInventoryProfiles.category_core_storage())
var core_repaired := false
var core_energy := 0
var harvested_clusters: Array[String] = []

var player: SlicePlayer
var combat_controller: SliceCombatController
var first_journey: SliceFirstJourneyController

## Injected by Boot so menu summary and world reads/writes share one service.
## Standalone scene checks keep the production default unless they replace it.
var save_service := SliceSaveService.new()
var _map: Node2D
var _craft_panel: SliceCraftPanel
var _core_storage_panel: SliceCoreStoragePanel
var _core_charge_panel: SliceCoreChargePanel
var _building_action_panel: SliceBuildingActionPanel
var pause_menu: SlicePauseMenu
var _ground: TileMapLayer
var _industrial_floor: TileMapLayer
var _placement: SliceBuildingPlacementController
var _placement_pointer := SlicePlacementPointerInput.new()
var _placement_validator := SlicePlacementValidator.new()
var _support_floor_transaction := SlicePlacementSupportFloorTransaction.new()
var _occupancy := SliceBuildingOccupancy.new()
var _power_grid := SlicePowerGrid.new()
var _logistics_grid := SliceLogisticsGrid.new()
var _core_logistics := SliceCoreLogistics.new()
var _logistics_transitions: SliceLogisticsTransitionLayer
var _power_links: SlicePowerLinkLayer
var _building_instances: Array[SliceBuildingInstance] = []
var _collector_nodes: Array[SliceCollector] = []
var _reactor_nodes: Array[SliceReactor] = []
var _storage_nodes: Array[SliceStorage] = []
var _adjustment_instance: SliceBuildingInstance
var _adjustment_original_cell := Vector2i.ZERO
var _adjustment_original_rotation := 0
var _next_building_serial := 1
var _save_scheduler := SliceSaveScheduler.new()


func _ready() -> void:
	_save_scheduler.setup(save_service)
	_map = (load(MAP_SCENE) as PackedScene).instantiate()
	add_child(_map)
	_ground = _map.get_node("GroundLayer")
	_industrial_floor = _map.get_node("IndustrialFloorLayer")
	_logistics_transitions = _map.get_node("GroundStructures/LogisticsTransitions")
	var world_node := _map.get_node("World")
	_power_links = SlicePowerLinkLayer.new()
	_power_links.name = "PowerLinks"
	world_node.add_child(_power_links)

	player = (load(PLAYER_SCENE) as PackedScene).instantiate() as SlicePlayer
	player.world = self
	world_node.add_child(player)
	player.position = START_SPAWN
	combat_controller = (
		(load(COMBAT_CONTROLLER_SCENE) as PackedScene).instantiate()
		as SliceCombatController
	)
	world_node.add_child(combat_controller)
	combat_controller.setup(self, player)
	combat_controller.persistence_requested.connect(
		_on_combat_persistence_requested
	)
	first_journey = SliceFirstJourneyController.new()
	first_journey.name = "FirstJourney"
	add_child(first_journey)
	first_journey.setup(self, player)

	var camera := player.get_node("Camera") as Camera2D
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = MAP_PIXEL_SIZE.x
	camera.limit_bottom = MAP_PIXEL_SIZE.y

	var hud := (load(HUD_SCENE) as PackedScene).instantiate() as SliceHud
	add_child(hud)
	hud.setup(self, player)
	var demo_card := (load(DEMO_COMPLETION_CARD_SCENE) as PackedScene).instantiate() as SliceDemoCompletionCard
	add_child(demo_card)
	demo_card.setup(self)

	_craft_panel = (load(CRAFT_PANEL_SCENE) as PackedScene).instantiate() as SliceCraftPanel
	add_child(_craft_panel)
	_craft_panel.setup(self)
	_craft_panel.terminal_opened.connect(first_journey.mark_terminal_opened)
	_craft_panel.recipe_inspected.connect(first_journey.mark_recipe_inspected)

	_core_storage_panel = (load(CORE_STORAGE_PANEL_SCENE) as PackedScene).instantiate() as SliceCoreStoragePanel
	add_child(_core_storage_panel)
	_core_storage_panel.setup(self)

	_core_charge_panel = (
		(load(CORE_CHARGE_PANEL_SCENE) as PackedScene).instantiate()
		as SliceCoreChargePanel
	)
	add_child(_core_charge_panel)
	_core_charge_panel.setup(self)

	_building_action_panel = (
		(load(BUILDING_ACTION_PANEL_SCENE) as PackedScene).instantiate()
		as SliceBuildingActionPanel
	)
	add_child(_building_action_panel)
	_building_action_panel.setup(self)
	var power_link_presenter := SlicePowerLinkPresenter.new()
	add_child(power_link_presenter)
	power_link_presenter.setup(self, _power_links, _building_action_panel)

	pause_menu = (
		(load(PAUSE_MENU_SCENE) as PackedScene).instantiate()
		as SlicePauseMenu
	)
	add_child(pause_menu)
	pause_menu.save_and_return_requested.connect(
		_on_pause_save_and_return_requested
	)
	pause_menu.save_and_quit_requested.connect(
		_on_pause_save_and_quit_requested
	)

	_placement = SliceBuildingPlacementController.new()
	_map.add_child(_placement)
	_placement_validator.setup(
		self,
		_ground,
		_occupancy,
		_power_grid,
		player,
		MAP_PIXEL_SIZE,
		TILE_SIZE,
		ROCK_GROUND_SOURCE_ID,
		CRYSTAL_GROUND_SOURCE_ID
	)
	_support_floor_transaction.setup(
		_ground,
		_occupancy,
		_industrial_floor,
		_building_instances
	)

	var restore_succeeded := true
	if startup_load:
		restore_succeeded = _restore_from_save()
	_refresh_core_charge_visual()
	_rebuild_power_grid()
	_rebuild_logistics_grid()
	_save_scheduler.set_write_blocked(
		startup_load and not restore_succeeded
	)
	if (
		startup_load
		and restore_succeeded
		and not _save_scheduler.pending_load_context().is_empty()
		and not save_now()
	):
		push_warning("旧档已完成世界重建，但 schema 10 发布失败；后续保存将继续重试。")


func _physics_process(delta: float) -> void:
	_tick_logistics(delta)
	if not is_placement_active() or player == null:
		return
	_placement_pointer.release_if_button_up()
	_refresh_placement_target()


func _refresh_placement_target() -> void:
	if not is_placement_active() or player == null:
		return
	var target_point := (
		_placement.world_position_from_screen(
			_placement_pointer.screen_position
		)
		if _placement_pointer.pointer_target_active
		else player.position + player.facing * 64.0
	)
	var definition := _placement.definition
	var origin := definition.origin_for_target(
		target_point, TILE_SIZE, _placement.rotation_index
	)
	var validation := _validate_placement(
		definition, origin, _placement.rotation_index
	)
	_placement.update_target(
		origin,
		definition.block_center(
			origin, TILE_SIZE, _placement.rotation_index
		),
		validation,
		TILE_SIZE,
		_power_grid.placement_preview_nodes(),
		_logistics_grid.placement_preview_ports()
	)


func _tick_logistics(delta: float) -> void:
	var result := _logistics_grid.tick(delta)
	if not bool(result.get("changed", false)):
		return
	for instance_id in result.get("storage_ids", []):
		if String(instance_id) == SliceCoreLogistics.INSTANCE_ID:
			core_storage_changed.emit()
		else:
			building_storage_changed.emit(String(instance_id))
	request_save()


func _process(delta: float) -> void:
	_tick_production(delta)
	_tick_save_scheduler(delta)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if is_placement_active():
			cancel_building_placement()
		elif _craft_panel != null and _craft_panel.is_open():
			_craft_panel.close()
		elif is_core_storage_open():
			close_core_storage()
		elif is_core_charge_confirmation_open():
			close_core_charge_confirmation()
		elif is_building_actions_open():
			close_building_actions()
		elif pause_menu != null:
			combat_controller.require_fresh_attack_press()
			pause_menu.open()
		get_viewport().set_input_as_handled()
		return
	if not is_placement_active():
		return
	if (
		event is InputEventMouseMotion
		or event is InputEventMouseButton
	):
		if _handle_placement_pointer_event(
			event, _pointer_over_blocking_ui()
		):
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("rotate_building"):
		rotate_building_placement()
		get_viewport().set_input_as_handled()


func _handle_placement_pointer_event(
	event: InputEvent,
	ui_blocked: bool = false
) -> bool:
	if not is_placement_active() or not _placement_pointer.track_event(event):
		return false
	_refresh_placement_target()
	var definition := _placement.definition
	if _placement_pointer.should_confirm(
		event,
		_placement.target_origin,
		definition.is_floor,
		ui_blocked
	):
		try_place_building()
	return true


func _pointer_over_blocking_ui() -> bool:
	var hovered := get_viewport().gui_get_hovered_control()
	return (
		hovered != null
		and hovered.mouse_filter != Control.MOUSE_FILTER_IGNORE
	)


## Powered collectors and reactors retain their own tick progress. All mutable
## production state enters the shared save scheduler instead of owning a second
## checkpoint timer here.
func _tick_production(delta: float) -> void:
	var produced := false
	for collector in _collector_nodes:
		if not collector.powered:
			continue
		collector.production_progress += delta
		while collector.production_progress >= COLLECTOR_PRODUCE_INTERVAL:
			collector.production_progress -= COLLECTOR_PRODUCE_INTERVAL
			if collector.has_space():
				collector.produce(1)
				produced = true

	var reactor_changed := false
	var reactor_transition := false
	for reactor in _reactor_nodes:
		var result := reactor.tick(delta)
		if not bool(result.get("changed", false)):
			continue
		reactor_changed = true
		if (
			bool(result.get("started", false))
			or bool(result.get("completed", false))
		):
			reactor_transition = true
			building_storage_changed.emit(reactor.instance_id)

	var storage_changed := false
	var storage_transferred := false
	for storage in _storage_nodes:
		var transfer_result := storage.tick_wireless_transfer(
			delta, core_repaired, core_storage
		)
		if not bool(transfer_result.get("changed", false)):
			continue
		storage_changed = true
		var moved := int(transfer_result.get("moved", 0))
		if moved > 0:
			storage_transferred = true
			building_storage_changed.emit(storage.instance_id)
			core_storage_changed.emit()

	if (
		produced
		or reactor_changed
		or reactor_transition
		or storage_changed
		or storage_transferred
	):
		request_save()


## Harvest a crystal cluster into the backpack. Returns false (leaving the
## cluster in place) if the backpack cannot hold the full yield.
func harvest_crystals(cluster_name: String, amount: int) -> bool:
	if pocket.free_space_for(ITEM_CRYSTAL) < amount:
		return false
	if not harvested_clusters.has(cluster_name):
		harvested_clusters.append(cluster_name)
	pocket.add(ITEM_CRYSTAL, amount)
	inventory_changed.emit()
	request_save()
	return true


## Move a collector's output buffer into the backpack, bounded by free space.
func collect_from_collector(collector: SliceCollector) -> int:
	if collector.buffer <= 0:
		return 0
	var moved := pocket.add(ITEM_CRYSTAL, collector.buffer)
	if moved <= 0:
		return 0
	collector.buffer -= moved
	inventory_changed.emit()
	request_save()
	return moved

## Spend a specific item from the backpack (e.g. mechanical parts for repair).
func spend_pocket_item(item: String, amount: int) -> bool:
	if pocket.count(item) < amount:
		return false
	pocket.remove(item, amount)
	inventory_changed.emit()
	request_save()
	return true


func mark_core_repaired() -> void:
	core_repaired = true
	SliceCoreLogistics.apply_repaired_visual(
		_core_visual(), REPAIRED_CORE_TEXTURE
	)
	_refresh_core_charge_visual()
	_rebuild_power_grid()
	_rebuild_logistics_grid()
	core_repair_completed.emit()
	save_now()


func is_core_power_online() -> bool:
	return core_repaired


## Fixed L2 direct supply around the repaired core. L3 relays extend this
## source; consumers should query this method rather than duplicating range
## rules or treating core repair as machine power implicitly.
func is_position_core_powered(world_position: Vector2) -> bool:
	if not core_repaired:
		return false
	var core := _map.get_node_or_null("World/OutpostCoreDamaged") as Node2D
	return core != null and core.global_position.distance_to(world_position) <= CORE_DIRECT_POWER_RANGE


func is_building_powered(instance: SliceBuildingInstance) -> bool:
	return instance != null and instance.powered


func powered_relay_count() -> int:
	return _power_grid.powered_relay_count()


func current_journey_guidance() -> Dictionary:
	return first_journey.guidance()


func current_journey_goal_text() -> String:
	return String(current_journey_guidance().get("goal", ""))


func current_journey_rule_text() -> String:
	return String(current_journey_guidance().get("rule", ""))


func relay_disconnect_impact_count(relay: SliceBuildingInstance) -> int:
	if (
		relay == null
		or relay.definition == null
		or relay.definition.power_role
		!= SliceBuildingDefinition.POWER_RELAY
	):
		return 0
	var candidate := SlicePowerGrid.new()
	candidate.rebuild(
		core_repaired,
		_core_world_position(),
		TILE_SIZE,
		_building_instances,
		relay.instance_id
	)
	var affected := 0
	for instance in _building_instances:
		if (
			instance.definition != null
			and instance.definition.power_role
			== SliceBuildingDefinition.POWER_CONSUMER
			and instance.powered
			and not candidate.is_consumer_powered(instance)
		):
			affected += 1
	return affected


func open_core_storage() -> bool:
	if not core_repaired or _core_storage_panel == null:
		return false
	if _craft_panel != null:
		_craft_panel.close()
	close_core_charge_confirmation()
	close_building_actions()
	_core_storage_panel.open()
	return true


func close_core_storage() -> void:
	if _core_storage_panel != null:
		_core_storage_panel.close()


func is_core_storage_open() -> bool:
	return _core_storage_panel != null and _core_storage_panel.is_open()


func open_core_charge_confirmation() -> bool:
	if not can_charge_core() or _core_charge_panel == null:
		return false
	close_core_storage()
	close_building_actions()
	if _craft_panel != null:
		_craft_panel.close()
	_core_charge_panel.open()
	return true


func close_core_charge_confirmation() -> void:
	if _core_charge_panel != null:
		_core_charge_panel.close()


func is_core_charge_confirmation_open() -> bool:
	return (
		_core_charge_panel != null
		and _core_charge_panel.is_open()
	)


## Moves as much of one item as possible from the backpack into the repaired
## core warehouse. Returns the amount moved; the add-before-remove ordering
## makes a capacity-limited transfer lossless.
func transfer_pocket_to_core(item: String, requested_amount: int = -1) -> int:
	if not core_repaired:
		return 0
	var amount := (
		pocket.count(item)
		if requested_amount < 0
		else requested_amount
	)
	var moved := pocket.transfer_up_to(
		core_storage, item, amount
	)
	if moved <= 0:
		return 0
	inventory_changed.emit()
	core_storage_changed.emit()
	request_save()
	return moved


## Moves as much of one item as the backpack can accept from the core store.
func transfer_core_to_pocket(item: String, requested_amount: int = -1) -> int:
	if not core_repaired:
		return 0
	var amount := (
		core_storage.count(item)
		if requested_amount < 0
		else requested_amount
	)
	var moved := core_storage.transfer_up_to(
		pocket, item, amount
	)
	if moved <= 0:
		return 0
	inventory_changed.emit()
	core_storage_changed.emit()
	request_save()
	return moved


func transfer_pocket_to_storage(
	storage: SliceStorage, item: String, requested_amount: int = -1
) -> int:
	if (
		storage == null
		or not _building_instances.has(storage)
	):
		return 0
	var moved := storage.manual_deposit(pocket, item, requested_amount)
	if moved <= 0:
		return 0
	inventory_changed.emit()
	building_storage_changed.emit(storage.instance_id)
	request_save()
	return moved


func transfer_storage_to_pocket(
	storage: SliceStorage, item: String, requested_amount: int = -1
) -> int:
	if (
		storage == null
		or not _building_instances.has(storage)
	):
		return 0
	var moved := storage.manual_withdraw(pocket, item, requested_amount)
	if moved <= 0:
		return 0
	inventory_changed.emit()
	building_storage_changed.emit(storage.instance_id)
	request_save()
	return moved


func toggle_storage_mode(storage: SliceStorage) -> bool:
	if storage == null or not _building_instances.has(storage):
		return false
	if not storage.toggle_mode():
		return false
	_rebuild_logistics_grid()
	building_storage_changed.emit(storage.instance_id)
	request_save()
	return true


func select_next_storage_output(storage: SliceStorage) -> bool:
	if storage == null or not _building_instances.has(storage):
		return false
	if not storage.select_next_present_output():
		return false
	building_storage_changed.emit(storage.instance_id)
	request_save()
	return true


func reactor_status_text(reactor: SliceReactor) -> String:
	if reactor == null or not _building_instances.has(reactor):
		return "设备已失效"
	return reactor.operation_status_text(
		_logistics_grid.can_extract_reactor_output(reactor)
	)


func building_logistics_status_lines(
	instance: SliceBuildingInstance
) -> Array[String]:
	return _logistics_grid.building_status_lines(instance)


func building_logistics_status_snapshot(
	instance: SliceBuildingInstance
) -> Array[Dictionary]:
	return _logistics_grid.building_status_snapshot(instance)


func recover_reactor_contents(reactor: SliceReactor) -> Dictionary:
	if reactor == null or not _building_instances.has(reactor):
		return {
			"success": false,
			"message": "反应器已失效",
		}
	var result := reactor.recover_contents_to(pocket)
	if not bool(result.get("success", false)):
		return result
	inventory_changed.emit()
	building_storage_changed.emit(reactor.instance_id)
	request_save()
	return result


func recover_conveyor_cargo(conveyor: SliceConveyor) -> Dictionary:
	if conveyor == null or not _building_instances.has(conveyor):
		return {"success": false, "message": "传送带已失效"}
	if not conveyor.has_cargo():
		return {"success": false, "message": "传送带上没有货物"}
	var item_id := conveyor.cargo_item_id
	if pocket.free_space_for(item_id) <= 0:
		return {"success": false, "message": "背包中该物品已达上限"}
	if pocket.add(item_id, 1) != 1:
		return {"success": false, "message": "货物回收失败"}
	conveyor.clear_cargo()
	inventory_changed.emit()
	building_storage_changed.emit(conveyor.instance_id)
	request_save()
	return {"success": true, "message": "已回收 1 件货物"}


func transfer_all_building_kits_to_core() -> int:
	if not core_repaired:
		return 0
	var moved_total := 0
	for definition in SliceBuildingCatalog.all():
		var item := definition.kit_item_id
		moved_total += pocket.transfer_up_to(
			core_storage, item, pocket.count(item)
		)
	if moved_total > 0:
		inventory_changed.emit()
		core_storage_changed.emit()
		request_save()
	return moved_total


func transfer_all_building_kits_to_pocket() -> int:
	if not core_repaired:
		return 0
	var moved_total := 0
	for definition in SliceBuildingCatalog.all():
		var item := definition.kit_item_id
		moved_total += core_storage.transfer_up_to(
			pocket, item, core_storage.count(item)
		)
	if moved_total > 0:
		inventory_changed.emit()
		core_storage_changed.emit()
		request_save()
	return moved_total


func is_core_charged() -> bool:
	return core_energy >= CORE_CHARGE_TARGET


func core_charge_required() -> int:
	return maxi(0, CORE_CHARGE_TARGET - core_energy)


func core_charge_available() -> int:
	return (
		core_storage.count(ITEM_CATALYST)
		+ pocket.count(ITEM_CATALYST)
	)


func can_charge_core() -> bool:
	return (
		core_repaired
		and not is_core_charged()
		and core_charge_available() >= core_charge_required()
	)


func can_deliver_critical_sample() -> bool:
	return (
		core_repaired
		and is_core_charged()
		and combat_controller != null
		and combat_controller.can_deliver_critical_sample()
	)


func deliver_critical_sample() -> bool:
	if not can_deliver_critical_sample():
		return false
	if not combat_controller.deliver_critical_sample():
		return false
	_refresh_core_charge_visual()
	return true


func confirm_core_charge() -> bool:
	var charged := charge_core()
	if charged:
		close_core_charge_confirmation()
	return charged


## Deterministically consumes the repaired core's authoritative inventories:
## central storage first, backpack second. The operation is all-or-nothing.
func charge_core() -> bool:
	if not can_charge_core():
		return false
	var required := core_charge_required()
	var from_core := mini(required, core_storage.count(ITEM_CATALYST))
	var from_pocket := required - from_core
	if from_core > 0:
		core_storage.remove(ITEM_CATALYST, from_core)
	if from_pocket > 0:
		pocket.remove(ITEM_CATALYST, from_pocket)
	core_energy += required
	if from_core > 0:
		core_storage_changed.emit()
	if from_pocket > 0:
		inventory_changed.emit()
	core_charge_changed.emit(core_energy)
	_refresh_core_charge_visual()
	save_now()
	return true


func is_combat_input_blocked() -> bool:
	return (
		is_placement_active()
		or (_craft_panel != null and _craft_panel.is_open())
		or is_core_storage_open()
		or is_core_charge_confirmation_open()
		or is_building_actions_open()
		or (pause_menu != null and pause_menu.is_open())
	)


func _refresh_core_charge_visual() -> void:
	if _map == null:
		return
	var core_visual := _core_visual()
	if core_visual == null:
		return
	core_visual.apply_feedback_state(SliceDeviceFeedbackState.core_state(
		core_repaired,
		is_core_charged(),
		combat_controller != null
		and combat_controller.encounter_state == "delivered"
	))


## Craft a recipe into backpack property. Placement is a separate player action
## through the manufacturing panel's existing-kit entry.
func craft(recipe_id: String) -> bool:
	var recipe := SliceRecipes.find(recipe_id)
	if recipe.is_empty():
		return false
	var kind := String(recipe["kind"])
	if not SliceRecipes.craft_block_reason(
		recipe, pocket, core_storage, is_core_charged()
	).is_empty():
		return false
	var output_count := int(recipe.get("output_count", 1))
	if kind == "building":
		var definition := SliceBuildingCatalog.find(String(recipe["building_id"]))
		if definition == null:
			return false
	if not pocket.exchange(
		recipe["cost"],
		{String(recipe["output"]): output_count}
	):
		push_error("Craft inventory changed after authoritative validation.")
		return false
	inventory_changed.emit()
	save_now()
	return true


func can_afford(cost: Dictionary) -> bool:
	for item in cost:
		if pocket.count(String(item)) < int(cost[item]):
			return false
	return true


func select_building_kit(building_id: String) -> bool:
	var definition := SliceBuildingCatalog.find(building_id)
	if definition == null or pocket.count(definition.kit_item_id) <= 0:
		return false
	begin_building_placement(building_id)
	return true


func begin_building_placement(building_id: String) -> bool:
	var definition := SliceBuildingCatalog.find(building_id)
	if definition == null or pocket.count(definition.kit_item_id) <= 0:
		return false
	if _adjustment_instance != null:
		cancel_building_placement()
	close_core_storage()
	close_core_charge_confirmation()
	close_building_actions()
	if _craft_panel != null:
		_craft_panel.close()
	_placement.begin(definition)
	_placement_pointer.begin()
	placement_changed.emit()
	return true


func cancel_building_placement() -> void:
	if not is_placement_active():
		return
	if _adjustment_instance != null:
		_restore_adjustment_origin()
	_placement.cancel()
	_placement_pointer.cancel()
	placement_changed.emit()


func rotate_building_placement() -> void:
	if not is_placement_active():
		return
	_placement.rotate_clockwise()
	placement_changed.emit()


func try_place_building() -> bool:
	if not is_placement_active() or not _placement.target_valid:
		return false
	var definition := _placement.definition
	var support_result := _support_floor_transaction.create(
		definition,
		_placement.missing_floor_cells(),
		pocket,
		Callable(self, "_spawn_building")
	)
	if not bool(support_result.get("success", false)):
		return false
	var support_floors: Array[SliceBuildingInstance] = []
	for value in support_result.get("instances", []):
		support_floors.append(value as SliceBuildingInstance)
	if _adjustment_instance != null:
		_commit_adjustment(
			_placement.target_origin,
			_placement.rotation_index
		)
		_support_floor_transaction.commit_cost(pocket, support_floors)
		_placement.cancel()
		_placement_pointer.cancel()
		placement_changed.emit()
		inventory_changed.emit()
		save_now()
		return true
	if pocket.count(definition.kit_item_id) <= 0:
		_support_floor_transaction.rollback(support_floors)
		cancel_building_placement()
		return false
	var instance := _spawn_building(
		definition,
		"",
		_placement.target_origin,
		_placement.rotation_index,
		{}
	)
	if instance == null:
		_support_floor_transaction.rollback(support_floors)
		return false
	_support_floor_transaction.commit_cost(pocket, support_floors)
	pocket.remove(definition.kit_item_id, 1)
	if pocket.count(definition.kit_item_id) <= 0:
		cancel_building_placement()
	else:
		placement_changed.emit()
	inventory_changed.emit()
	save_now()
	return true


func is_place_target_valid() -> bool:
	return is_placement_active() and _placement.target_valid


func placement_invalid_reason() -> String:
	return "" if not is_placement_active() else _placement.invalid_reason


func is_placement_active() -> bool:
	return _placement != null and _placement.is_active()


func selected_building_id() -> String:
	return "" if not is_placement_active() else _placement.selected_building_id()


func selected_building_name() -> String:
	return "" if not is_placement_active() else _placement.definition.display_name


func selected_building_rotation() -> int:
	return 0 if not is_placement_active() else _placement.rotation_index


func placement_auto_floor_count() -> int:
	return 0 if not is_placement_active() else (
		_placement.missing_floor_cells().size()
	)


func placement_logistics_feedback() -> String:
	return (
		""
		if not is_placement_active()
		else _placement.logistics_feedback_text()
	)


func open_building_actions(instance: SliceBuildingInstance) -> void:
	if instance == null or not _building_instances.has(instance):
		return
	if is_placement_active():
		return
	close_core_storage()
	close_core_charge_confirmation()
	if _craft_panel != null:
		_craft_panel.close()
	_building_action_panel.open(instance)


func close_building_actions() -> void:
	if _building_action_panel != null:
		_building_action_panel.close()


func is_building_actions_open() -> bool:
	return (
		_building_action_panel != null
		and _building_action_panel.is_open()
	)


func adjustment_block_reason(instance: SliceBuildingInstance) -> String:
	if instance == null or not _building_instances.has(instance):
		return "建筑已失效"
	if instance.definition.is_floor and _floor_supports_facility(instance):
		return "地板上有设施"
	if instance is SliceConveyor or instance is SliceReactor:
		var content_reason := instance.content_block_reason()
		if not content_reason.is_empty():
			return content_reason
	return ""


func begin_building_adjustment(instance: SliceBuildingInstance) -> bool:
	if not adjustment_block_reason(instance).is_empty():
		return false
	if is_placement_active():
		cancel_building_placement()
	close_building_actions()
	_adjustment_instance = instance
	_adjustment_original_cell = instance.origin_cell
	_adjustment_original_rotation = instance.building_rotation
	_occupancy.release(instance.instance_id)
	if instance.definition.is_floor:
		_industrial_floor.erase_cell(instance.origin_cell)
	instance.set_adjustment_hidden(true)
	_placement.begin(instance.definition, instance.building_rotation)
	_rebuild_power_grid(instance.instance_id)
	_rebuild_logistics_grid(instance.instance_id)
	placement_changed.emit()
	return true


func demolition_block_reason(instance: SliceBuildingInstance) -> String:
	if instance == null or not _building_instances.has(instance):
		return "建筑已失效"
	if instance.definition.is_floor and _floor_supports_facility(instance):
		return "地板上有设施"
	var content_reason := instance.content_block_reason()
	if not content_reason.is_empty():
		return content_reason
	if pocket.free_space_for(instance.definition.kit_item_id) <= 0:
		return "背包空间不足"
	return ""


func demolish_building(instance: SliceBuildingInstance) -> bool:
	if not demolition_block_reason(instance).is_empty():
		return false
	close_building_actions()
	_occupancy.release(instance.instance_id)
	if instance.definition.is_floor:
		_industrial_floor.erase_cell(instance.origin_cell)
	_building_instances.erase(instance)
	if instance is SliceCollector:
		_collector_nodes.erase(instance as SliceCollector)
	elif instance is SliceReactor:
		_reactor_nodes.erase(instance as SliceReactor)
	elif instance is SliceStorage:
		_storage_nodes.erase(instance as SliceStorage)
	var returned := pocket.add(instance.definition.kit_item_id, 1)
	if returned != 1:
		push_error("Demolition capacity changed after validation.")
		return false
	instance.queue_free()
	_rebuild_power_grid()
	_rebuild_logistics_grid()
	inventory_changed.emit()
	placement_changed.emit()
	save_now()
	return true


func _validate_placement(
	definition: SliceBuildingDefinition,
	origin_cell: Vector2i,
	rotation: int
) -> Dictionary:
	var result := _placement_validator.validate(
		definition,
		origin_cell,
		rotation,
		pocket.count(ITEM_FLOOR_KIT),
		_active_logistics_approach_cells()
	)
	if definition.building_id == SliceBuildingCatalog.CONVEYOR_ID:
		result["logistics_preview"] = (
			_logistics_grid.conveyor_placement_preview(
				origin_cell, rotation
			)
		)
	return result


func _active_logistics_approach_cells() -> Array[Vector2i]:
	return _core_logistics.reserved_approach_cells(
		_building_instances, _adjustment_instance
	)


func _floor_supports_facility(instance: SliceBuildingInstance) -> bool:
	for cell in instance.definition.occupied_cells(
		instance.origin_cell, instance.building_rotation
	):
		if not _occupancy.blocking_instance_at(cell).is_empty():
			return true
	return false


func _rebuild_power_grid(excluded_instance_id: String = "") -> void:
	_power_grid.rebuild(
		core_repaired,
		_core_world_position(),
		TILE_SIZE,
		_building_instances,
		excluded_instance_id
	)
	for instance in _building_instances:
		if instance.definition == null:
			continue
		if instance.instance_id == excluded_instance_id:
			instance.set_powered(false)
		elif (
			instance.definition.power_role
			== SliceBuildingDefinition.POWER_RELAY
		):
			instance.set_powered(
				_power_grid.is_relay_powered(instance.instance_id)
			)
		elif (
			instance.definition.power_role
			== SliceBuildingDefinition.POWER_CONSUMER
		):
			instance.set_powered(
				_power_grid.is_consumer_powered(instance)
			)
	_refresh_power_links()


func _rebuild_logistics_grid(excluded_instance_id: String = "") -> void:
	var core := _map.get_node_or_null(
		"World/OutpostCoreDamaged"
	) as Node2D
	_core_logistics.setup(
		core, _core_visual(), core_storage, core_repaired, TILE_SIZE
	)
	_logistics_grid.rebuild(
		_building_instances,
		excluded_instance_id,
		_core_logistics.endpoints()
	)
	_logistics_transitions.set_transitions(
		_logistics_grid.placement_preview_ports(), TILE_SIZE
	)


func _refresh_power_links() -> void:
	if _power_links == null:
		return
	_power_links.set_links(SlicePowerVisualResolver.resolve_links(
		_power_grid.powered_connections(),
		_building_instances,
		CORE_LINK_ANCHOR_OFFSET,
		RELAY_LINK_ANCHOR_OFFSET
	))


func _core_world_position() -> Vector2:
	if _map == null:
		return Vector2.ZERO
	var core := _map.get_node_or_null("World/OutpostCoreDamaged") as Node2D
	return Vector2.ZERO if core == null else core.global_position


func _core_visual() -> SliceCoreVisual:
	if _map == null:
		return null
	return _map.get_node_or_null(
		"World/OutpostCoreVisualSortShell"
	) as SliceCoreVisual


func _restore_adjustment_origin() -> void:
	var instance := _adjustment_instance
	if instance == null:
		return
	_place_existing_instance(
		instance,
		_adjustment_original_cell,
		_adjustment_original_rotation
	)
	_adjustment_instance = null


func _commit_adjustment(origin_cell: Vector2i, rotation: int) -> void:
	var instance := _adjustment_instance
	if instance == null:
		return
	_place_existing_instance(instance, origin_cell, rotation)
	_adjustment_instance = null


func _place_existing_instance(
	instance: SliceBuildingInstance,
	origin_cell: Vector2i,
	rotation: int
) -> void:
	var definition := instance.definition
	instance.configure_building(
		instance.instance_id,
		instance.building_id,
		origin_cell,
		definition.normalized_rotation(rotation)
	)
	instance.position = definition.sort_anchor_world_position(
		origin_cell, TILE_SIZE, instance.building_rotation
	)
	instance.apply_definition(definition, TILE_SIZE)
	instance.set_adjustment_hidden(false)
	_occupancy.occupy(
		instance.instance_id,
		definition.occupied_cells(origin_cell, instance.building_rotation),
		definition.is_floor
	)
	if definition.is_floor:
		_industrial_floor.set_cell(
			origin_cell, 0, _floor_atlas_coords(origin_cell), 0
		)
	_rebuild_power_grid()
	_rebuild_logistics_grid()


func _spawn_building(
	definition: SliceBuildingDefinition,
	requested_id: String,
	origin_cell: Vector2i,
	rotation: int,
	state: Dictionary
) -> SliceBuildingInstance:
	var instance: SliceBuildingInstance
	if definition.scene_path.is_empty():
		instance = SliceBuildingInstance.new()
	else:
		instance = (
			(load(definition.scene_path) as PackedScene).instantiate()
			as SliceBuildingInstance
		)
	if instance == null:
		push_error("Building scene root must extend SliceBuildingInstance.")
		return null

	var instance_id := requested_id
	if instance_id.is_empty():
		instance_id = _allocate_building_id()
	instance.configure_building(
		instance_id,
		definition.building_id,
		origin_cell,
		definition.normalized_rotation(rotation)
	)
	instance.position = definition.sort_anchor_world_position(
		origin_cell, TILE_SIZE, instance.building_rotation
	)
	instance.apply_definition(definition, TILE_SIZE)
	if instance is SliceCollector:
		var collector := instance as SliceCollector
		collector.buffer = clampi(
			int(state.get("buffer", 0)), 0, SliceCollector.BUFFER_CAP
		)
		collector.production_progress = clampf(
			float(state.get("production_progress", 0.0)),
			0.0,
			COLLECTOR_PRODUCE_INTERVAL
		)
		_collector_nodes.append(collector)
	elif instance is SliceReactor:
		var reactor := instance as SliceReactor
		reactor.input_inventory = Inventory.from_dict(
			state.get("input_inventory", {}),
			SliceInventoryProfiles.device_reactor_input()
		)
		reactor.output_inventory = Inventory.from_dict(
			state.get("output_inventory", {}),
			SliceInventoryProfiles.device_reactor_output()
		)
		reactor.processing = bool(state.get("processing", false))
		reactor.production_progress = float(
			state.get("production_progress", 0.0)
		)
		_reactor_nodes.append(reactor)
	elif instance is SliceConveyor:
		var conveyor := instance as SliceConveyor
		var cargo: Dictionary = state.get("cargo", {})
		if not cargo.is_empty():
			conveyor.set_cargo(
				String(cargo.get("item_id", "")),
				float(cargo.get("progress", 0.0))
			)
		conveyor.merge_cursor = int(state.get("merge_cursor", 0))
	elif instance is SliceStorage:
		var storage := instance as SliceStorage
		storage.restore_state(state)
		_storage_nodes.append(storage)

	var layer_name := (
		"GroundStructures"
		if definition.spatial_layer == SliceBuildingDefinition.SPATIAL_LAYER_GROUND
		else "World"
	)
	_map.get_node(layer_name).add_child(instance)
	_building_instances.append(instance)
	_occupancy.occupy(
		instance.instance_id,
		definition.occupied_cells(origin_cell, instance.building_rotation),
		definition.is_floor
	)
	if definition.is_floor:
		_industrial_floor.set_cell(
			origin_cell, 0, _floor_atlas_coords(origin_cell), 0
		)
	else:
		_rebuild_power_grid()
	_rebuild_logistics_grid()
	return instance


func _allocate_building_id() -> String:
	var instance_id := "building-%06d" % _next_building_serial
	_next_building_serial += 1
	return instance_id


func _floor_atlas_coords(cell: Vector2i) -> Vector2i:
	return Vector2i(posmod(cell.x + cell.y, 4), 0)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_now()


func _restore_from_save() -> bool:
	var result := save_service.load_state()
	if not bool(result.get("success", false)):
		push_warning("切片读档失败，按新档继续：%s" % String(result.get("message", "")))
		return false
	var pending_load_context := (
		(result.get("load_context", {}) as Dictionary).duplicate(true)
		if bool(result.get("publish_required", false))
		else {}
	)
	_save_scheduler.set_pending_load_context(pending_load_context)

	var data: Dictionary = result.get("data", {})
	pocket = Inventory.from_dict(
		data.get("pocket", {}), SliceInventoryProfiles.category_pocket()
	)
	core_storage = Inventory.from_dict(
		data.get("core_storage", {}),
		SliceInventoryProfiles.category_core_storage()
	)
	core_repaired = bool(data.get("core_repaired", false))
	core_energy = int(data.get("core_energy", 0))
	harvested_clusters = SliceSaveService.canonical_string_array(
		data.get("harvested_clusters", [])
	)
	_next_building_serial = int(data.get("next_building_serial", 1))
	var saved_buildings: Array = data.get("buildings", [])
	for entry in SliceBuildingSaveCodec.ordered_for_restore(saved_buildings):
		var definition := SliceBuildingCatalog.find(String(entry["building_id"]))
		var raw_cell: Array = entry["origin_cell"]
		var cell := Vector2i(int(raw_cell[0]), int(raw_cell[1]))
		var spawned := _spawn_building(
			definition,
			String(entry["instance_id"]),
			cell,
			int(entry["rotation"]),
			entry["state"]
		)
		if spawned == null:
			push_warning("存档世界重建失败：%s 无法生成。" % String(entry["instance_id"]))
			return false

	var world_node := _map.get_node("World")
	for cluster_name in harvested_clusters:
		var cluster := world_node.get_node_or_null(NodePath(cluster_name))
		if cluster != null:
			cluster.queue_free()

	if core_repaired:
		SliceCoreLogistics.apply_repaired_visual(
			_core_visual(), REPAIRED_CORE_TEXTURE
		)

	player.position = Vector2(
		float(data.get("player_x", START_SPAWN.x)),
		float(data.get("player_y", START_SPAWN.y))
	)
	first_journey.restore(data["first_journey_flags"], data["explored_map_bits"])
	combat_controller.restore_durable_state(
		int(data.get("player_health", 100)),
		data.get("field_encounter", {
			"state": "hostile" if is_core_charged() else "locked",
			"enemy_health": SliceFieldEnemy.MAX_HEALTH,
		}),
		String(data.get(
			"equipped_weapon_id", SliceCombatController.WEAPON_CUTTER
		))
	)
	_refresh_core_charge_visual()

	inventory_changed.emit()
	core_storage_changed.emit()
	core_charge_changed.emit(core_energy)
	if core_repaired:
		core_repair_completed.emit()
	return true


func _on_pause_save_and_return_requested() -> void:
	if not save_now():
		pause_menu.show_save_error(
			"保存失败，仍停留在当前世界；请检查存档目录后重试。"
		)
		return
	pause_menu.release_for_transition()
	return_to_startup_requested.emit()


func _on_pause_save_and_quit_requested() -> void:
	if not save_now():
		pause_menu.show_save_error(
			"保存失败，未退出游戏；请检查存档目录后重试。"
		)
		return
	pause_menu.release_for_transition()
	get_tree().quit()


func request_save() -> bool:
	var accepted := _save_scheduler.request_save()
	if not accepted:
		push_warning("切片保存请求已阻止：载入世界未完整重建。")
	return accepted


func save_now() -> bool:
	var result := _save_scheduler.flush(Callable(self, "_durable_state"))
	if bool(result.get("success", false)):
		return true
	push_warning("切片保存失败：%s" % String(result.get("message", "")))
	return false


func _tick_save_scheduler(delta: float) -> void:
	var result := _save_scheduler.advance(
		delta, Callable(self, "_durable_state")
	)
	if (
		bool(result.get("attempted", false))
		and not bool(result.get("success", false))
	):
		push_warning(
			"切片延迟保存失败，将保留待保存状态：%s"
			% String(result.get("message", ""))
		)


func _on_combat_persistence_requested(immediate: bool) -> void:
	if immediate:
		save_now()
	else:
		request_save()


func _durable_state() -> Dictionary:
	return SliceWorldSaveStateBuilder.build(self)
