class_name SlicePowerLinkLayer
extends Node2D

## Derived binary power feedback. The logical grid owns reachability and one
## real parent edge per powered relay / consumer; this layer renders each edge
## as the single 1px segment locked by Gate A and never persists topology.

const POWER_COLOR := Color(0.345, 0.769, 0.749, 0.92)
const POWER_WIDTH := 1.0

var _links: Array[Dictionary] = []


func _ready() -> void:
	z_index = 1


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
		draw_line(start, finish, POWER_COLOR, POWER_WIDTH, false)
