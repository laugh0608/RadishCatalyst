extends RefCounted
class_name DemoCrystalWorkfaceAssetArtPass

const ASSET_WORKFACE_FLOOR_ID := "crystal_workface_asset.workface_floor"
const ASSET_CURRENT_VEIN_ID := "crystal_workface_asset.current_vein"
const ASSET_COLLECTOR_MACHINE_ID := "crystal_workface_asset.collector_machine"
const ASSET_OUTPUT_TRAY_ID := "crystal_workface_asset.output_tray_loaded"

const ASSET_WORKFACE_FLOOR := preload("res://assets/sprites/demo_crystal_workface/workface_floor.svg")
const ASSET_CURRENT_VEIN := preload("res://assets/sprites/demo_crystal_workface/current_crystal_vein.svg")
const ASSET_COLLECTOR_MACHINE := preload("res://assets/sprites/demo_crystal_workface/crystal_collector_machine.svg")
const ASSET_OUTPUT_TRAY := preload("res://assets/sprites/demo_crystal_workface/output_tray_loaded.svg")

const ASSET_MANIFEST := {
	ASSET_WORKFACE_FLOOR_ID: {
		"path": "res://assets/sprites/demo_crystal_workface/workface_floor.svg",
		"role": "local_terrain",
		"render": "sprite"
	},
	ASSET_CURRENT_VEIN_ID: {
		"path": "res://assets/sprites/demo_crystal_workface/current_crystal_vein.svg",
		"role": "harvestable_resource",
		"render": "sprite"
	},
	ASSET_COLLECTOR_MACHINE_ID: {
		"path": "res://assets/sprites/demo_crystal_workface/crystal_collector_machine.svg",
		"role": "collector_device",
		"render": "sprite"
	},
	ASSET_OUTPUT_TRAY_ID: {
		"path": "res://assets/sprites/demo_crystal_workface/output_tray_loaded.svg",
		"role": "pickup_output",
		"render": "sprite"
	},
}

const RESOURCE_SHAPES := [
	"crystal.workface.asset.current_vein_sprite",
	"crystal.workface.asset.collector_machine_sprite",
	"crystal.workface.asset.output_tray_sprite",
	"crystal.workface.asset.enlarged_output_tray_subject"
]

const FLOW_SHAPES := [
	"flow.crystal_workface.asset.short_material_packets",
	"flow.crystal_workface.asset.tray_pickup_port",
	"flow.crystal_workface.asset.pickup_ready_signal"
]

const TERRAIN_SHAPES := [
	"terrain.crystal.workface.asset.floor_sprite",
	"terrain.crystal.workface.asset.local_ground_shadow",
	"terrain.crystal.workface.asset.legacy_geometry_backgrounded",
	"terrain.crystal.workface.asset.expanded_linework_suppression",
	"terrain.crystal.workface.asset.forward_pickup_tray",
	"terrain.crystal.workface.asset.sprite_manifest"
]

const WORKFACE_FLOW := Color(0.58, 0.96, 0.9, 0.72)
const PICKUP_FLOW := Color(0.9, 0.86, 0.46, 0.66)
const DARK_BACKING := Color(0.002, 0.012, 0.012, 0.84)


static func get_asset_ids() -> Array[String]:
	var ids: Array[String] = []
	for asset_id in ASSET_MANIFEST.keys():
		ids.append(String(asset_id))
	return ids


static func has_asset(asset_id: String) -> bool:
	return ASSET_MANIFEST.has(asset_id)


static func get_asset_path(asset_id: String) -> String:
	return String(ASSET_MANIFEST.get(asset_id, {}).get("path", ""))


static func get_asset_role(asset_id: String) -> String:
	return String(ASSET_MANIFEST.get(asset_id, {}).get("role", ""))


static func get_asset_render_mode(asset_id: String) -> String:
	return String(ASSET_MANIFEST.get(asset_id, {}).get("render", ""))


static func is_asset_available(asset_id: String) -> bool:
	return _get_asset_texture(asset_id) != null


static func get_resource_shape_ids() -> Array[String]:
	return _copy_shape_ids(RESOURCE_SHAPES)


static func get_flow_shape_ids() -> Array[String]:
	return _copy_shape_ids(FLOW_SHAPES)


static func get_terrain_shape_ids() -> Array[String]:
	return _copy_shape_ids(TERRAIN_SHAPES)


static func draw_workface(canvas: CanvasItem) -> void:
	if canvas == null:
		return

	_draw_workface_shadow(canvas)
	_draw_legacy_linework_suppression(canvas)
	_draw_asset(canvas, ASSET_WORKFACE_FLOOR_ID, Rect2(Vector2(-34.0, -186.0), Vector2(248.0, 164.0)), Color(0.92, 1.0, 0.92, 0.88))
	_draw_asset(canvas, ASSET_CURRENT_VEIN_ID, Rect2(Vector2(-14.0, -136.0), Vector2(94.0, 84.0)), Color(0.92, 1.0, 1.0, 0.98))
	_draw_asset(canvas, ASSET_COLLECTOR_MACHINE_ID, Rect2(Vector2(110.0, -170.0), Vector2(112.0, 82.0)), Color(0.96, 1.0, 0.92, 0.98))
	_draw_material_packets(canvas)
	_draw_pickup_tray_stage(canvas)
	_draw_asset(canvas, ASSET_OUTPUT_TRAY_ID, Rect2(Vector2(38.0, -148.0), Vector2(132.0, 88.0)), Color(1.0, 1.0, 0.9, 1.0))
	_draw_pickup_port(canvas)


