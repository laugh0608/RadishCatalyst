extends Node2D
class_name DemoPresentationCoreStation

const PRESENTATION_PROCESS_PRIORITY := 220
const CORE_FOCUS_RECT := Rect2(Vector2(3860.0, -280.0), Vector2(420.0, 560.0))
const CONTEXT_MARKER_ALPHA := 0.012
const LOCAL_MARKER_ALPHA := 0.08

const CONTEXT_LAYER_ALPHAS := [
	{"path": "DemoRoutePresentationLayer", "alpha": 0.0},
	{"path": "SceneArtFoundationLayer", "alpha": 0.0},
	{"path": "NonCoreSceneIdentityLayer", "alpha": 0.0},
	{"path": "FunctionalTransitionSpatialPlayabilityLayer", "alpha": 0.0},
	{"path": "MidfieldRoutePlayabilityLayer", "alpha": 0.0},
	{"path": "WindCorridorTransitionPlayabilityLayer", "alpha": 0.0},
	{"path": "CoreApproachHandoffLayer", "alpha": 0.0},
	{"path": "CoreStabilizationRunLayer", "alpha": 0.0},
	{"path": "DemoCoreStabilizationVisualLayer", "alpha": 0.0},
	{"path": "DemoRegionIndustrialValueLayer", "alpha": 0.0},
	{"path": "PrototypeVisualPriorityLayer", "alpha": 0.0},
	{"path": "CurrentObjectiveGuidanceLayer", "alpha": 0.018},
]

const CONTEXT_RECT_ALPHAS := [
	{"path": "RegionPhaseWellTether", "alpha": 0.0},
	{"path": "RegionDemoStabilizationCore", "alpha": 0.012},
	{"path": "MainRouteSpine", "alpha": 0.0},
	{"path": "DemoRoutePresentationLayer/DemoRouteCoreApproachFlow", "alpha": 0.0},
	{"path": "DemoRoutePresentationLayer/DemoRouteCoreBand", "alpha": 0.0},
]

var context_original_modulates: Dictionary = {}
var context_rect_original_colors: Dictionary = {}
var core_focus_active := false


func _ready() -> void:
	process_priority = PRESENTATION_PROCESS_PRIORITY
	refresh_focus_visibility(_get_player_position())


func _process(_delta: float) -> void:
	refresh_focus_visibility(_get_player_position())


func refresh_focus_visibility(player_position: Vector2) -> void:
	core_focus_active = CORE_FOCUS_RECT.has_point(player_position)
	_set_context_layers_muted(core_focus_active)
	_set_context_rects_muted(core_focus_active)
	_set_interactable_cues_muted(core_focus_active, player_position)


func is_core_focus_active() -> bool:
	return core_focus_active


func _set_context_layers_muted(should_mute: bool) -> void:
	var map_root := get_parent()
	if map_root == null:
		return
	for config in CONTEXT_LAYER_ALPHAS:
		var node_path := String(config["path"])
		var canvas_item := map_root.get_node_or_null(node_path) as CanvasItem
		if canvas_item == null:
			continue
		if should_mute:
			if not context_original_modulates.has(node_path):
				context_original_modulates[node_path] = canvas_item.modulate
			var muted_modulate := context_original_modulates[node_path] as Color
			muted_modulate.a = float(config["alpha"])
			canvas_item.modulate = muted_modulate
			continue
		if context_original_modulates.has(node_path):
			canvas_item.modulate = context_original_modulates[node_path] as Color
	if not should_mute:
		context_original_modulates.clear()


func _set_context_rects_muted(should_mute: bool) -> void:
	var map_root := get_parent()
	if map_root == null:
		return
	for config in CONTEXT_RECT_ALPHAS:
		var node_path := String(config["path"])
		var rect := map_root.get_node_or_null(node_path) as ColorRect
		if rect == null:
			continue
		if should_mute:
			if not context_rect_original_colors.has(node_path):
				context_rect_original_colors[node_path] = rect.color
			var muted_color := context_rect_original_colors[node_path] as Color
			muted_color.a = float(config["alpha"])
			rect.color = muted_color
			continue
		if context_rect_original_colors.has(node_path):
			rect.color = context_rect_original_colors[node_path] as Color
	if not should_mute:
		context_rect_original_colors.clear()


func _set_interactable_cues_muted(should_mute: bool, player_position: Vector2) -> void:
	if not should_mute:
		return
	var map_root := get_parent()
	if map_root == null:
		return
	var interactables := map_root.get_node_or_null("Interactables")
	if interactables == null:
		return
	for child in interactables.get_children():
		var interactable := child as PrototypeInteractable
		if interactable == null:
			continue
		var label := interactable.get_node_or_null("Label") as Label
		if label != null:
			label.visible = false
		var focus_ring := interactable.get_node_or_null("FocusRing") as ColorRect
		if focus_ring != null:
			focus_ring.visible = false
		var marker := interactable.get_node_or_null("Marker") as ColorRect
		if marker == null:
			continue
		marker.scale = Vector2.ONE
		var marker_modulate := marker.modulate
		var marker_alpha := LOCAL_MARKER_ALPHA if interactable.position.distance_to(player_position) <= 220.0 else CONTEXT_MARKER_ALPHA
		marker_modulate.a = minf(marker_modulate.a, marker_alpha)
		marker.modulate = marker_modulate


func _get_player_position() -> Vector2:
	var map_root := get_parent()
	if map_root == null:
		return Vector2.INF
	var player := map_root.get_node_or_null("Player") as Node2D
	if player == null:
		return Vector2.INF
	return player.position
