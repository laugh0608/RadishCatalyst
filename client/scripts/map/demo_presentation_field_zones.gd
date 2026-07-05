extends Node2D
class_name DemoPresentationFieldZones

const PRESENTATION_FOCUS_RECTS := [
	Rect2(Vector2(0.0, -260.0), Vector2(360.0, 420.0)),
	Rect2(Vector2(3600.0, -280.0), Vector2(700.0, 560.0)),
]

const CONTEXT_LAYER_ALPHAS := [
	{"path": "OpeningSceneLayer", "alpha": 0.0},
	{"path": "DemoCoreSceneSpaceLayer", "alpha": 0.0},
	{"path": "DemoRoutePresentationLayer", "alpha": 0.0},
	{"path": "SceneArtFoundationLayer", "alpha": 0.0},
	{"path": "DemoFirstIndustrialPathVisualLayer", "alpha": 0.0},
	{"path": "DemoCrystalResourceVisualLayer", "alpha": 0.0},
	{"path": "DemoPollutionBoundaryVisualLayer", "alpha": 0.0},
	{"path": "DemoCoreStabilizationVisualLayer", "alpha": 0.0},
	{"path": "CoreApproachHandoffLayer", "alpha": 0.0},
	{"path": "CoreStabilizationRunLayer", "alpha": 0.0},
	{"path": "DemoRegionIndustrialValueLayer", "alpha": 0.0},
	{"path": "PrototypeVisualPriorityLayer", "alpha": 0.0},
	{"path": "DemoBaseHandoffAssetArtPass", "alpha": 0.0},
	{"path": "DemoBaseStartupPresentationLayer", "alpha": 0.0},
]

const CONTEXT_RECT_ALPHAS := [
	{"path": "RegionCrystal", "alpha": 0.018},
	{"path": "RegionPollution", "alpha": 0.012},
	{"path": "RegionDemoStabilizationCore", "alpha": 0.012},
	{"path": "MainRouteSpine", "alpha": 0.0001},
	{"path": "BaseToCrystalRouteBand", "alpha": 0.0001},
	{"path": "CrystalToPollutionRouteBand", "alpha": 0.0001},
	{"path": "DemoRoutePresentationLayer/DemoRouteCoreApproachFlow", "alpha": 0.0},
	{"path": "DemoRoutePresentationLayer/DemoRouteCoreBand", "alpha": 0.0},
	{"path": "RegionBoundaryCrystal", "alpha": 0.0001},
	{"path": "RegionBoundaryPollution", "alpha": 0.0001},
	{"path": "RegionBoundaryRuin", "alpha": 0.0001},
]

var context_original_modulates: Dictionary = {}
var context_rect_original_colors: Dictionary = {}
var field_focus_active := false


func _ready() -> void:
	refresh_focus_visibility(_get_player_position())


func _process(_delta: float) -> void:
	refresh_focus_visibility(_get_player_position())


func refresh_focus_visibility(player_position: Vector2) -> void:
	field_focus_active = is_field_focus_active_at(player_position)
	_set_context_layers_muted(field_focus_active)
	_set_context_rects_muted(field_focus_active)


func is_field_focus_active_at(player_position: Vector2) -> bool:
	for focus_rect in PRESENTATION_FOCUS_RECTS:
		var rect := focus_rect as Rect2
		if rect.has_point(player_position):
			return true
	return false


func is_field_focus_active() -> bool:
	return field_focus_active


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


func _get_player_position() -> Vector2:
	var map_root := get_parent()
	if map_root == null:
		return Vector2.INF
	var player := map_root.get_node_or_null("Player") as Node2D
	if player == null:
		return Vector2.INF
	return player.position
