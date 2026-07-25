class_name SliceWorld
extends Node2D

## Slice world root: one seamless map (base zone west, crystal expedition zone
## east) plus the player. Owns the runtime loop state and an isolated
## SliceSaveService that auto-persists on every change and on quit.
##
## L3 package 1 migrates the collector-only carry boolean and fixed query into
## data-driven building definitions, ordinary inventory kits, separate floor /
## blocking occupancy, one placement controller and shared runtime instances.
## Industrial floor and the existing collector are the first two definitions;
## other devices, adjustment, power and schema 4 arrive in later L3 packages.
## `startup_load` (set by Boot before the node enters the tree) decides whether
## _ready restores the saved slice or starts a fresh one.

const MAP_SCENE := "res://scenes/slice/SliceMap.tscn"
const PLAYER_SCENE := "res://scenes/slice/SlicePlayer.tscn"
const HUD_SCENE := "res://scenes/slice/SliceHud.tscn"
const CRAFT_PANEL_SCENE := "res://scenes/slice/SliceCraftPanel.tscn"
const CORE_STORAGE_PANEL_SCENE := "res://scenes/slice/SliceCoreStoragePanel.tscn"
const REPAIRED_CORE_TEXTURE := preload("res://assets/sprites/slice/outpost_core_repaired.png")
const MAP_PIXEL_SIZE := Vector2i(2560, 768)
const START_SPAWN := Vector2(400, 576)
const TILE_SIZE := 32.0

const ITEM_CRYSTAL := "crystal"
const ITEM_CATALYST := "catalyst"
const ITEM_PART := "part"
const ITEM_FLOOR_KIT := SliceBuildingCatalog.FLOOR_ID
const ITEM_COLLECTOR_KIT := SliceBuildingCatalog.COLLECTOR_ID
const POCKET_CAPACITY := 30
const CORE_STORAGE_CAPACITY := 120
const CORE_DIRECT_POWER_RANGE := 192.0

const COLLECTOR_PRODUCE_INTERVAL := 10.0
const REACTOR_INPUT_PER_BATCH := 2
const REACTOR_OUTPUT_PER_BATCH := 1
const REACTOR_PRODUCE_INTERVAL := 10.0
const CATALYST_CAP := 20
const CORE_CHARGE_TARGET := 10
const ROCK_GROUND_SOURCE_ID := 0
const CRYSTAL_GROUND_SOURCE_ID := 2

## Emitted whenever the player backpack contents change (drives HUD refresh).
signal inventory_changed
signal core_storage_changed
signal catalyst_changed(count: int)
signal core_charge_changed(energy: int)
signal core_repair_completed
signal placement_changed

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

## Injected by Boot so menu summary and world reads/writes share one service.
## Standalone scene checks keep the production default unless they replace it.
var save_service := SliceSaveService.new()
var _map: Node2D
var _craft_panel: SliceCraftPanel
var _core_storage_panel: SliceCoreStoragePanel
var _ground: TileMapLayer
var _industrial_floor: TileMapLayer
var _placement: SliceBuildingPlacementController
var _occupancy := SliceBuildingOccupancy.new()
var _building_instances: Array[SliceBuildingInstance] = []
var _collector_nodes: Array[SliceCollector] = []
var _next_building_serial := 1
## Runtime-only accumulator toward the next collector production tick; partial
## sub-interval progress is not persisted (resets to 0 on load).
var _produce_timer := 0.0


func _ready() -> void:
	_map = (load(MAP_SCENE) as PackedScene).instantiate()
	add_child(_map)
	_ground = _map.get_node("GroundLayer")
	_industrial_floor = _map.get_node("IndustrialFloorLayer")

	player = (load(PLAYER_SCENE) as PackedScene).instantiate() as SlicePlayer
	player.world = self
	_map.get_node("World").add_child(player)
	player.position = START_SPAWN

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

	_placement = SliceBuildingPlacementController.new()
	_map.add_child(_placement)

	if startup_load:
		_restore_from_save()


func _physics_process(_delta: float) -> void:
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


func _process(delta: float) -> void:
	_tick_production(delta)


func _unhandled_input(event: InputEvent) -> void:
	if not is_placement_active():
		return
	if event.is_action_pressed("rotate_building"):
		rotate_building_placement()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		cancel_building_placement()
		get_viewport().set_input_as_handled()


