extends Control

const Rules := preload("res://data/factory/discovery_rules.gd")
const MapRules := preload("res://data/factory/rules.gd")
const SIDE := MapRules.MAX_CELL - MapRules.MIN_CELL
const ORIGIN := Vector2.ONE * MapRules.MIN_CELL
const SCALE := 3.0
const TARGET_COLOR := Color("ffce78")
const PLAYER_COLOR := Color("b7fff3")

var target: Vector2
var player: Vector2
var forward := Vector2.UP
var terrain: ImageTexture
var terrain_key: Array = []


func _ready() -> void:
	custom_minimum_size = Vector2.ONE * SIDE * SCALE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func sync(model: RefCounted, actor: Dictionary, destination: Vector2, camera_yaw: float) -> String:
	var key: Array = [model.map_id, model.discovery.passages.duplicate(), model.revision]
	if key != terrain_key:
		terrain_key = key
		var image := Image.create_empty(SIDE, SIDE, false, Image.FORMAT_RGB8)
		for z in SIDE:
			for x in SIDE:
				var cell := Vector2i(x, z) + Vector2i(ORIGIN)
				var color := Color("253435")
				if Rules.open_cell(cell, model.discovery.passages, model.map_id):
					var e: Dictionary = model.entity_at(cell)
					color = Color("536863") if e.is_empty() or e.type == "belt" else Color("324441")
				image.set_pixel(x, z, color)
		terrain = ImageTexture.create_from_image(image)
		queue_redraw()
	var next := Vector2(actor.x, actor.z)
	var camera_forward := Vector2.UP.rotated(-deg_to_rad(camera_yaw))
	if player != next or target != destination or forward != camera_forward:
		queue_redraw()
	player = next
	target = destination
	forward = camera_forward
	var offset := target - player
	if offset.length() <= 2.0:
		return "已到目标附近"
	var bearings := ["北", "东北", "东", "东南", "南", "西南", "西", "西北"]
	var sector := posmod(roundi(atan2(offset.x, -offset.y) / (PI / 4.0)), 8)
	return "%s方 · 直线约 %d 格" % [bearings[sector], roundi(offset.length())]


func _draw() -> void:
	if terrain == null:
		return
	draw_texture_rect(terrain, Rect2(Vector2.ZERO, size), false)
	var pin := (target - ORIGIN) * SCALE
	draw_circle(pin, 6.0, Color("212d2b"), true, -1.0, true)
	draw_circle(pin, 5.0, TARGET_COLOR, false, 2.0, true)
	var here := (player - ORIGIN) * SCALE
	var wing := forward.orthogonal() * 4.0
	var marker := PackedVector2Array([here + forward * 6.0, here - forward * 3.0 + wing, here - forward * 3.0 - wing])
	draw_colored_polygon(marker, PLAYER_COLOR)
	marker.append(marker[0])
	draw_polyline(marker, Color("143632"), 1.0, true)
