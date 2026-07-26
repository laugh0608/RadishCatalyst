extends Control
class_name StartupMenu

const PRIMARY_COLOR := Color(0.82, 0.96, 0.88, 1.0)
const MUTED_COLOR := Color(0.52, 0.66, 0.62, 1.0)
const ACCENT_COLOR := Color(0.96, 0.72, 0.28, 1.0)
const PANEL_COLOR := Color(0.02, 0.045, 0.048, 0.82)
const BUTTON_COLOR := Color(0.045, 0.1, 0.1, 0.92)
const BUTTON_HOVER_COLOR := Color(0.07, 0.16, 0.15, 0.96)
const BUTTON_DISABLED_COLOR := Color(0.035, 0.045, 0.045, 0.78)

var has_loadable_save := false
var slot_summary_text := "槽位 01：读取中"

@onready var title_label: Label = $ContentRoot/TitleLabel
@onready var subtitle_label: Label = $ContentRoot/SubtitleLabel
@onready var slot_summary_label: Label = $ContentRoot/SlotSummaryLabel
@onready var new_game_button: Button = $ContentRoot/MenuButtons/NewGameButton
@onready var load_game_button: Button = $ContentRoot/MenuButtons/LoadGameButton
@onready var multiplayer_button: Button = $ContentRoot/MenuButtons/MultiplayerButton
@onready var settings_button: Button = $ContentRoot/MenuButtons/SettingsButton
@onready var quit_button: Button = $ContentRoot/MenuButtons/QuitButton
@onready var settings_panel: ColorRect = $SettingsPanel
@onready var settings_title_label: Label = $SettingsPanel/SettingsTitleLabel
@onready var settings_body_label: Label = $SettingsPanel/SettingsBodyLabel
@onready var settings_back_button: Button = $SettingsPanel/SettingsBackButton

signal new_game_requested
signal load_game_requested
signal quit_requested


func _ready() -> void:
	_apply_text_style()
	_apply_button_style()
	new_game_button.pressed.connect(_on_new_game_pressed)
	load_game_button.pressed.connect(_on_load_game_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	settings_back_button.pressed.connect(_on_settings_back_pressed)
	multiplayer_button.disabled = true
	settings_panel.visible = false
	_refresh_save_summary()
	new_game_button.grab_focus()


func configure_save_summary(summary: Dictionary) -> void:
	has_loadable_save = bool(summary.get("has_loadable_save", false))
	slot_summary_text = "%s：%s" % [
		String(summary.get("display_name", "槽位 01")),
		String(summary.get("status", "空槽位"))
	]
	var details := String(summary.get("details", ""))
	if not details.is_empty():
		slot_summary_text = "%s\n%s" % [slot_summary_text, details]
	_refresh_save_summary()


func _refresh_save_summary() -> void:
	if slot_summary_label != null:
		slot_summary_label.text = slot_summary_text
	if load_game_button != null:
		load_game_button.disabled = not has_loadable_save
		if has_loadable_save:
			load_game_button.tooltip_text = "读取切片存档，继续前哨恢复。"
		else:
			load_game_button.tooltip_text = "暂无可读取的切片存档。"


func _apply_text_style() -> void:
	for label in [title_label, subtitle_label, slot_summary_label, settings_title_label, settings_body_label]:
		if label == null:
			continue
		label.add_theme_color_override("font_color", PRIMARY_COLOR)
		label.add_theme_font_size_override("font_size", 18)
	title_label.add_theme_font_size_override("font_size", 54)
	subtitle_label.add_theme_color_override("font_color", ACCENT_COLOR)
	slot_summary_label.add_theme_color_override("font_color", MUTED_COLOR)
	settings_body_label.add_theme_color_override("font_color", MUTED_COLOR)


func _apply_button_style() -> void:
	for button in [new_game_button, load_game_button, multiplayer_button, settings_button, quit_button, settings_back_button]:
		if button == null:
			continue
		button.add_theme_color_override("font_color", PRIMARY_COLOR)
		button.add_theme_color_override("font_disabled_color", MUTED_COLOR)
		button.add_theme_font_size_override("font_size", 20)
		button.add_theme_stylebox_override("normal", _make_button_style(BUTTON_COLOR, Color(0.26, 0.52, 0.48, 0.86)))
		button.add_theme_stylebox_override("hover", _make_button_style(BUTTON_HOVER_COLOR, Color(0.55, 0.88, 0.76, 0.96)))
		button.add_theme_stylebox_override("pressed", _make_button_style(Color(0.03, 0.08, 0.08, 0.96), ACCENT_COLOR))
		button.add_theme_stylebox_override("disabled", _make_button_style(BUTTON_DISABLED_COLOR, Color(0.16, 0.22, 0.2, 0.74)))
	if settings_panel != null:
		settings_panel.color = PANEL_COLOR


func _make_button_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


func _draw() -> void:
	var view_size := size
	if view_size.x <= 0.0 or view_size.y <= 0.0:
		view_size = Vector2(1920.0, 1080.0)
	_draw_space_backdrop(view_size)
	_draw_outpost_silhouette(view_size)
	_draw_pollution_horizon(view_size)
	_draw_menu_grounding(view_size)


func _draw_space_backdrop(view_size: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, view_size), Color(0.012, 0.021, 0.024, 1.0))
	draw_rect(Rect2(Vector2(0.0, view_size.y * 0.58), Vector2(view_size.x, view_size.y * 0.42)), Color(0.034, 0.049, 0.045, 1.0))
	for index in range(9):
		var x := view_size.x * (0.08 + float(index) * 0.105)
		var y := view_size.y * (0.12 + float(index % 3) * 0.06)
		draw_rect(Rect2(Vector2(x, y), Vector2(2.0 + float(index % 2), 2.0 + float(index % 2))), Color(0.5, 0.72, 0.68, 0.42))


