extends Control
class_name StartupMenu

const COLOR_TEXT := Color(0.863, 0.886, 0.878, 1.0)
const COLOR_MUTED := Color(0.537, 0.576, 0.588, 1.0)
const COLOR_A1 := Color(0.498, 0.573, 0.722, 1.0)
const COLOR_DANGER := Color(0.82, 0.31, 0.29, 1.0)
const COLOR_DARK_TEXT := Color(0.11, 0.145, 0.16, 1.0)
const SYSTEM_SURFACE_STYLE := preload(
	"res://assets/themes/slice_ui_system_surface.tres"
)
const SYSTEM_PRIMARY_STYLE := preload(
	"res://assets/themes/slice_ui_system_primary_action.tres"
)
const SYSTEM_DANGER_STYLE := preload(
	"res://assets/themes/slice_ui_system_danger_action.tres"
)

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
@onready var system_shade: ColorRect = $SystemShade
@onready var settings_panel: SliceSettingsPanel = $SettingsPanel
@onready var settings_back_button: Button = (
	$SettingsPanel/Margin/Layout/Footer/BackButton
)
@onready var world_panel: Panel = $WorldPanel
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
@onready var trash_confirm_panel: Panel = $WorldPanel/TrashConfirmPanel
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
	settings_panel.close_requested.connect(_on_settings_back_pressed)
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
	settings_panel.setup(_user_settings())
	world_panel.visible = false
	trash_confirm_panel.visible = false
	system_shade.visible = false
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
	settings_panel.close()
	system_shade.visible = true
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
	system_shade.visible = false
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
		if _is_unreadable_summary(entry):
			world_item_list.set_item_custom_fg_color(item_index, COLOR_DANGER)
		elif not bool(entry.get("loadable", false)) and not _showing_trash:
			world_item_list.set_item_custom_fg_color(item_index, COLOR_MUTED)
	world_title_label.text = "回收区" if _showing_trash else "本地世界"
	world_count_label.text = "%d / %d 个世界 · 回收区 %d 项" % [
		_active_worlds.size(),
		SliceSaveCatalog.MAX_WORLDS,
		_trash_worlds.size(),
	]
	active_worlds_button.disabled = not _showing_trash
	trash_worlds_button.disabled = _showing_trash
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
	_apply_world_tab_styles()
	_refresh_world_action_state()


func _refresh_world_action_state() -> void:
	var has_active_selection := not _selected_world_id.is_empty()
	var has_trash_selection := not _selected_trash_id.is_empty()
	var summary := _selected_summary()
	var selection_is_unreadable := _is_unreadable_summary(summary)
	var world_limit_reached := (
		_active_worlds.size() >= SliceSaveCatalog.MAX_WORLDS
	)
	create_world_button.visible = not _showing_trash and not has_active_selection
	load_world_button.visible = not _showing_trash and has_active_selection
	rename_world_button.visible = not _showing_trash and has_active_selection
	trash_world_button.visible = not _showing_trash and has_active_selection
	restore_world_button.visible = _showing_trash
	world_name_input.editable = (
		not _showing_trash
		and (not has_active_selection or not selection_is_unreadable)
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
	load_world_button.disabled = (
		not has_active_selection
		or not bool(summary.get("loadable", false))
	)
	rename_world_button.disabled = (
		not has_active_selection
		or selection_is_unreadable
	)
	trash_world_button.disabled = not has_active_selection
	restore_world_button.disabled = (
		not has_trash_selection
		or selection_is_unreadable
	)


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
	if _is_unreadable_summary(summary):
		world_details_label.text = (
			"%s\n危险状态 · %s\n更新时间 / 进度：无法验证\n"
			+ "原始目录保留，可移入回收区隔离。\n无法从游戏内恢复。"
		) % [display_name, status]
		world_details_label.add_theme_color_override(
			"font_color", COLOR_DANGER
		)
		world_name_input.text = ""
		return
	var updated_at := String(summary.get("updated_at", ""))
	if updated_at.is_empty():
		updated_at = "尚无更新时间"
	world_details_label.text = "%s\n%s · %s\n%s" % [
		display_name,
		status,
		updated_at,
		_world_progress_text(summary),
	]
	world_details_label.add_theme_color_override("font_color", COLOR_MUTED)
	world_name_input.text = display_name if not _showing_trash else ""


func _is_unreadable_summary(summary: Dictionary) -> bool:
	if summary.is_empty():
		return false
	var status := String(summary.get("status", ""))
	return (
		status == "元数据损坏"
		or status == "世界 ID 不一致"
		or not String(summary.get("error", "")).is_empty()
	)


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
		world_title_label,
		world_count_label,
		world_details_label,
		world_status_label,
		trash_confirm_label,
	]:
		if label == null:
			continue
		label.add_theme_color_override("font_color", COLOR_TEXT)
		label.add_theme_font_size_override("font_size", 18)
	title_label.add_theme_font_size_override("font_size", 52)
	subtitle_label.add_theme_color_override("font_color", COLOR_A1)
	slot_summary_label.add_theme_color_override("font_color", COLOR_MUTED)
	world_count_label.add_theme_color_override("font_color", COLOR_MUTED)
	world_details_label.add_theme_color_override("font_color", COLOR_MUTED)
	world_status_label.add_theme_color_override("font_color", COLOR_MUTED)


