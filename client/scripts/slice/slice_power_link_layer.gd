class_name SlicePowerLinkLayer
extends Node2D

## Subtle derived power-state feedback. The logical grid owns reachability and
## supplies one parent edge per powered relay; this layer only renders those
## edges below world actors and never persists topology.

const CABLE_COLOR := Color(0.05, 0.10, 0.11, 0.34)
const POWER_COLOR := Color(0.34, 0.86, 0.82, 0.38)
const CABLE_WIDTH := 2.0
const POWER_WIDTH := 1.0
const SAG_PIXELS := 4.0

var _links: Array[Dictionary] = []


func set_links(links: Array[Dictionary]) -> void:
	_links = links.duplicate(true)
	queue_redraw()


func link_count() -> int:
	return _links.size()


func links_snapshot() -> Array[Dictionary]:
	return _links.duplicate(true)


func _draw() -> void:
	for link in _links:
		var start := Vector2(link.get("from_position", Vector2.ZERO))
		var finish := Vector2(link.get("to_position", Vector2.ZERO))
		var midpoint := (start + finish) * 0.5 + Vector2.DOWN * SAG_PIXELS
		var points := PackedVector2Array([start, midpoint, finish])
		draw_polyline(points, CABLE_COLOR, CABLE_WIDTH, false)
		draw_polyline(points, POWER_COLOR, POWER_WIDTH, false)
