class_name SliceWorld
extends Node2D

## Slice world root: one seamless map (base zone west, crystal expedition zone
## east) plus the player. Owns the runtime loop state and an isolated
## SliceSaveService that auto-persists on every change and on quit.
##
## L3 packages 1-4 provide six data-driven building definitions, ordinary
## inventory kits, separate floor / blocking occupancy, one placement
## controller, shared runtime instances, lossless adjustment / demolition,
## derived power propagation and stable topology persistence. L4 adds
## storage-to-storage conveyor cargo and fixed topology frames. L5 adds
## per-instance reactor buffers, retained processing and schema-6 state.
## `startup_load` (set by Boot before the node enters the tree) decides whether
## _ready restores the saved slice or starts a fresh one.

const MAP_SCENE := "res://scenes/slice/SliceMap.tscn"
const PLAYER_SCENE := "res://scenes/slice/SlicePlayer.tscn"
const HUD_SCENE := "res://scenes/slice/SliceHud.tscn"
const CRAFT_PANEL_SCENE := "res://scenes/slice/SliceCraftPanel.tscn"
const CORE_STORAGE_PANEL_SCENE := "res://scenes/slice/SliceCoreStoragePanel.tscn"
const CORE_CHARGE_PANEL_SCENE := "res://scenes/slice/SliceCoreChargePanel.tscn"
const BUILDING_ACTION_PANEL_SCENE := "res://scenes/slice/SliceBuildingActionPanel.tscn"
const PAUSE_MENU_SCENE := "res://scenes/slice/SlicePauseMenu.tscn"
const COMBAT_CONTROLLER_SCENE := "res://scenes/slice/SliceCombatController.tscn"
const REPAIRED_CORE_TEXTURE := preload("res://assets/sprites/slice/outpost_core_repaired.png")
const MAP_PIXEL_SIZE := Vector2i(2560, 768)
const START_SPAWN := Vector2(400, 576)
const TILE_SIZE := 32.0

const ITEM_CRYSTAL := "crystal"
const ITEM_CATALYST := "catalyst"
const ITEM_PART := "part"
const ITEM_FLOOR_KIT := SliceBuildingCatalog.FLOOR_ID
const ITEM_COLLECTOR_KIT := SliceBuildingCatalog.COLLECTOR_ID
const ITEM_REACTOR_KIT := SliceBuildingCatalog.REACTOR_ID
const ITEM_POWER_RELAY_KIT := SliceBuildingCatalog.POWER_RELAY_ID
const ITEM_CONVEYOR_KIT := SliceBuildingCatalog.CONVEYOR_ID
const ITEM_STORAGE_KIT := SliceBuildingCatalog.STORAGE_ID
const POCKET_CAPACITY := 30
const CORE_STORAGE_CAPACITY := 120
const CORE_DIRECT_POWER_RANGE := 192.0

const COLLECTOR_PRODUCE_INTERVAL := 10.0
const REACTOR_INPUT_PER_BATCH := 2
const REACTOR_OUTPUT_PER_BATCH := 1
const REACTOR_PRODUCE_INTERVAL := 10.0
const CATALYST_CAP := 20
const CORE_CHARGE_TARGET := 2
const ROCK_GROUND_SOURCE_ID := 0
const CRYSTAL_GROUND_SOURCE_ID := 2
const CORE_LINK_ANCHOR_OFFSET := Vector2(0, -32)
const RELAY_LINK_ANCHOR_OFFSET := Vector2(0, -44)

## Emitted whenever the player backpack contents change (drives HUD refresh).
signal inventory_changed
signal core_storage_changed
signal building_storage_changed(instance_id: String)
signal catalyst_changed(count: int)
signal core_charge_changed(energy: int)
signal core_repair_completed
signal placement_changed
signal return_to_startup_requested

## Set by Boot before add_child: true loads the saved slice, false starts fresh.
var startup_load := false

## Player backpack (spatial crystal/catalyst store, capacity-limited).
var pocket := Inventory.new(POCKET_CAPACITY)
var core_storage := Inventory.new(CORE_STORAGE_CAPACITY)
var catalyst_count := 0
var core_repaired := false
var core_energy := 0
var reactor_active := false
var harvested_clusters: Array[String] = []

