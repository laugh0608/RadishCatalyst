class_name SlicePowerLinkLayer
extends Node2D

## Derived binary power feedback. The logical grid owns reachability and one
## real parent edge per powered relay / consumer; this layer renders each edge
## only in an explicit placement or inspection context and never persists it.

const POWER_COLOR := Color(0.345, 0.769, 0.749, 0.92)
const POWER_WIDTH := 1.0
const CONTEXT_NORMAL := "normal"
const CONTEXT_PLACEMENT := "placement"
const CONTEXT_DEVICE := "device"

var _links: Array[Dictionary] = []
var _context := CONTEXT_NORMAL


func _ready() -> void:
	z_index = 1
	visible = false


func set_links(links: Array[Dictionary]) -> void:
	_links = links.duplicate(true)
	queue_redraw()


func link_count() -> int:
	return _links.size()


func links_snapshot() -> Array[Dictionary]:
	return _links.duplicate(true)


func set_context(context: String) -> void:
	if context not in [CONTEXT_NORMAL, CONTEXT_PLACEMENT, CONTEXT_DEVICE]:
		push_error("Unsupported power-link presentation context: %s" % context)
		return
	_context = context
	visible = _context != CONTEXT_NORMAL
	modulate = Color.WHITE if _context == CONTEXT_PLACEMENT else Color(1, 1, 1, 0.82)
	queue_redraw()


func context() -> String:
	return _context


func context_visible() -> bool:
	return visible


func _draw() -> void:
	for link in _links:
		var start := Vector2(link.get("from_position", Vector2.ZERO))
		var finish := Vector2(link.get("to_position", Vector2.ZERO))
		draw_line(start, finish, POWER_COLOR, POWER_WIDTH, false)