static func _copy_shape_ids(source: Array) -> Array[String]:
	var ids: Array[String] = []
	for shape_id in source:
		ids.append(String(shape_id))
	return ids


static func _draw_workface_shadow(canvas: CanvasItem) -> void:
	var rect := Rect2(Vector2(-58.0, -208.0), Vector2(314.0, 218.0))
	canvas.draw_rect(rect, DARK_BACKING, true)
	canvas.draw_rect(rect.grow(-10.0), Color(0.05, 0.15, 0.14, 0.18), true)
	canvas.draw_rect(rect, Color(0.56, 0.92, 0.86, 0.18), false, 1.4, true)


static func _draw_legacy_linework_suppression(canvas: CanvasItem) -> void:
	for rect in [
		Rect2(Vector2(-42.0, -206.0), Vector2(300.0, 62.0)),
		Rect2(Vector2(152.0, -180.0), Vector2(98.0, 148.0)),
		Rect2(Vector2(-50.0, -74.0), Vector2(284.0, 78.0))
	]:
		canvas.draw_rect(rect, Color(0.001, 0.008, 0.009, 0.64), true)
		canvas.draw_rect(rect, Color(0.42, 0.76, 0.74, 0.05), false, 1.0, true)
	var cutout := PackedVector2Array([
		Vector2(-48.0, -186.0),
		Vector2(72.0, -218.0),
		Vector2(246.0, -178.0),
		Vector2(238.0, -38.0),
		Vector2(120.0, 10.0),
		Vector2(-52.0, -38.0),
		Vector2(-48.0, -186.0)
	])
	canvas.draw_colored_polygon(cutout, Color(0.002, 0.014, 0.015, 0.42))


static func _draw_material_packets(canvas: CanvasItem) -> void:
	var points: Array[Vector2] = [
		Vector2(34.0, -96.0),
		Vector2(66.0, -112.0),
		Vector2(104.0, -116.0),
		Vector2(150.0, -126.0)
	]
	canvas.draw_polyline(PackedVector2Array(points), Color(0.004, 0.016, 0.014, 0.82), 7.0, true)
	canvas.draw_polyline(PackedVector2Array(points), WORKFACE_FLOW, 2.6, true)
	var flow_start := points[0]
	var flow_end := points[points.size() - 1]
	for ratio in [0.28, 0.5, 0.72]:
		var center := flow_start.lerp(flow_end, ratio)
		canvas.draw_circle(center, 4.0, Color(WORKFACE_FLOW.r, WORKFACE_FLOW.g, WORKFACE_FLOW.b, 0.74))
		canvas.draw_circle(center + Vector2(1.0, -1.0), 1.6, Color(0.94, 1.0, 0.96, 0.82))


static func _draw_pickup_tray_stage(canvas: CanvasItem) -> void:
	var tray_stage := Rect2(Vector2(38.0, -152.0), Vector2(134.0, 94.0))
	canvas.draw_rect(tray_stage.grow(6.0), Color(0.001, 0.008, 0.007, 0.82), true)
	canvas.draw_rect(tray_stage, Color(0.08, 0.11, 0.065, 0.36), true)
	canvas.draw_rect(tray_stage, Color(PICKUP_FLOW.r, PICKUP_FLOW.g, PICKUP_FLOW.b, 0.34), false, 1.7, true)
	canvas.draw_line(Vector2(52.0, -66.0), Vector2(158.0, -66.0), Color(PICKUP_FLOW.r, PICKUP_FLOW.g, PICKUP_FLOW.b, 0.36), 2.0, true)


static func _draw_pickup_port(canvas: CanvasItem) -> void:
	var port := Rect2(Vector2(74.0, -62.0), Vector2(56.0, 20.0))
	canvas.draw_rect(port.grow(4.0), Color(0.004, 0.012, 0.01, 0.78), true)
	canvas.draw_rect(port, Color(PICKUP_FLOW.r, PICKUP_FLOW.g, PICKUP_FLOW.b, 0.18), true)
	canvas.draw_rect(port, PICKUP_FLOW, false, 1.8, true)
	canvas.draw_line(Vector2(102.0, -42.0), Vector2(102.0, -24.0), Color(PICKUP_FLOW.r, PICKUP_FLOW.g, PICKUP_FLOW.b, 0.62), 2.0, true)
	for offset in [-15.0, 0.0, 15.0]:
		canvas.draw_circle(Vector2(102.0 + offset, -52.0), 2.8, Color(PICKUP_FLOW.r, PICKUP_FLOW.g, PICKUP_FLOW.b, 0.68))
	canvas.draw_arc(Vector2(102.0, -52.0), 30.0, PI * 0.08, PI * 0.92, 24, Color(PICKUP_FLOW.r, PICKUP_FLOW.g, PICKUP_FLOW.b, 0.38), 1.4, true)


static func _draw_asset(canvas: CanvasItem, asset_id: String, rect: Rect2, modulate: Color) -> void:
	var texture := _get_asset_texture(asset_id)
	if texture == null:
		return

	canvas.draw_texture_rect(texture, rect, false, modulate)


static func _get_asset_texture(asset_id: String) -> Texture2D:
	match asset_id:
		ASSET_WORKFACE_FLOOR_ID:
			return ASSET_WORKFACE_FLOOR
		ASSET_CURRENT_VEIN_ID:
			return ASSET_CURRENT_VEIN
		ASSET_COLLECTOR_MACHINE_ID:
			return ASSET_COLLECTOR_MACHINE
		ASSET_OUTPUT_TRAY_ID:
			return ASSET_OUTPUT_TRAY
		_:
			return null
