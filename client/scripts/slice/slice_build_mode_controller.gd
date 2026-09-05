class_name SliceBuildModeController
extends Node2D

## Owns the transient construction view. It changes presentation and input
## context only; production, logistics and persisted world state keep running.

const BUILD_ZOOM := Vector2(1.5, 1.5)
const OBSTRUCTION_COLOR := Color(1.0, 1.0, 1.0, 0.34)

signal changed(active: bool)

var _active := false
var _camera: Camera2D
var _normal_zoom := Vector2.ONE
var _world_layer: Node2D
var _instances: Array[SliceBuildingInstance] = []
var _overlay := SliceBuildModeOverlay.new()
var _original_modulates: Dictionary = {}
var _original_self_modulates: Dictionary = {}


func setup(
	_map: Node2D,
	camera: Camera2D,
	world_layer: Node2D,
	map_size: Vector2i,
	tile_size: float,
	instances: Array[SliceBuildingInstance]
) -> void:
	_camera = camera
	_world_layer = world_layer
	_instances = instances
	_overlay.name = "BuildModeOverlay"
	_overlay.z_index = 40
	_overlay.visible = false
	add_child(_overlay)
	_overlay.configure(map_size, tile_size, instances)


func enter() -> void:
	if _active:
		return
	_active = true
	_normal_zoom = _camera.zoom
	_camera.zoom = BUILD_ZOOM
	_overlay.visible = true
	_refresh_obstructions()
	changed.emit(true)


func exit() -> void:
	if not _active:
		return
	_active = false
	_camera.zoom = _normal_zoom
	_overlay.visible = false
	_restore_obstructions()
	changed.emit(false)


func is_active() -> bool:
	return _active


func refresh_instances(instances: Array[SliceBuildingInstance]) -> void:
	_instances = instances
	_overlay.refresh_instances(instances)
	if _active:
		_refresh_obstructions()


func _refresh_obstructions() -> void:
	_restore_obstructions()
	for child in _world_layer.get_children():
		var item := child as CanvasItem
		if item == null:
			continue
		if item is SliceBuildingInstance:
			_dim_building_body(item as SliceBuildingInstance)
		elif not _is_essential(item):
			_original_modulates[item] = item.modulate
			item.modulate = OBSTRUCTION_COLOR
	for instance in _instances:
		_dim_building_body(instance)


func _is_essential(item: CanvasItem) -> bool:
	return (
		item is SlicePlayer
		or item is SliceBuildingInstance
		or item.name in [
			"OutpostCoreDamaged",
			"OutpostCoreVisualSortShell",
			"PowerLinks",
		]
	)


func _restore_obstructions() -> void:
	for item in _original_modulates:
		if is_instance_valid(item):
			item.modulate = _original_modulates[item]
	for item in _original_self_modulates:
		if is_instance_valid(item):
			item.self_modulate = _original_self_modulates[item]
	_original_modulates.clear()
	_original_self_modulates.clear()


func _dim_building_body(instance: SliceBuildingInstance) -> void:
	if (
		instance == null
		or instance.definition == null
		or instance.definition.is_floor
		or instance is SliceConveyor
	):
		return
	var sprite := instance.get_node_or_null("Sprite") as CanvasItem
	if sprite == null or _original_self_modulates.has(sprite):
		return
	_original_self_modulates[sprite] = sprite.self_modulate
	sprite.self_modulate = Color(1.0, 1.0, 1.0, 0.58)