var player: SlicePlayer
var combat_controller: SliceCombatController

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
var _occupancy := SliceBuildingOccupancy.new()
var _power_grid := SlicePowerGrid.new()
var _logistics_grid := SliceLogisticsGrid.new()
var _power_links: SlicePowerLinkLayer
var _building_instances: Array[SliceBuildingInstance] = []
var _collector_nodes: Array[SliceCollector] = []
var _reactor_nodes: Array[SliceReactor] = []
var _adjustment_instance: SliceBuildingInstance
var _adjustment_original_cell := Vector2i.ZERO
var _adjustment_original_rotation := 0
var _next_building_serial := 1
var _logistics_save_elapsed := 0.0
var _production_save_elapsed := 0.0


func _ready() -> void:
	_map = (load(MAP_SCENE) as PackedScene).instantiate()
	add_child(_map)
	_ground = _map.get_node("GroundLayer")
	_industrial_floor = _map.get_node("IndustrialFloorLayer")
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

	var camera := player.get_node("Camera") as Camera2D
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = MAP_PIXEL_SIZE.x
	camera.limit_bottom = MAP_PIXEL_SIZE.y

	var hud := (load(HUD_SCENE) as PackedScene).instantiate() as SliceHud
	add_child(hud)
	hud.setup(self, player)

	_craft_panel = (load(CRAFT_PANEL_SCENE) as PackedScene).instantiate() as SliceCraftPanel
	add_child(_craft_panel)
	_craft_panel.setup(self)

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

	if startup_load:
		_restore_from_save()
	_refresh_core_charge_visual()
	_rebuild_power_grid()
	_rebuild_logistics_grid()


func _physics_process(delta: float) -> void:
	_tick_logistics(delta)
	if not is_placement_active() or player == null:
		return
	var target_point := player.position + player.facing * 64.0
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
		validation
	)


func _tick_logistics(delta: float) -> void:
	var result := _logistics_grid.tick(delta)
	if not bool(result.get("changed", false)):
		return
	_logistics_save_elapsed += delta
	for instance_id in result.get("storage_ids", []):
		building_storage_changed.emit(String(instance_id))
	if _logistics_save_elapsed >= 1.0:
		_autosave()


func _process(delta: float) -> void:
	_tick_production(delta)


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
			pause_menu.open()
		get_viewport().set_input_as_handled()
		return
	if not is_placement_active():
		return
	if event.is_action_pressed("rotate_building"):
		rotate_building_placement()
		get_viewport().set_input_as_handled()


## Powered collectors and reactors retain their own tick progress. Production
## transitions save immediately; in-flight progress is checkpointed each second.
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

	if reactor_changed:
		_production_save_elapsed += delta
	if produced or reactor_transition or _production_save_elapsed >= 1.0:
		_autosave()


## L0 package 2 re-wires the reactor to pull crystals from its input buffer and
## push catalyst to its output buffer. Until then the reactor tick is inert:
## activation is still recorded (and saved) but no processing happens.
func _tick_reactor(_delta: float) -> void:
	pass


func activate_reactor() -> void:
	if reactor_active:
		return
	reactor_active = true
	_autosave()


## Harvest a crystal cluster into the backpack. Returns false (leaving the
## cluster in place) if the backpack cannot hold the full yield.
func harvest_crystals(cluster_name: String, amount: int) -> bool:
	if pocket.free_space() < amount:
		return false
	if not harvested_clusters.has(cluster_name):
		harvested_clusters.append(cluster_name)
	pocket.add(ITEM_CRYSTAL, amount)
	inventory_changed.emit()
	_autosave()
	return true


## Move a collector's output buffer into the backpack, bounded by free space.
func collect_from_collector(collector: SliceCollector) -> void:
	if collector.buffer <= 0:
		return
	var moved := pocket.add(ITEM_CRYSTAL, collector.buffer)
	if moved <= 0:
		return
	collector.buffer -= moved
	inventory_changed.emit()
	_autosave()


## Spend a specific item from the backpack (e.g. mechanical parts for repair).
func spend_pocket_item(item: String, amount: int) -> bool:
	if pocket.count(item) < amount:
		return false
	pocket.remove(item, amount)
	inventory_changed.emit()
	_autosave()
	return true


func mark_core_repaired() -> void:
	core_repaired = true
	_refresh_core_charge_visual()
	_rebuild_power_grid()
	core_repair_completed.emit()
	_autosave()


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
func transfer_pocket_to_core(item: String) -> int:
	if not core_repaired:
		return 0
	var moved := core_storage.add(item, pocket.count(item))
	if moved <= 0:
		return 0
	pocket.remove(item, moved)
	inventory_changed.emit()
	core_storage_changed.emit()
	_autosave()
	return moved