## Each collector fills its own output buffer by 1 crystal per interval, pausing
## at BUFFER_CAP. The timer bank drains multiple ticks on a long frame so output
## is framerate-independent; players withdraw buffers via collect_from_collector.
func _tick_production(delta: float) -> void:
	if _collector_nodes.is_empty():
		return
	_produce_timer += delta
	var ticks := 0
	while _produce_timer >= COLLECTOR_PRODUCE_INTERVAL:
		_produce_timer -= COLLECTOR_PRODUCE_INTERVAL
		ticks += 1
	if ticks <= 0:
		return
	var produced := false
	for collector in _collector_nodes:
		for _t in ticks:
			if collector.has_space():
				collector.produce(1)
				produced = true
	if produced:
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


func open_core_storage() -> bool:
	if not core_repaired or _core_storage_panel == null:
		return false
	if _craft_panel != null:
		_craft_panel.close()
	_core_storage_panel.open()
	return true


func close_core_storage() -> void:
	if _core_storage_panel != null:
		_core_storage_panel.close()


func is_core_storage_open() -> bool:
	return _core_storage_panel != null and _core_storage_panel.is_open()


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


func is_core_charged() -> bool:
	return core_energy >= CORE_CHARGE_TARGET


## Inject stored catalyst into the repaired core, advancing core_energy toward
## CORE_CHARGE_TARGET. Catalyst is still the abstract count in package 1; L0
## package 2 sources it from the core store inventory instead.
func charge_core() -> bool:
	if not core_repaired or is_core_charged() or catalyst_count <= 0:
		return false
	var used := mini(catalyst_count, CORE_CHARGE_TARGET - core_energy)
	catalyst_count -= used
	core_energy += used
	catalyst_changed.emit(catalyst_count)
	core_charge_changed.emit(core_energy)
	_autosave()
	return true


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
	close_core_storage()
	if _craft_panel != null:
		_craft_panel.close()
	_placement.begin(definition)
	placement_changed.emit()
	return true


func cancel_building_placement() -> void:
	if not is_placement_active():
		return
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
	return _placement_result(true, "")


func _placement_result(valid: bool, reason: String) -> Dictionary:
	return {"valid": valid, "reason": reason}


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
	instance.position = definition.block_center(
		origin_cell, TILE_SIZE, instance.building_rotation
	)
	if instance is SliceCollector:
		var collector := instance as SliceCollector
		collector.buffer = clampi(
			int(state.get("buffer", 0)), 0, SliceCollector.BUFFER_CAP
		)
		_collector_nodes.append(collector)

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
	var legacy_carried_collector := bool(
		data.get("carrying_collector", false)
	)
	if legacy_carried_collector:
		pocket.restore_existing(ITEM_COLLECTOR_KIT, 1)

	for entry in data.get("collectors", []):
		if not (entry is Dictionary):
			continue
		var raw_cell = entry.get("cell", [0, 0])
		var cell := Vector2i(int(raw_cell[0]), int(raw_cell[1]))
		_spawn_building(
			SliceBuildingCatalog.find(SliceBuildingCatalog.COLLECTOR_ID),
			"",
			cell,
			0,
			{"buffer": int(entry.get("buffer", 0))}
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
	if legacy_carried_collector:
		begin_building_placement(SliceBuildingCatalog.COLLECTOR_ID)


func _autosave() -> void:
	var player_position := player.position if player != null else START_SPAWN
	var serialized_collectors := []
	for collector in _collector_nodes:
		serialized_collectors.append({
			"cell": [collector.origin_cell.x, collector.origin_cell.y],
			"buffer": collector.buffer
		})
	var result := save_service.save_state({
		"pocket": pocket.to_dict(),
		"core_storage": core_storage.to_dict(),
		"catalyst_count": catalyst_count,
		"core_repaired": core_repaired,
		"core_energy": core_energy,
		"reactor_active": reactor_active,
		"harvested_clusters": harvested_clusters,
		"collectors": serialized_collectors,
		"carrying_collector": false,
		"player_x": player_position.x,
		"player_y": player_position.y
	})
	if not bool(result.get("success", false)):
		push_warning("切片自动存档失败：%s" % String(result.get("message", "")))


func _to_string_array(value) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item in value:
			result.append(String(item))
	return result
