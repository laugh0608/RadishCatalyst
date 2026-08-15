class_name SliceMinimap
extends Panel

## Current-slice minimap shell. It renders the real world through a shared
## World2D viewport, then layers durable fog and derived task markers above it.

const MAP_CENTER := Vector2(1280, 384)
const MAP_ZOOM := Vector2(0.078125, 0.078125)

var _world: SliceWorld
var _player: SlicePlayer
var _last_region := ""
var _last_intel := ""

@onready var _map_viewport: SubViewport = (
	$MapViewportContainer/MapViewport
)
@onready var _map_camera: Camera2D = (
	$MapViewportContainer/MapViewport/MapCamera
)
@onready var _overlay: SliceMinimapOverlay = $FogOverlay
@onready var _region_label: Label = $Header/Region
@onready var _intel_label: Label = $Intel


func setup(world: SliceWorld, player: SlicePlayer) -> void:
	_world = world
	_player = player
	_map_viewport.world_2d = world.get_viewport().world_2d
	_map_camera.position = MAP_CENTER
	_map_camera.zoom = MAP_ZOOM
	_map_camera.enabled = true
	_overlay.setup(world, player, world.first_journey.state)
	world.first_journey.changed.connect(_refresh)
	_refresh()


func _process(_delta: float) -> void:
	if _player == null:
		return
	var region := "前哨基地" if _player.position.x < 1280.0 else "晶体矿脉"
	if region != _last_region:
		_last_region = region
		_region_label.text = region


func _refresh() -> void:
	if _world == null:
		return
	var stage := String(
		_world.current_journey_guidance().get("stage", "")
	)
	var intel := "基地已知范围"
	match stage:
		"find_crystals":
			intel = "情报 · 东侧晶体信号"
		"craft_parts":
			intel = "晶体已齐 · 打开终端"
		"repair_core":
			intel = "目标 · 返回前哨核心"
		"field":
			intel = "外勤 · 东侧裂晶区"
	if intel != _last_intel:
		_last_intel = intel
		_intel_label.text = intel
	_overlay.queue_redraw()
