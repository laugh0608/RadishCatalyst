class_name SliceWorld
extends Node2D

## Slice world root: one seamless map (base zone west, crystal expedition
## zone east) plus the player. Owns the runtime loop state (crystal count,
## catalyst count, the core-repaired and reactor-active flags, harvested
## cluster names, placed collectors and the collector carry state) and an
## isolated SliceSaveService that auto-persists this state on every change and
## on quit. `startup_load` (set by Boot before the node enters the tree)
## decides whether _ready restores the saved slice or starts a fresh one.
## Collector placement is only valid on free crystal ground
## (docs/features/slice-harvest-and-build-v1.md). Once activated, the reactor
## refines crystals into catalyst on a timed tick
## (docs/features/slice-recipe-processing-v1.md).

const MAP_SCENE := "res://scenes/slice/SliceMap.tscn"
const PLAYER_SCENE := "res://scenes/slice/SlicePlayer.tscn"
const HUD_SCENE := "res://scenes/slice/SliceHud.tscn"
const COLLECTOR_SCENE := "res://scenes/slice/SliceCollector.tscn"
const COLLECTOR_TEXTURE := preload("res://assets/sprites/slice/collector.png")
const REPAIRED_CORE_TEXTURE := preload("res://assets/sprites/slice/outpost_core_repaired.png")
const MAP_PIXEL_SIZE := Vector2i(2560, 768)
const START_SPAWN := Vector2(400, 576)
const TILE_SIZE := 32.0
const COLLECTOR_COST := 5
const COLLECTOR_PRODUCE_INTERVAL := 10.0
const REACTOR_INPUT_PER_BATCH := 2
const REACTOR_OUTPUT_PER_BATCH := 1
const REACTOR_PRODUCE_INTERVAL := 10.0
const CATALYST_CAP := 20
const CORE_CHARGE_TARGET := 10
const CRYSTAL_GROUND_SOURCE_ID := 2
const GHOST_VALID_COLOR := Color(0.45, 1.0, 0.9, 0.55)
const GHOST_INVALID_COLOR := Color(1.0, 0.4, 0.35, 0.55)

signal crystals_changed(count: int)
signal catalyst_changed(count: int)
signal core_charge_changed(energy: int)
signal core_repair_completed

## Set by Boot before add_child: true loads the saved slice, false starts fresh.
var startup_load := false

var crystal_count := 0
var catalyst_count := 0
var core_repaired := false
var core_energy := 0
var reactor_active := false
var harvested_clusters: Array[String] = []
var collectors: Array[Vector2i] = []
var carrying_collector := false

var player: SlicePlayer

var _save_service := SliceSaveService.new()
var _map: Node2D
var _ground: TileMapLayer
var _ghost: Sprite2D
var _place_query: PhysicsShapeQueryParameters2D
var _target_cell := Vector2i.ZERO
var _target_valid := false
## Runtime-only accumulator toward the next collector production tick; partial
## sub-interval progress is not persisted (resets to 0 on load).
var _produce_timer := 0.0
## Runtime-only accumulator toward the next reactor batch; not persisted.
var _reactor_timer := 0.0


func _ready() -> void:
	_map = (load(MAP_SCENE) as PackedScene).instantiate()
	add_child(_map)
	_ground = _map.get_node("GroundLayer")

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

	# Placement preview ghost draws above the y-sorted world container.
	_ghost = Sprite2D.new()
	_ghost.texture = COLLECTOR_TEXTURE
	_ghost.offset = Vector2(0, -16)
	_ghost.visible = false
	_map.add_child(_ghost)

	var place_shape := RectangleShape2D.new()
	place_shape.size = Vector2(62, 62)
	_place_query = PhysicsShapeQueryParameters2D.new()
	_place_query.shape = place_shape
	_place_query.collide_with_areas = false

	if startup_load:
		_restore_from_save()


func _physics_process(_delta: float) -> void:
	if not carrying_collector or player == null:
		_target_valid = false
		return
	# The collector occupies a 2x2 tile block; the target block snaps its
	# center to the grid intersection nearest to 2 tiles ahead of the player,
	# far enough that the block never overlaps the player's own feet box.
	var target_point := player.position + player.facing * 64.0
	var corner := (target_point / TILE_SIZE).round() * TILE_SIZE
	_target_cell = Vector2i(corner / TILE_SIZE) - Vector2i.ONE
	_target_valid = _can_place(_target_cell)


func _process(delta: float) -> void:
	_tick_production(delta)
	_tick_reactor(delta)
	_ghost.visible = carrying_collector
	if not carrying_collector:
		return
	_ghost.position = _block_center(_target_cell)
	_ghost.modulate = GHOST_VALID_COLOR if _target_valid else GHOST_INVALID_COLOR


## Each placed collector yields 1 crystal per COLLECTOR_PRODUCE_INTERVAL. The
## timer bank drains multiple ticks if a frame is long so output is
## framerate-independent; crystals_changed drives the HUD and autosave.
func _tick_production(delta: float) -> void:
	if collectors.is_empty():
		return
	_produce_timer += delta
	var produced := 0
	while _produce_timer >= COLLECTOR_PRODUCE_INTERVAL:
		_produce_timer -= COLLECTOR_PRODUCE_INTERVAL
		produced += collectors.size()
	if produced > 0:
		crystal_count += produced
		crystals_changed.emit(crystal_count)
		_autosave()


