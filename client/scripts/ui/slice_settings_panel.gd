class_name SliceSettingsPanel
extends Panel

## Shared startup / pause settings surface. Sliders preview immediately and
## debounce disk persistence so dragging does not create a write per step.

signal close_requested

const COLOR_TEXT := Color(0.863, 0.886, 0.878, 1.0)
const COLOR_MUTED := Color(0.776, 0.812, 0.804, 1.0)
const COLOR_SUCCESS := Color(0.498, 0.573, 0.722, 1.0)
const COLOR_DANGER := Color(0.82, 0.31, 0.29, 1.0)
const PREVIEW_MIX_RATE := 22050
const PREVIEW_DURATION_SECONDS := 0.14

var _settings: SliceUserSettings
var _syncing := false
var _audio_save_pending := false

@onready var _title: Label = $Margin/Layout/Title
@onready var _summary: Label = $Margin/Layout/Summary
@onready var _fullscreen_toggle: CheckButton = (
	$Margin/Layout/WindowRow/FullscreenToggle
)
@onready var _master_slider: HSlider = (
	$Margin/Layout/MasterRow/MasterSlider
)
@onready var _master_value: Label = $Margin/Layout/MasterRow/MasterValue
@onready var _sfx_slider: HSlider = $Margin/Layout/SfxRow/SfxSlider
@onready var _sfx_value: Label = $Margin/Layout/SfxRow/SfxValue
@onready var _controls: Label = $Margin/Layout/Controls
@onready var _preview_button: Button = (
	$Margin/Layout/PreviewRow/PreviewButton
)
@onready var _status: Label = $Margin/Layout/Status
@onready var _back_button: Button = $Margin/Layout/Footer/BackButton
@onready var _save_timer: Timer = $SaveTimer
@onready var _preview_player: AudioStreamPlayer = $PreviewPlayer


func _ready() -> void:
	visible = false
	_fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	_master_slider.value_changed.connect(_on_master_value_changed)
	_sfx_slider.value_changed.connect(_on_sfx_value_changed)
	_preview_button.pressed.connect(_play_preview)
	_save_timer.timeout.connect(_flush_audio_settings)
	_back_button.pressed.connect(func(): close_requested.emit())
	_apply_style()


func setup(settings: SliceUserSettings) -> void:
	_settings = settings
	if _settings == null:
		_set_controls_enabled(false)
		_show_status("用户设置服务不可用。", true)
		return
	if not _settings.changed.is_connected(_on_settings_changed):
		_settings.changed.connect(_on_settings_changed)
	if not _settings.persistence_failed.is_connected(_on_persistence_failed):
		_settings.persistence_failed.connect(_on_persistence_failed)
	_set_controls_enabled(true)
	_sync_from_settings()


func open() -> void:
	visible = true
	_sync_from_settings()
	_fullscreen_toggle.grab_focus()


func close() -> void:
	_flush_audio_settings()
	visible = false


func is_open() -> bool:
	return visible


func back_button() -> Button:
	return _back_button


func settings_snapshot() -> Dictionary:
	return {} if _settings == null else _settings.snapshot()


func _on_fullscreen_toggled(enabled: bool) -> void:
	if _syncing or _settings == null:
		return
	_show_save_result(_settings.set_fullscreen(enabled))


func _on_master_value_changed(value: float) -> void:
	_master_value.text = "%d%%" % roundi(value)
	if _syncing or _settings == null:
		return
	_settings.set_master_volume_percent(roundi(value), false)
	_audio_save_pending = true
	_save_timer.start()


func _on_sfx_value_changed(value: float) -> void:
	_sfx_value.text = "%d%%" % roundi(value)
	if _syncing or _settings == null:
		return
	_settings.set_sfx_volume_percent(roundi(value), false)
	_audio_save_pending = true
	_save_timer.start()


func _play_preview() -> void:
	if _preview_player.stream == null:
		_preview_player.stream = _build_preview_stream()
	_preview_player.play()
	_show_status("试听音效通过 SFX 总线播放。", false)


func _flush_audio_settings() -> void:
	if _settings == null or not _audio_save_pending:
		return
	_audio_save_pending = false
	_save_timer.stop()
	_show_save_result(_settings.save_settings())


func _on_settings_changed(_snapshot: Dictionary) -> void:
	_sync_from_settings()


func _on_persistence_failed(message: String) -> void:
	_show_status(message, true)


func _sync_from_settings() -> void:
	if _settings == null:
		return
	_syncing = true
	_fullscreen_toggle.button_pressed = _settings.fullscreen
	_master_slider.value = _settings.master_volume_percent
	_sfx_slider.value = _settings.sfx_volume_percent
	_master_value.text = "%d%%" % _settings.master_volume_percent
	_sfx_value.text = "%d%%" % _settings.sfx_volume_percent
	_syncing = false


func _show_save_result(succeeded: bool) -> void:
	if succeeded:
		_show_status("设置已保存，独立于当前世界存档。", false)


func _show_status(message: String, danger: bool) -> void:
	_status.text = message
	_status.add_theme_color_override(
		"font_color", COLOR_DANGER if danger else COLOR_SUCCESS
	)


func _set_controls_enabled(enabled: bool) -> void:
	_fullscreen_toggle.disabled = not enabled
	_master_slider.editable = enabled
	_sfx_slider.editable = enabled
	_preview_button.disabled = not enabled


func _build_preview_stream() -> AudioStreamWAV:
	var sample_count := roundi(
		PREVIEW_MIX_RATE * PREVIEW_DURATION_SECONDS
	)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for index in range(sample_count):
		var progress := float(index) / float(sample_count - 1)
		var time_seconds := float(index) / float(PREVIEW_MIX_RATE)
		var envelope := sin(PI * progress)
		var carrier := sin(TAU * 660.0 * time_seconds)
		var overtone := sin(TAU * 990.0 * time_seconds) * 0.28
		var sample := clampi(
			roundi((carrier + overtone) * envelope * 0.22 * 32767.0),
			-32768,
			32767
		)
		data[index * 2] = sample & 0xff
		data[index * 2 + 1] = (sample >> 8) & 0xff
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = PREVIEW_MIX_RATE
	stream.stereo = false
	stream.data = data
	return stream


func _apply_style() -> void:
	for label in [
		_title,
		_summary,
		$Margin/Layout/WindowRow/WindowLabel,
		$Margin/Layout/MasterRow/MasterLabel,
		$Margin/Layout/SfxRow/SfxLabel,
		$Margin/Layout/PreviewRow/PreviewLabel,
		$Margin/Layout/ControlsTitle,
		_controls,
		_master_value,
		_sfx_value,
		_status,
	]:
		label.add_theme_color_override("font_color", COLOR_TEXT)
		label.add_theme_font_size_override("font_size", 18)
	_title.add_theme_font_size_override("font_size", 32)
	_summary.add_theme_color_override("font_color", COLOR_MUTED)
	$Margin/Layout/PreviewRow/PreviewLabel.add_theme_color_override(
		"font_color", COLOR_MUTED
	)
	_controls.add_theme_color_override("font_color", COLOR_MUTED)
	_preview_button.add_theme_font_size_override("font_size", 18)
	_back_button.add_theme_font_size_override("font_size", 20)