func _draw_outpost_silhouette(view_size: Vector2) -> void:
	var ground_y := view_size.y * 0.68
	var base_x := view_size.x * 0.47
	draw_rect(Rect2(Vector2(base_x - 360.0, ground_y - 42.0), Vector2(720.0, 62.0)), Color(0.04, 0.08, 0.078, 0.92))
	draw_rect(Rect2(Vector2(base_x - 300.0, ground_y - 78.0), Vector2(180.0, 70.0)), Color(0.055, 0.11, 0.11, 0.95))
	draw_rect(Rect2(Vector2(base_x - 70.0, ground_y - 122.0), Vector2(150.0, 114.0)), Color(0.05, 0.096, 0.094, 0.96))
	draw_rect(Rect2(Vector2(base_x + 150.0, ground_y - 88.0), Vector2(220.0, 80.0)), Color(0.044, 0.086, 0.082, 0.94))
	draw_rect(Rect2(Vector2(base_x - 12.0, ground_y - 190.0), Vector2(24.0, 78.0)), Color(0.036, 0.068, 0.068, 0.96))
	draw_line(Vector2(base_x, ground_y - 112.0), Vector2(base_x + 255.0, ground_y - 28.0), Color(0.34, 0.62, 0.58, 0.58), 4.0)
	draw_line(Vector2(base_x - 198.0, ground_y - 32.0), Vector2(base_x - 40.0, ground_y - 94.0), Color(0.86, 0.58, 0.2, 0.48), 3.0)
	for offset in [-250.0, -180.0, -20.0, 58.0, 204.0, 286.0]:
		draw_rect(Rect2(Vector2(base_x + offset, ground_y - 8.0), Vector2(42.0, 8.0)), Color(0.62, 0.9, 0.78, 0.52))
	draw_circle(Vector2(base_x + 8.0, ground_y - 132.0), 22.0, Color(0.38, 1.0, 0.85, 0.5))
	draw_circle(Vector2(base_x + 8.0, ground_y - 132.0), 8.0, Color(0.76, 1.0, 0.9, 0.82))


func _draw_pollution_horizon(view_size: Vector2) -> void:
	var start_x := view_size.x * 0.72
	var base_y := view_size.y * 0.64
	draw_rect(Rect2(Vector2(start_x, base_y - 70.0), Vector2(view_size.x - start_x, 160.0)), Color(0.18, 0.16, 0.05, 0.36))
	for index in range(5):
		var x := start_x + float(index) * 86.0
		draw_line(Vector2(x, base_y - 20.0), Vector2(x + 72.0, base_y + 26.0), Color(0.58, 0.5, 0.16, 0.38), 5.0)
		draw_circle(Vector2(x + 42.0, base_y + 18.0), 9.0 + float(index % 2) * 4.0, Color(0.84, 0.76, 0.22, 0.36))


func _draw_menu_grounding(view_size: Vector2) -> void:
	var panel_rect := Rect2(Vector2(view_size.x * 0.07, view_size.y * 0.16), Vector2(560.0, 620.0))
	draw_rect(panel_rect.grow(18.0), Color(0.005, 0.014, 0.016, 0.58))
	draw_line(panel_rect.position + Vector2(0.0, 82.0), panel_rect.position + Vector2(panel_rect.size.x, 82.0), Color(0.82, 0.7, 0.3, 0.46), 3.0)
	draw_line(Vector2(view_size.x * 0.07, view_size.y * 0.78), Vector2(view_size.x * 0.82, view_size.y * 0.78), Color(0.26, 0.48, 0.44, 0.45), 4.0)


func _on_new_game_pressed() -> void:
	new_game_requested.emit()


func _on_load_game_pressed() -> void:
	if not has_loadable_save:
		return
	load_game_requested.emit()


func _on_settings_pressed() -> void:
	settings_panel.visible = true
	settings_back_button.grab_focus()


func _on_settings_back_pressed() -> void:
	settings_panel.visible = false
	settings_button.grab_focus()


func _on_quit_pressed() -> void:
	quit_requested.emit()
