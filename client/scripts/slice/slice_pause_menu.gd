class_name SlicePauseMenu
extends CanvasLayer

const PRIMARY_COLOR := Color(0.82, 0.96, 0.88, 1.0)
const MUTED_COLOR := Color(0.52, 0.66, 0.62, 1.0)
const ACCENT_COLOR := Color(0.96, 0.72, 0.28, 1.0)
const BUTTON_COLOR := Color(0.045, 0.1, 0.1, 0.96)
const BUTTON_HOVER_COLOR := Color(0.07, 0.16, 0.15, 0.98)

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
@onready var settings_panel: ColorRect = $Root/SettingsPanel
@onready var settings_back_button: Button = $Root/SettingsPanel/BackButton
@onready var confirm_panel: ColorRect = $Root/ConfirmPanel
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
	confirm_label.text = "保存当前世界并返回主菜单？\n完成后可从世界列表重新载入。"
	confirm_panel.visible = true
	confirm_cancel_button.grab_focus()


func _request_quit() -> void:
	_pending_action = "quit"
	confirm_label.text = "保存当前世界并退出游戏？"
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
		label.add_theme_color_override("font_color", PRIMARY_COLOR)
		label.add_theme_font_size_override("font_size", 20)
	title_label.add_theme_font_size_override("font_size", 38)
	body_label.add_theme_color_override("font_color", MUTED_COLOR)
	status_label.add_theme_color_override("font_color", ACCENT_COLOR)
	$Root/SettingsPanel/BodyLabel.add_theme_color_override(
		"font_color",
		MUTED_COLOR
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
		button.add_theme_color_override("font_color", PRIMARY_COLOR)
		button.add_theme_font_size_override("font_size", 20)
		button.add_theme_stylebox_override(
			"normal",
			_make_button_style(
				BUTTON_COLOR,
				Color(0.26, 0.52, 0.48, 0.9)
			)
		)
		button.add_theme_stylebox_override(
			"hover",
			_make_button_style(
				BUTTON_HOVER_COLOR,
				Color(0.55, 0.88, 0.76, 0.98)
			)
		)
		button.add_theme_stylebox_override(
			"pressed",
			_make_button_style(
				Color(0.03, 0.08, 0.08, 0.98),
				ACCENT_COLOR
			)
		)
		button.add_theme_stylebox_override(
			"focus",
			_make_button_style(Color.TRANSPARENT, ACCENT_COLOR)
		)


func _make_button_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style