## Once the reactor is active it consumes REACTOR_INPUT_PER_BATCH crystals to
## produce REACTOR_OUTPUT_PER_BATCH catalyst every REACTOR_PRODUCE_INTERVAL. It
## pauses when crystals run short or the catalyst store is full; the banked
## timer is clamped to one interval while paused so resuming never bursts a
## backlog. Multiple batches drain in one long frame for framerate independence.
func _tick_reactor(delta: float) -> void:
	if not reactor_active:
		return
	_reactor_timer += delta
	var produced := 0
	while _reactor_timer >= REACTOR_PRODUCE_INTERVAL:
		if crystal_count < REACTOR_INPUT_PER_BATCH or catalyst_count >= CATALYST_CAP:
			_reactor_timer = minf(_reactor_timer, REACTOR_PRODUCE_INTERVAL)
			break
		crystal_count -= REACTOR_INPUT_PER_BATCH
		catalyst_count = mini(catalyst_count + REACTOR_OUTPUT_PER_BATCH, CATALYST_CAP)
		produced += 1
		_reactor_timer -= REACTOR_PRODUCE_INTERVAL
	if produced > 0:
		crystals_changed.emit(crystal_count)
		catalyst_changed.emit(catalyst_count)
		_autosave()


## First interaction with the reactor turns it on; afterwards it runs on the
## timed tick above. Idempotent so a second press is a no-op.
func activate_reactor() -> void:
	if reactor_active:
		return
	reactor_active = true
	_autosave()


func harvest_crystals(cluster_name: String, amount: int) -> void:
	if not harvested_clusters.has(cluster_name):
		harvested_clusters.append(cluster_name)
	crystal_count += amount
	crystals_changed.emit(crystal_count)
	_autosave()


func spend_crystals(amount: int) -> bool:
	if crystal_count < amount:
		return false
	crystal_count -= amount
	crystals_changed.emit(crystal_count)
	_autosave()
	return true


func mark_core_repaired() -> void:
	core_repaired = true
	core_repair_completed.emit()
	_autosave()


func is_core_charged() -> bool:
	return core_energy >= CORE_CHARGE_TARGET


## Inject stored catalyst into the repaired core, advancing core_energy toward
## CORE_CHARGE_TARGET. One press pours in as much catalyst as fits (bounded by
## the remaining need and the current store) so charging is not press-spammy.
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


func try_craft_collector() -> bool:
	if carrying_collector or crystal_count < COLLECTOR_COST:
		return false
	# Set the carry flag before spending so the autosave inside
	# spend_crystals persists both together.
	carrying_collector = true
	spend_crystals(COLLECTOR_COST)
	return true


func try_place_collector() -> bool:
	if not carrying_collector or not _can_place(_target_cell):
		return false
	_spawn_collector(_target_cell)
	collectors.append(_target_cell)
	carrying_collector = false
	_autosave()
	return true


func is_place_target_valid() -> bool:
	return _target_valid


## `top_left` is the top-left cell of the collector's 2x2 tile block. All four
## cells must be crystal ground and the block area must be free of bodies.
func _can_place(top_left: Vector2i) -> bool:
	for offset in [Vector2i.ZERO, Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
		if _ground.get_cell_source_id(top_left + offset) != CRYSTAL_GROUND_SOURCE_ID:
			return false
	_place_query.transform = Transform2D(0.0, _block_center(top_left))
	return get_world_2d().direct_space_state.intersect_shape(_place_query, 1).is_empty()


func _spawn_collector(top_left: Vector2i) -> void:
	var collector := (load(COLLECTOR_SCENE) as PackedScene).instantiate() as Node2D
	collector.position = _block_center(top_left)
	_map.get_node("World").add_child(collector)


func _block_center(top_left: Vector2i) -> Vector2:
	return Vector2(top_left) * TILE_SIZE + Vector2(TILE_SIZE, TILE_SIZE)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_autosave()


func _restore_from_save() -> void:
	var result := _save_service.load_state()
	if not bool(result.get("success", false)):
		push_warning("切片读档失败，按新档继续：%s" % String(result.get("message", "")))
		return

	var data: Dictionary = result.get("data", {})
	crystal_count = int(data.get("crystal_count", 0))
	catalyst_count = int(data.get("catalyst_count", 0))
	core_repaired = bool(data.get("core_repaired", false))
	core_energy = int(data.get("core_energy", 0))
	reactor_active = bool(data.get("reactor_active", false))
	harvested_clusters = _to_string_array(data.get("harvested_clusters", []))
	carrying_collector = bool(data.get("carrying_collector", false))
	collectors.clear()
	for cell_pair in data.get("collectors", []):
		var cell := Vector2i(int(cell_pair[0]), int(cell_pair[1]))
		collectors.append(cell)
		_spawn_collector(cell)

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

	crystals_changed.emit(crystal_count)
	catalyst_changed.emit(catalyst_count)
	core_charge_changed.emit(core_energy)
	if core_repaired:
		core_repair_completed.emit()


func _autosave() -> void:
	var player_position := player.position if player != null else START_SPAWN
	var serialized_collectors := []
	for cell in collectors:
		serialized_collectors.append([cell.x, cell.y])
	var result := _save_service.save_state({
		"crystal_count": crystal_count,
		"catalyst_count": catalyst_count,
		"core_repaired": core_repaired,
		"core_energy": core_energy,
		"reactor_active": reactor_active,
		"harvested_clusters": harvested_clusters,
		"collectors": serialized_collectors,
		"carrying_collector": carrying_collector,
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