## Moves as much of one item as the backpack can accept from the core store.
func transfer_core_to_pocket(item: String) -> int:
	if not core_repaired:
		return 0
	var moved := pocket.add(item, core_storage.count(item))
	if moved <= 0:
		return 0
	core_storage.remove(item, moved)
	inventory_changed.emit()
	core_storage_changed.emit()
	_autosave()
	return moved


func transfer_pocket_to_storage(
	storage: SliceStorage,
	item: String
) -> int:
	if (
		not [ITEM_CRYSTAL, ITEM_CATALYST].has(item)
		or storage == null
		or not _building_instances.has(storage)
	):
		return 0
	var moved := storage.inventory.add(item, pocket.count(item))
	if moved <= 0:
		return 0
	pocket.remove(item, moved)
	inventory_changed.emit()
	building_storage_changed.emit(storage.instance_id)
	_autosave()
	return moved


func transfer_storage_to_pocket(
	storage: SliceStorage,
	item: String
) -> int:
	if (
		not [ITEM_CRYSTAL, ITEM_CATALYST].has(item)
		or storage == null
		or not _building_instances.has(storage)
	):
		return 0
	var moved := pocket.add(item, storage.inventory.count(item))
	if moved <= 0:
		return 0
	storage.inventory.remove(item, moved)
	inventory_changed.emit()
	building_storage_changed.emit(storage.instance_id)
	_autosave()
	return moved


func reactor_status_text(reactor: SliceReactor) -> String:
	if reactor == null or not _building_instances.has(reactor):
		return "设备已失效"
	return reactor.operation_status_text(
		_logistics_grid.can_extract_reactor_output(reactor)
	)


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
	_autosave()
	return result


func transfer_all_building_kits_to_core() -> int:
	if not core_repaired:
		return 0
	var moved_total := 0
	for definition in SliceBuildingCatalog.all():
		var item := definition.kit_item_id
		var moved := core_storage.add(item, pocket.count(item))
		if moved > 0:
			pocket.remove(item, moved)
			moved_total += moved
	if moved_total > 0:
		inventory_changed.emit()
		core_storage_changed.emit()
		_autosave()
	return moved_total


func transfer_all_building_kits_to_pocket() -> int:
	if not core_repaired:
		return 0
	var moved_total := 0
	for definition in SliceBuildingCatalog.all():
		var item := definition.kit_item_id
		var moved := pocket.add(item, core_storage.count(item))
		if moved > 0:
			core_storage.remove(item, moved)
			moved_total += moved
	if moved_total > 0:
		inventory_changed.emit()
		core_storage_changed.emit()
		_autosave()
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
	_autosave()
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
	var core := _map.get_node_or_null(
		"World/OutpostCoreDamaged"
	) as Sprite2D
	if core == null:
		return
	core.self_modulate = (
		Color(0.76, 1.0, 0.94, 1.0)
		if is_core_charged()
		else Color.WHITE
	)


## Craft a recipe into ordinary backpack items. Building recipes create one or
## more kit items and immediately select their shared placement definition.
func craft(recipe_id: String) -> bool:
	var recipe := SliceRecipes.find(recipe_id)
	if recipe.is_empty():
		return false
	var kind := String(recipe["kind"])
	if not can_afford(recipe["cost"]):
		return false
	var output_count := int(recipe.get("output_count", 1))
	var consumed_count := 0
	for amount in recipe["cost"].values():
		consumed_count += int(amount)
	if pocket.free_space() + consumed_count < output_count:
		return false
	if kind == "building":
		var definition := SliceBuildingCatalog.find(String(recipe["building_id"]))
		if definition == null:
			return false
	for item in recipe["cost"]:
		pocket.remove(String(item), int(recipe["cost"][item]))
	var stored := pocket.add(String(recipe["output"]), output_count)
	if stored != output_count:
		push_error("Craft capacity check drifted after consuming recipe inputs.")
		return false
	if kind == "building":
		begin_building_placement(String(recipe["building_id"]))
	inventory_changed.emit()
	_autosave()
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
	placement_changed.emit()
	return true


