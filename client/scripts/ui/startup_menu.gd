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
var slot_summary_text := "世界目录：读取中"
var save_catalog: SliceSaveCatalog
var _active_worlds: Array[Dictionary] = []
var _trash_worlds: Array[Dictionary] = []
var _showing_trash := false
var _selected_world_id := ""
var _selected_trash_id := ""

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
@onready var world_panel: ColorRect = $WorldPanel
@onready var world_title_label: Label = $WorldPanel/WorldTitleLabel
@onready var world_count_label: Label = $WorldPanel/WorldCountLabel
@onready var active_worlds_button: Button = $WorldPanel/ActiveWorldsButton
@onready var trash_worlds_button: Button = $WorldPanel/TrashWorldsButton
@onready var world_item_list: ItemList = $WorldPanel/WorldItemList
@onready var world_details_label: Label = $WorldPanel/WorldDetailsLabel
@onready var world_name_input: LineEdit = $WorldPanel/WorldNameInput
@onready var world_status_label: Label = $WorldPanel/WorldStatusLabel
@onready var create_world_button: Button = $WorldPanel/Actions/CreateWorldButton
@onready var load_world_button: Button = $WorldPanel/Actions/LoadWorldButton
@onready var rename_world_button: Button = $WorldPanel/Actions/RenameWorldButton
@onready var trash_world_button: Button = $WorldPanel/Actions/TrashWorldButton
@onready var restore_world_button: Button = $WorldPanel/Actions/RestoreWorldButton
@onready var world_back_button: Button = $WorldPanel/Actions/WorldBackButton
@onready var trash_confirm_panel: ColorRect = $WorldPanel/TrashConfirmPanel
@onready var trash_confirm_label: Label = $WorldPanel/TrashConfirmPanel/ConfirmLabel
@onready var trash_confirm_button: Button = $WorldPanel/TrashConfirmPanel/ConfirmButton
@onready var trash_cancel_button: Button = $WorldPanel/TrashConfirmPanel/CancelButton

signal world_created(world_id: String)
signal world_load_requested(world_id: String)
signal quit_requested


