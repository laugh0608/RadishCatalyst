class_name SlicePauseMenu
extends CanvasLayer

const COLOR_TEXT := Color(0.863, 0.886, 0.878, 1.0)
const COLOR_MUTED := Color(0.537, 0.576, 0.588, 1.0)
const COLOR_DANGER := Color(0.82, 0.31, 0.29, 1.0)
const COLOR_DARK_TEXT := Color(0.11, 0.145, 0.16, 1.0)
const SYSTEM_PRIMARY_STYLE := preload(
	"res://assets/themes/slice_ui_system_primary_action.tres"
)
const SYSTEM_DANGER_STYLE := preload(
	"res://assets/themes/slice_ui_system_danger_action.tres"
)

var _open := false
var _pending_action := ""

@onready var root_control: Control = $Root
@onready var title_label: Label = $Root/PauseBox/TitleLabel
@onready var body_label: Label = $Root/PauseBox/BodyLabel
@onready var status_label: Label = $Root/PauseBox/StatusLabel
@onready var resume_button: Button = $Root/PauseBox/Buttons/ResumeButton
@onready var settings_button: Button = $Root/PauseBox/Buttons/SettingsButton
@onready var return_button: Button = $Root/PauseBox/Buttons/ReturnButton
@onready var quit_button: Button = $Root/PauseBox/Buttons/QuitButton
@onready var settings_panel: Panel = $Root/SettingsPanel
@onready var settings_back_button: Button = $Root/SettingsPanel/BackButton
@onready var confirm_panel: Panel = $Root/ConfirmPanel
@onready var confirm_label: Label = $Root/ConfirmPanel/ConfirmLabel
@onready var confirm_button: Button = $Root/ConfirmPanel/ConfirmButton
@onready var confirm_cancel_button: Button = $Root/ConfirmPanel/CancelButton

signal save_and_return_requested
signal save_and_quit_requested


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	root_control.visible = false
	settings_panel.visible = false
	confirm_panel.visible = false
	resume_button.pressed.connect(close)
	settings_button.pressed.connect(_open_settings)
	return_button.pressed.connect(_request_return)
	quit_button.pressed.connect(_request_quit)
	settings_back_button.pressed.connect(_close_settings)
	confirm_button.pressed.connect(_confirm_pending_action)
	confirm_cancel_button.pressed.connect(_close_confirmation)
	_apply_style()


func open() -> void:
	if _open:
		return
	_open = true
	_pending_action = ""
	status_label.text = ""
	settings_panel.visible = false
	confirm_panel.visible = false
	root_control.visible = true
	get_tree().paused = true
	resume_button.grab_focus()


func close() -> void:
	if not _open:
		return
	_open = false
	_pending_action = ""
	settings_panel.visible = false
	confirm_panel.visible = false
	root_control.visible = false
	get_tree().paused = false


func release_for_transition() -> void:
	close()


func is_open() -> bool:
	return _open


func show_save_error(message: String) -> void:
	status_label.text = message
	confirm_panel.visible = false
	_pending_action = ""
	return_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if not _open or not event.is_action_pressed("ui_cancel"):
		return
	if confirm_panel.visible:
		_close_confirmation()
	elif settings_panel.visible:
		_close_settings()
	else:
		close()
	get_viewport().set_input_as_handled()


func _open_settings() -> void:
	settings_panel.visible = true
	settings_back_button.grab_focus()


func _close_settings() -> void:
	settings_panel.visible = false
	settings_button.grab_focus()


func _request_return() -> void:
	_pending_action = "return"
	confirm_label.text = (
		"保存当前世界并返回主菜单？\n"
		+ "只有保存成功后才会离开，可从世界列表重新载入。"
	)
	confirm_panel.visible = true
	confirm_cancel_button.grab_focus()


func _request_quit() -> void:
	_pending_action = "quit"
	confirm_label.text = (
		"保存当前世界并退出游戏？\n只有保存成功后才会离开。"
	)
	confirm_panel.visible = true
	confirm_cancel_button.grab_focus()


func _close_confirmation() -> void:
	confirm_panel.visible = false
	_pending_action = ""
	return_button.grab_focus()


func _confirm_pending_action() -> void:
	match _pending_action:
		"return":
			save_and_return_requested.emit()
		"quit":
			save_and_quit_requested.emit()


func _apply_style() -> void:
	for label in [
		title_label,
		body_label,
		status_label,
		$Root/SettingsPanel/TitleLabel,
		$Root/SettingsPanel/BodyLabel,
		confirm_label,
	]:
		label.add_theme_color_override("font_color", COLOR_TEXT)
		label.add_theme_font_size_override("font_size", 20)
	title_label.add_theme_font_size_override("font_size", 38)
	body_label.add_theme_color_override("font_color", COLOR_MUTED)
	status_label.add_theme_color_override("font_color", COLOR_DANGER)
	$Root/SettingsPanel/BodyLabel.add_theme_color_override(
		"font_color",
		COLOR_MUTED
	)
	for button in [
		resume_button,
		settings_button,
		return_button,
		quit_button,
		settings_back_button,
		confirm_button,
		confirm_cancel_button,
	]:
		button.add_theme_color_override("font_color", COLOR_TEXT)
		button.add_theme_font_size_override("font_size", 20)
	resume_button.add_theme_color_override("font_color", COLOR_DARK_TEXT)
	resume_button.add_theme_stylebox_override("normal", SYSTEM_PRIMARY_STYLE)
	confirm_cancel_button.add_theme_color_override("font_color", COLOR_DARK_TEXT)
	confirm_cancel_button.add_theme_stylebox_override(
		"normal", SYSTEM_PRIMARY_STYLE
	)
	confirm_button.add_theme_stylebox_override("normal", SYSTEM_DANGER_STYLE)
	return_button.add_theme_color_override("font_color", COLOR_DANGER)
	quit_button.add_theme_color_override("font_color", COLOR_DANGER)