func cancel_building_placement() -> void:
	if not is_placement_active():
		return
	if _adjustment_instance != null:
		_restore_adjustment_origin()
	_placement.cancel()
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
	if _adjustment_instance != null:
		_commit_adjustment(
			_placement.target_origin,
			_placement.rotation_index
		)
		_placement.cancel()
		placement_changed.emit()
		_autosave()
		return true
	if pocket.count(definition.kit_item_id) <= 0:
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
		return false
	pocket.remove(definition.kit_item_id, 1)
	if pocket.count(definition.kit_item_id) <= 0:
		cancel_building_placement()
	else:
		placement_changed.emit()
	inventory_changed.emit()
	_autosave()
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
	if pocket.free_space() <= 0:
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
	var returned := pocket.add(instance.definition.kit_item_id, 1)
	if returned != 1:
		push_error("Demolition capacity changed after validation.")
		return false
	instance.queue_free()
	_rebuild_power_grid()
	_rebuild_logistics_grid()
	inventory_changed.emit()
	placement_changed.emit()
	_autosave()
	return true


func _validate_placement(
	definition: SliceBuildingDefinition,
	origin_cell: Vector2i,
	rotation: int
) -> Dictionary:
	var cells := definition.occupied_cells(origin_cell, rotation)
	for cell in cells:
		if cell.x < 0 or cell.y < 0:
			return _placement_result(false, "越界")
		if cell.x >= MAP_PIXEL_SIZE.x / int(TILE_SIZE):
			return _placement_result(false, "越界")
		if cell.y >= MAP_PIXEL_SIZE.y / int(TILE_SIZE):
			return _placement_result(false, "越界")

	for cell in cells:
		var source_id := _ground.get_cell_source_id(cell)
		if (
			definition.surface_rule
			== SliceBuildingDefinition.SURFACE_BUILDABLE_ROCK
			and source_id != ROCK_GROUND_SOURCE_ID
		):
			return _placement_result(false, "需可建岩地")
		if (
			definition.surface_rule == SliceBuildingDefinition.SURFACE_CRYSTAL
			and source_id != CRYSTAL_GROUND_SOURCE_ID
		):
			return _placement_result(false, "需晶体地")
		if (
			definition.surface_rule
			== SliceBuildingDefinition.SURFACE_INDUSTRIAL_FLOOR
			and not _occupancy.has_floor(cell)
		):
			return _placement_result(false, "需工业地板")

	if not _occupancy.can_occupy(cells, definition.is_floor):
		return _placement_result(false, "已有占用")

	var query := PhysicsShapeQueryParameters2D.new()
	var shape := RectangleShape2D.new()
	var footprint := Vector2(definition.rotated_footprint(rotation)) * TILE_SIZE
	shape.size = footprint - Vector2(2, 2)
	query.shape = shape
	query.collide_with_areas = false
	query.transform = Transform2D(
		0.0, definition.block_center(origin_cell, TILE_SIZE, rotation)
	)
	var collisions := get_world_2d().direct_space_state.intersect_shape(query, 8)
	for collision in collisions:
		if collision.get("collider") == player:
			return _placement_result(false, "玩家阻挡")
	if not collisions.is_empty():
		return _placement_result(false, "已有占用")
	if (
		definition.power_role == SliceBuildingDefinition.POWER_RELAY
		and not _power_grid.can_connect_relay_at(
			definition.block_center(origin_cell, TILE_SIZE, rotation)
		)
	):
		return _placement_result(false, "超出电网连接距离")
	return _placement_result(true, "")


func _placement_result(valid: bool, reason: String) -> Dictionary:
	return {"valid": valid, "reason": reason}


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
	_logistics_grid.rebuild(_building_instances, excluded_instance_id)


func _refresh_power_links() -> void:
	if _power_links == null:
		return
	var links: Array[Dictionary] = []
	for connection in _power_grid.powered_connections():
		var parent_id := String(connection.get("parent_id", ""))
		var from_position := Vector2(
			connection.get("from_position", Vector2.ZERO)
		)
		var to_position := Vector2(
			connection.get("to_position", Vector2.ZERO)
		)
		links.append({
			"from_position": from_position + (
				CORE_LINK_ANCHOR_OFFSET
				if parent_id == SlicePowerGrid.CORE_NODE_ID
				else RELAY_LINK_ANCHOR_OFFSET
			),
			"to_position": to_position + RELAY_LINK_ANCHOR_OFFSET,
		})
	_power_links.set_links(links)