func _apply_button_style() -> void:
	for button in [
		new_game_button,
		load_game_button,
		multiplayer_button,
		settings_button,
		quit_button,
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
		button.add_theme_color_override("font_color", COLOR_TEXT)
		button.add_theme_color_override("font_disabled_color", COLOR_MUTED)
		button.add_theme_font_size_override("font_size", 20)
	for button in [
		new_game_button,
		create_world_button,
		load_world_button,
		restore_world_button,
		trash_cancel_button,
	]:
		button.add_theme_color_override("font_color", COLOR_DARK_TEXT)
		button.add_theme_stylebox_override("normal", SYSTEM_PRIMARY_STYLE)
	for button in [trash_world_button, trash_confirm_button, quit_button]:
		button.add_theme_color_override("font_color", COLOR_TEXT)
		button.add_theme_stylebox_override("normal", SYSTEM_DANGER_STYLE)


func _apply_world_control_style() -> void:
	world_item_list.add_theme_font_size_override("font_size", 18)
	world_item_list.add_theme_color_override("font_color", COLOR_MUTED)
	world_item_list.add_theme_color_override("font_selected_color", COLOR_TEXT)
	world_item_list.add_theme_stylebox_override(
		"panel",
		SYSTEM_SURFACE_STYLE
	)
	world_item_list.add_theme_stylebox_override(
		"focus",
		_make_field_style(Color.TRANSPARENT, COLOR_A1)
	)
	var selected_style := _make_field_style(
		Color(0.12, 0.16, 0.19, 1.0),
		COLOR_A1
	)
	world_item_list.add_theme_stylebox_override("selected", selected_style)
	world_item_list.add_theme_stylebox_override(
		"selected_focus",
		selected_style
	)
	world_name_input.add_theme_font_size_override("font_size", 18)
	world_name_input.add_theme_color_override("font_color", COLOR_TEXT)
	world_name_input.add_theme_color_override(
		"font_placeholder_color",
		COLOR_MUTED
	)
	world_name_input.add_theme_stylebox_override(
		"normal",
		SYSTEM_SURFACE_STYLE
	)
	world_name_input.add_theme_stylebox_override(
		"focus",
		_make_field_style(
			Color(0.11, 0.145, 0.16, 1.0),
			COLOR_A1
		)
	)


func _apply_world_tab_styles() -> void:
	var active_button := (
		trash_worlds_button if _showing_trash else active_worlds_button
	)
	var inactive_button := (
		active_worlds_button if _showing_trash else trash_worlds_button
	)
	var active_style := SYSTEM_SURFACE_STYLE.duplicate() as StyleBoxFlat
	active_style.border_width_bottom = 3
	active_style.border_color = COLOR_A1
	active_button.add_theme_color_override("font_disabled_color", COLOR_TEXT)
	active_button.add_theme_stylebox_override("disabled", active_style)
	inactive_button.remove_theme_stylebox_override("disabled")
	inactive_button.remove_theme_color_override("font_disabled_color")


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
	var display_name := String(summary.get("display_name", "未命名世界"))
	if _is_unreadable_summary(summary):
		trash_confirm_label.text = (
			"隔离“%s”到回收区？\n原始目录不会永久删除，"
			+ "但元数据损坏项无法从游戏内恢复。"
		) % display_name
	else:
		trash_confirm_label.text = (
			"将“%s”移入回收区？\n可稍后恢复，不会永久删除。"
		) % display_name
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
	if settings_panel.is_open():
		_on_settings_back_pressed()
		get_viewport().set_input_as_handled()


func _on_settings_pressed() -> void:
	system_shade.visible = true
	settings_panel.open()


func _on_settings_back_pressed() -> void:
	settings_panel.close()
	system_shade.visible = false
	settings_button.grab_focus()


func _user_settings() -> SliceUserSettings:
	return get_node_or_null("/root/UserSettings") as SliceUserSettings


func _on_quit_pressed() -> void:
	quit_requested.emit()
