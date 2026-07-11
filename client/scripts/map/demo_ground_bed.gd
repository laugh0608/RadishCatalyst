extends Node2D
## R1 地形与平台地基：用真实岩地 tile 填满首屏可视地面，并把基地设备
## 收拢到有边界的真实金属平台上；同时关闭旧深色 ColorRect 背景。
##
## 本节点只选择和放置既有 TileSet 中的真实 atlas tile，不做程序绘制或贴图生成。

const ROCK_SOURCE_ID := 0
const ROCK_MACRO_TILE_SIZE := 4
const ROCK_MACRO_VARIANT_COUNT := 3
const PLATFORM_SOURCE_ID := 1
const PLATFORM_MACRO_TILE_SIZE := 4
const PLATFORM_MACRO_VARIANT_COUNT := 3
const PLATFORM_ROW_RANGES := {
	-3: Vector2i(-6, -3),
	-2: Vector2i(-6, 0),
	-1: Vector2i(-6, 1),
	0: Vector2i(-6, 1),
	1: Vector2i(-5, 0),
	2: Vector2i(-5, -1),
}

## 岩地覆盖范围（tile 坐标，含端点），默认覆盖基地到污染 / 残骸入口的首小时可视地面。
@export var fill_tile_min := Vector2i(-18, -11)
@export var fill_tile_max := Vector2i(24, 11)

## 首屏 GroundTileMap 相对本节点的路径。
@export var ground_tilemap_path := NodePath("../DemoPresentationFirstScreen/GroundTileMap")
@export var platform_tilemap_path := NodePath("../DemoPresentationFirstScreen/MetalPlatformTileMap")

## 需要关闭的旧深色背景色块（相对本节点父级），避免铺不到的边缘露出黑底。
@export var dark_backdrop_nodes: PackedStringArray = ["Background"]

func _ready() -> void:
	_fill_ground_bed()
	_build_base_platform()
	_hide_dark_backdrops()

func _fill_ground_bed() -> void:
	var ground := get_node_or_null(ground_tilemap_path) as TileMapLayer
	if ground == null:
		push_warning("GroundBed: 未找到 GroundTileMap，跳过地形填充")
		return
	for y in range(fill_tile_min.y, fill_tile_max.y + 1):
		for x in range(fill_tile_min.x, fill_tile_max.x + 1):
			var cell := Vector2i(x, y)
			var source_id := ground.get_cell_source_id(cell)
			# 空格补岩地；既有岩地同步换成确定性变体，其他来源保持不动。
			if source_id == -1 or source_id == ROCK_SOURCE_ID:
				ground.set_cell(cell, ROCK_SOURCE_ID, _rock_atlas_for_cell(cell))

func _rock_atlas_for_cell(cell: Vector2i) -> Vector2i:
	# 每个真实候选按 4x4 个 64px tile 保留完整纹理关系，避免把同一裂纹压进每个格子。
	# 宏块之间只做确定性候选选择，不旋转、镜像或程序生成视觉内容。
	var macro_cell := Vector2i(
		floori(float(cell.x) / float(ROCK_MACRO_TILE_SIZE)),
		floori(float(cell.y) / float(ROCK_MACRO_TILE_SIZE))
	)
	var mixed := macro_cell.x * 92821 + macro_cell.y * 68917 + macro_cell.x * macro_cell.y * 97
	var macro_variant := absi(mixed) % ROCK_MACRO_VARIANT_COUNT
	return Vector2i(
		macro_variant * ROCK_MACRO_TILE_SIZE + posmod(cell.x, ROCK_MACRO_TILE_SIZE),
		posmod(cell.y, ROCK_MACRO_TILE_SIZE)
	)

func _build_base_platform() -> void:
	var platform := get_node_or_null(platform_tilemap_path) as TileMapLayer
	if platform == null:
		push_warning("GroundBed: 未找到 MetalPlatformTileMap，跳过基地平台")
		return
	platform.clear()
	platform.visible = true
	platform.modulate = Color(0.96, 0.91, 0.82, 1.0)
	for y in PLATFORM_ROW_RANGES:
		var x_range: Vector2i = PLATFORM_ROW_RANGES[y]
		for x in range(x_range.x, x_range.y + 1):
			var cell := Vector2i(x, y)
			platform.set_cell(cell, PLATFORM_SOURCE_ID, _platform_atlas_for_cell(cell))

func _platform_atlas_for_cell(cell: Vector2i) -> Vector2i:
	var macro_cell := Vector2i(
		floori(float(cell.x) / float(PLATFORM_MACRO_TILE_SIZE)),
		floori(float(cell.y) / float(PLATFORM_MACRO_TILE_SIZE))
	)
	var mixed := macro_cell.x * 57347 + macro_cell.y * 91493 + macro_cell.x * macro_cell.y * 131
	var macro_variant := absi(mixed) % PLATFORM_MACRO_VARIANT_COUNT
	return Vector2i(
		macro_variant * PLATFORM_MACRO_TILE_SIZE + posmod(cell.x, PLATFORM_MACRO_TILE_SIZE),
		posmod(cell.y, PLATFORM_MACRO_TILE_SIZE)
	)

func _hide_dark_backdrops() -> void:
	var parent := get_parent()
	if parent == null:
		return
	for node_name in dark_backdrop_nodes:
		var node := parent.get_node_or_null(NodePath(node_name)) as CanvasItem
		if node != null:
			node.visible = false