func _core_world_position() -> Vector2:
	if _map == null:
		return Vector2.ZERO
	var core := _map.get_node_or_null("World/OutpostCoreDamaged") as Node2D
	return Vector2.ZERO if core == null else core.global_position


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
			state.get("input_inventory", {})
		)
		reactor.input_inventory.capacity = SliceReactor.INPUT_CAPACITY
		reactor.output_inventory = Inventory.from_dict(
			state.get("output_inventory", {})
		)
		reactor.output_inventory.capacity = SliceReactor.OUTPUT_CAPACITY
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
		storage.inventory = Inventory.from_dict(state.get("inventory", {}))
		storage.inventory.capacity = SliceStorage.CAPACITY

	_map.get_node("World").add_child(instance)
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
		_autosave()


func _restore_from_save() -> void:
	var result := save_service.load_state()
	if not bool(result.get("success", false)):
		push_warning("切片读档失败，按新档继续：%s" % String(result.get("message", "")))
		return

	var data: Dictionary = result.get("data", {})
	pocket = Inventory.from_dict(data.get("pocket", {}))
	if pocket.capacity != POCKET_CAPACITY:
		pocket.capacity = POCKET_CAPACITY
	core_storage = Inventory.from_dict(data.get("core_storage", {}))
	if core_storage.capacity != CORE_STORAGE_CAPACITY:
		core_storage.capacity = CORE_STORAGE_CAPACITY
	catalyst_count = int(data.get("catalyst_count", 0))
	core_repaired = bool(data.get("core_repaired", false))
	core_energy = int(data.get("core_energy", 0))
	reactor_active = bool(data.get("reactor_active", false))
	harvested_clusters = _to_string_array(data.get("harvested_clusters", []))
	_next_building_serial = int(data.get("next_building_serial", 1))
	var saved_buildings: Array = data.get("buildings", [])
	for entry in SliceBuildingSaveCodec.ordered_for_restore(saved_buildings):
		var definition := SliceBuildingCatalog.find(String(entry["building_id"]))
		var raw_cell: Array = entry["origin_cell"]
		var cell := Vector2i(int(raw_cell[0]), int(raw_cell[1]))
		_spawn_building(
			definition,
			String(entry["instance_id"]),
			cell,
			int(entry["rotation"]),
			entry["state"]
		)

	var world_node := _map.get_node("World")
	for cluster_name in harvested_clusters:
		var cluster := world_node.get_node_or_null(NodePath(cluster_name))
		if cluster != null:
			cluster.queue_free()

	if core_repaired:
		var core := world_node.get_node_or_null("OutpostCoreDamaged") as Sprite2D
		if core != null:
			core.texture = REPAIRED_CORE_TEXTURE
	_refresh_core_charge_visual()

	player.position = Vector2(
		float(data.get("player_x", START_SPAWN.x)),
		float(data.get("player_y", START_SPAWN.y))
	)

	inventory_changed.emit()
	core_storage_changed.emit()
	catalyst_changed.emit(catalyst_count)
	core_charge_changed.emit(core_energy)
	if core_repaired:
		core_repair_completed.emit()


func _on_pause_save_and_return_requested() -> void:
	if not _autosave():
		pause_menu.show_save_error(
			"保存失败，仍停留在当前世界；请检查存档目录后重试。"
		)
		return
	pause_menu.release_for_transition()
	return_to_startup_requested.emit()


func _on_pause_save_and_quit_requested() -> void:
	if not _autosave():
		pause_menu.show_save_error(
			"保存失败，未退出游戏；请检查存档目录后重试。"
		)
		return
	pause_menu.release_for_transition()
	get_tree().quit()


func _autosave() -> bool:
	var player_position := player.position if player != null else START_SPAWN
	var result := save_service.save_state({
		"pocket": pocket.to_dict(),
		"core_storage": core_storage.to_dict(),
		"core_repaired": core_repaired,
		"core_energy": core_energy,
		"harvested_clusters": harvested_clusters,
		"buildings": SliceBuildingSaveCodec.serialize_instances(
			_building_instances
		),
		"next_building_serial": _next_building_serial,
		"player_x": player_position.x,
		"player_y": player_position.y
	})
	if not bool(result.get("success", false)):
		push_warning("切片自动存档失败：%s" % String(result.get("message", "")))
		return false
	_logistics_save_elapsed = 0.0
	_production_save_elapsed = 0.0
	return true


func _to_string_array(value) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item in value:
			result.append(String(item))
	return result