func _ready() -> void:
	_apply_text_style()
	_apply_button_style()
	_apply_world_control_style()
	new_game_button.pressed.connect(_on_new_game_pressed)
	load_game_button.pressed.connect(_on_load_game_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	settings_back_button.pressed.connect(_on_settings_back_pressed)
	active_worlds_button.pressed.connect(_on_active_worlds_pressed)
	trash_worlds_button.pressed.connect(_on_trash_worlds_pressed)
	world_item_list.item_selected.connect(_on_world_item_selected)
	world_item_list.item_activated.connect(_on_world_item_activated)
	create_world_button.pressed.connect(_on_create_world_pressed)
	load_world_button.pressed.connect(_on_load_world_pressed)
	rename_world_button.pressed.connect(_on_rename_world_pressed)
	trash_world_button.pressed.connect(_on_trash_world_pressed)
	restore_world_button.pressed.connect(_on_restore_world_pressed)
	world_back_button.pressed.connect(_close_world_panel)
	trash_confirm_button.pressed.connect(_on_trash_confirmed)
	trash_cancel_button.pressed.connect(_close_trash_confirmation)
	multiplayer_button.disabled = true
	settings_panel.visible = false
	world_panel.visible = false
	trash_confirm_panel.visible = false
	_refresh_save_summary()
	new_game_button.grab_focus()


func configure_save_catalog(
	catalog: SliceSaveCatalog,
	notice: String = ""
) -> void:
	save_catalog = catalog
	_refresh_worlds()
	if not notice.is_empty():
		show_catalog_message(notice)


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


func show_catalog_message(message: String) -> void:
	if world_status_label != null:
		world_status_label.text = message


func _refresh_save_summary() -> void:
	if slot_summary_label != null:
		slot_summary_label.text = slot_summary_text
	if load_game_button != null:
		load_game_button.disabled = not has_loadable_save
		if has_loadable_save:
			load_game_button.tooltip_text = "读取切片存档，继续前哨恢复。"
		else:
			load_game_button.tooltip_text = "暂无可读取的切片存档。"


func _refresh_worlds() -> void:
	if save_catalog == null:
		return
	_active_worlds = save_catalog.list_worlds()
	_trash_worlds = save_catalog.list_trash()
	has_loadable_save = (
		not _active_worlds.is_empty()
		or not _trash_worlds.is_empty()
	)
	if _active_worlds.is_empty():
		slot_summary_text = "世界目录：尚未建立世界"
	else:
		var latest := _active_worlds[0]
		slot_summary_text = "%s：%s\n%s" % [
			String(latest.get("display_name", "未命名世界")),
			String(latest.get("status", "状态未知")),
			_world_progress_text(latest),
		]
	_refresh_save_summary()
	if world_panel != null and world_panel.visible:
		_rebuild_world_list()


func _open_world_panel(show_trash: bool, focus_name: bool = false) -> void:
	if save_catalog == null:
		show_catalog_message("世界目录尚未初始化。")
		return
	settings_panel.visible = false
	world_panel.visible = true
	trash_confirm_panel.visible = false
	_showing_trash = show_trash
	_refresh_worlds()
	_rebuild_world_list()
	if focus_name:
		world_name_input.grab_focus()
	else:
		world_item_list.grab_focus()


func _close_world_panel() -> void:
	trash_confirm_panel.visible = false
	world_panel.visible = false
	new_game_button.grab_focus()


func _rebuild_world_list() -> void:
	world_item_list.clear()
	_selected_world_id = ""
	_selected_trash_id = ""
	var entries := _trash_worlds if _showing_trash else _active_worlds
	for entry in entries:
		var status := String(entry.get("status", "状态未知"))
		var display_name := String(entry.get("display_name", "未命名世界"))
		world_item_list.add_item("%s  ·  %s" % [display_name, status])
		var item_index := world_item_list.item_count - 1
		world_item_list.set_item_metadata(item_index, entry)
		if not bool(entry.get("loadable", false)) and not _showing_trash:
			world_item_list.set_item_custom_fg_color(item_index, MUTED_COLOR)
	world_title_label.text = "回收区" if _showing_trash else "本地世界"
	world_count_label.text = "%d / %d 个世界 · 回收区 %d 项" % [
		_active_worlds.size(),
		SliceSaveCatalog.MAX_WORLDS,
		_trash_worlds.size(),
	]
	active_worlds_button.disabled = not _showing_trash
	trash_worlds_button.disabled = _showing_trash
	create_world_button.visible = not _showing_trash
	load_world_button.visible = not _showing_trash
	rename_world_button.visible = not _showing_trash
	trash_world_button.visible = not _showing_trash
	restore_world_button.visible = _showing_trash
	create_world_button.disabled = (
		_showing_trash
		or _active_worlds.size() >= SliceSaveCatalog.MAX_WORLDS
	)
	world_name_input.editable = not _showing_trash
	world_name_input.placeholder_text = (
		"世界名称（最多 40 字）"
		if not _showing_trash
		else "回收项恢复后可重命名"
	)
	world_details_label.text = (
		"回收区为空。"
		if _showing_trash and entries.is_empty()
		else "尚未建立世界。输入名称创建第一个前哨。"
		if entries.is_empty()
		else "选择一个条目查看进度与可用操作。"
	)
	world_status_label.text = (
		"世界数量已达到 30 个上限，请先移入回收区。"
		if _active_worlds.size() >= SliceSaveCatalog.MAX_WORLDS
		else ""
	)
	_refresh_world_action_state()


func _refresh_world_action_state() -> void:
	var has_active_selection := not _selected_world_id.is_empty()
	var has_trash_selection := not _selected_trash_id.is_empty()
	var world_limit_reached := (
		_active_worlds.size() >= SliceSaveCatalog.MAX_WORLDS
	)
	create_world_button.disabled = (
		_showing_trash
		or world_limit_reached
		or has_active_selection
	)
	if has_active_selection:
		create_world_button.tooltip_text = (
			"已选择已有世界；请载入、重命名或移入回收区。"
		)
	elif world_limit_reached:
		create_world_button.tooltip_text = "世界数量已达到 30 个上限。"
	else:
		create_world_button.tooltip_text = "使用输入的名称创建并进入新世界。"
	load_world_button.disabled = true
	rename_world_button.disabled = not has_active_selection
	trash_world_button.disabled = not has_active_selection
	restore_world_button.disabled = not has_trash_selection
	if not has_active_selection:
		return
	var summary := _selected_summary()
	load_world_button.disabled = not bool(summary.get("loadable", false))


func _selected_summary() -> Dictionary:
	var selected := world_item_list.get_selected_items()
	if selected.is_empty():
		return {}
	var metadata = world_item_list.get_item_metadata(selected[0])
	return metadata if metadata is Dictionary else {}


func _show_selected_summary(summary: Dictionary) -> void:
	if summary.is_empty():
		return
	var display_name := String(summary.get("display_name", "未命名世界"))
	var status := String(summary.get("status", "状态未知"))
	var updated_at := String(summary.get("updated_at", ""))
	if updated_at.is_empty():
		updated_at = "尚无更新时间"
	world_details_label.text = "%s\n%s · %s\n%s" % [
		display_name,
		status,
		updated_at,
		_world_progress_text(summary),
	]
	world_name_input.text = display_name if not _showing_trash else ""


func _world_progress_text(summary: Dictionary) -> String:
	return "核心：%s · 外勤：%s · 建筑：%d · 催化剂：%d" % [
		"已恢复" if bool(summary.get("core_repaired", false)) else "待恢复",
		_encounter_progress_text(
			String(summary.get("field_encounter_state", "locked"))
		),
		int(summary.get("building_count", 0)),
		int(summary.get("catalyst_count", 0)),
	]


func _encounter_progress_text(encounter_state: String) -> String:
	match encounter_state:
		"hostile":
			return "交战中"
		"dropped":
			return "样本待拾取"
		"carried":
			return "样本待交付"
		"delivered":
			return "内衬已安装"
		_:
			return "未充能"


func _apply_text_style() -> void:
	for label in [
		title_label,
		subtitle_label,
		slot_summary_label,
		settings_title_label,
		settings_body_label,
		world_title_label,
		world_count_label,
		world_details_label,
		world_status_label,
		trash_confirm_label,
	]:
		if label == null:
			continue
		label.add_theme_color_override("font_color", PRIMARY_COLOR)
		label.add_theme_font_size_override("font_size", 18)
	title_label.add_theme_font_size_override("font_size", 54)
	subtitle_label.add_theme_color_override("font_color", ACCENT_COLOR)
	slot_summary_label.add_theme_color_override("font_color", MUTED_COLOR)
	settings_body_label.add_theme_color_override("font_color", MUTED_COLOR)
	world_count_label.add_theme_color_override("font_color", MUTED_COLOR)
	world_details_label.add_theme_color_override("font_color", MUTED_COLOR)
	world_status_label.add_theme_color_override("font_color", ACCENT_COLOR)


func _apply_button_style() -> void:
	for button in [
		new_game_button,
		load_game_button,
		multiplayer_button,
		settings_button,
		quit_button,
		settings_back_button,
		active_worlds_button,
		trash_worlds_button,
		create_world_button,
		load_world_button,
		rename_world_button,
		trash_world_button,
		restore_world_button,
		world_back_button,
		trash_confirm_button,
		trash_cancel_button,
	]:
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
	if world_panel != null:
		world_panel.color = PANEL_COLOR
	if trash_confirm_panel != null:
		trash_confirm_panel.color = Color(0.025, 0.055, 0.055, 0.98)


func _apply_world_control_style() -> void:
	world_item_list.add_theme_font_size_override("font_size", 18)
	world_item_list.add_theme_color_override("font_color", MUTED_COLOR)
	world_item_list.add_theme_color_override("font_selected_color", PRIMARY_COLOR)
	world_item_list.add_theme_stylebox_override(
		"panel",
		_make_field_style(
			Color(0.016, 0.03, 0.032, 0.96),
			Color(0.18, 0.34, 0.32, 0.9)
		)
	)
	world_item_list.add_theme_stylebox_override(
		"focus",
		_make_field_style(Color.TRANSPARENT, ACCENT_COLOR)
	)
	var selected_style := _make_field_style(
		Color(0.055, 0.14, 0.13, 0.98),
		Color(0.42, 0.82, 0.72, 0.98)
	)
	world_item_list.add_theme_stylebox_override("selected", selected_style)
	world_item_list.add_theme_stylebox_override(
		"selected_focus",
		selected_style
	)
	world_name_input.add_theme_font_size_override("font_size", 18)
	world_name_input.add_theme_color_override("font_color", PRIMARY_COLOR)
	world_name_input.add_theme_color_override(
		"font_placeholder_color",
		MUTED_COLOR
	)
	world_name_input.add_theme_stylebox_override(
		"normal",
		_make_field_style(
			Color(0.016, 0.03, 0.032, 0.96),
			Color(0.18, 0.34, 0.32, 0.9)
		)
	)
	world_name_input.add_theme_stylebox_override(
		"focus",
		_make_field_style(
			Color(0.025, 0.065, 0.062, 0.98),
			Color(0.42, 0.82, 0.72, 0.98)
		)
	)


func _make_field_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


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
	_open_world_panel(false, true)


func _on_load_game_pressed() -> void:
	if not has_loadable_save:
		return
	_open_world_panel(false)


func _on_active_worlds_pressed() -> void:
	_showing_trash = false
	_rebuild_world_list()
	world_item_list.grab_focus()


func _on_trash_worlds_pressed() -> void:
	_showing_trash = true
	_rebuild_world_list()
	world_item_list.grab_focus()


func _on_world_item_selected(index: int) -> void:
	var metadata = world_item_list.get_item_metadata(index)
	if not (metadata is Dictionary):
		return
	var summary: Dictionary = metadata
	_selected_world_id = (
		"" if _showing_trash else String(summary.get("world_id", ""))
	)
	_selected_trash_id = (
		String(summary.get("trash_id", "")) if _showing_trash else ""
	)
	_show_selected_summary(summary)
	_refresh_world_action_state()


func _on_world_item_activated(_index: int) -> void:
	if _showing_trash:
		_on_restore_world_pressed()
	else:
		_on_load_world_pressed()


func _on_create_world_pressed() -> void:
	if save_catalog == null or create_world_button.disabled:
		return
	var result := save_catalog.create_world(world_name_input.text)
	if not bool(result.get("success", false)):
		show_catalog_message(String(result.get("message", "创建世界失败。")))
		return
	var data: Dictionary = result["data"]
	world_created.emit(String(data.get("world_id", "")))


func _on_load_world_pressed() -> void:
	if _selected_world_id.is_empty():
		return
	var summary := _selected_summary()
	if not bool(summary.get("loadable", false)):
		show_catalog_message("该世界当前不可读取。")
		return
	world_load_requested.emit(_selected_world_id)


func _on_rename_world_pressed() -> void:
	if save_catalog == null or _selected_world_id.is_empty():
		return
	var result := save_catalog.rename_world(
		_selected_world_id,
		world_name_input.text
	)
	if not bool(result.get("success", false)):
		show_catalog_message(String(result.get("message", "重命名失败。")))
		return
	_refresh_worlds()
	show_catalog_message("世界已重命名。")


func _on_trash_world_pressed() -> void:
	if _selected_world_id.is_empty():
		return
	var summary := _selected_summary()
	trash_confirm_label.text = "将“%s”移入回收区？\n可稍后恢复，不会永久删除。" % String(
		summary.get("display_name", "未命名世界")
	)
	trash_confirm_panel.visible = true
	trash_cancel_button.grab_focus()


func _on_trash_confirmed() -> void:
	if save_catalog == null or _selected_world_id.is_empty():
		return
	var result := save_catalog.move_world_to_trash(_selected_world_id)
	_close_trash_confirmation()
	if not bool(result.get("success", false)):
		show_catalog_message(String(result.get("message", "移入回收区失败。")))
		return
	_refresh_worlds()
	show_catalog_message("世界已移入回收区，可随时恢复。")


func _close_trash_confirmation() -> void:
	trash_confirm_panel.visible = false
	trash_world_button.grab_focus()


func _on_restore_world_pressed() -> void:
	if save_catalog == null or _selected_trash_id.is_empty():
		return
	var result := save_catalog.restore_world(_selected_trash_id)
	if not bool(result.get("success", false)):
		show_catalog_message(String(result.get("message", "恢复世界失败。")))
		return
	_refresh_worlds()
	show_catalog_message("世界已恢复到本地世界列表。")


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if trash_confirm_panel.visible:
		_close_trash_confirmation()
		get_viewport().set_input_as_handled()
		return
	if world_panel.visible:
		_close_world_panel()
		get_viewport().set_input_as_handled()
		return
	if settings_panel.visible:
		_on_settings_back_pressed()
		get_viewport().set_input_as_handled()


func _on_settings_pressed() -> void:
	settings_panel.visible = true
	settings_back_button.grab_focus()


func _on_settings_back_pressed() -> void:
	settings_panel.visible = false
	settings_button.grab_focus()


func _on_quit_pressed() -> void:
	quit_requested.emit()
