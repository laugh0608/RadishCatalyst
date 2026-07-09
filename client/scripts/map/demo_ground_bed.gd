extends Node2D
## R1 地形地基：把首屏 GroundTileMap 的真实岩地 tile 覆盖扩展到填满可视地面，
## 并关闭旧的深色 ColorRect 背景，消除"空背景 + 悬浮物"。
##
## 本节点只放置既有 TileSet 中的真实 tile，不做任何程序绘制视觉层。
## 地表贴图质量（亮度 / 细节 / 暖调）属素材范畴，由 AI 管线重生成 tile 解决，不在本脚本内补。

const ROCK_SOURCE_ID := 0
const ROCK_ATLAS := Vector2i(0, 0)

## 岩地覆盖范围（tile 坐标，含端点），默认覆盖基地到污染 / 残骸入口的首小时可视地面。
@export var fill_tile_min := Vector2i(-18, -11)
@export var fill_tile_max := Vector2i(24, 11)

## 首屏 GroundTileMap 相对本节点的路径。
@export var ground_tilemap_path := NodePath("../DemoPresentationFirstScreen/GroundTileMap")

## 需要关闭的旧深色背景色块（相对本节点父级），避免铺不到的边缘露出黑底。
@export var dark_backdrop_nodes: PackedStringArray = ["Background"]

func _ready() -> void:
	_fill_ground_bed()
	_hide_dark_backdrops()

func _fill_ground_bed() -> void:
	var ground := get_node_or_null(ground_tilemap_path) as TileMapLayer
	if ground == null:
		push_warning("GroundBed: 未找到 GroundTileMap，跳过地形填充")
		return
	for y in range(fill_tile_min.y, fill_tile_max.y + 1):
		for x in range(fill_tile_min.x, fill_tile_max.x + 1):
			var cell := Vector2i(x, y)
			# 只填补空缺格，保留原有已铺设的地表与接缝细节。
			if ground.get_cell_source_id(cell) == -1:
				ground.set_cell(cell, ROCK_SOURCE_ID, ROCK_ATLAS)

func _hide_dark_backdrops() -> void:
	var parent := get_parent()
	if parent == null:
		return
	for node_name in dark_backdrop_nodes:
		var node := parent.get_node_or_null(NodePath(node_name)) as CanvasItem
		if node != null:
			node.visible = false
