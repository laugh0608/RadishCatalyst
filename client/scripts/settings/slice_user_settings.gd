class_name SliceUserSettings
extends Node

## Application-level preferences. This file is deliberately independent from
## every world directory, save backup and gameplay schema.

signal changed(snapshot: Dictionary)
signal persistence_failed(message: String)

const DEFAULT_SETTINGS_PATH := "user://settings.cfg"
const WINDOW_SECTION := "window"
const AUDIO_SECTION := "audio"
const FULLSCREEN_KEY := "fullscreen"
const MASTER_VOLUME_KEY := "master_volume_percent"
const SFX_VOLUME_KEY := "sfx_volume_percent"
const MASTER_BUS := &"Master"
const SFX_BUS := &"SFX"
const MIN_VOLUME_PERCENT := 0
const MAX_VOLUME_PERCENT := 100

var settings_path := DEFAULT_SETTINGS_PATH
var fullscreen := false
var master_volume_percent := MAX_VOLUME_PERCENT
var sfx_volume_percent := MAX_VOLUME_PERCENT


func _ready() -> void:
	load_settings()


func load_settings() -> bool:
	var current_fullscreen := _window_is_fullscreen()
	var config := ConfigFile.new()
	var error := config.load(settings_path)
	if error == ERR_FILE_NOT_FOUND:
		fullscreen = current_fullscreen
		_apply_audio()
		changed.emit(snapshot())
		return true
	if error != OK:
		fullscreen = current_fullscreen
		_apply_audio()
		var message := "用户设置读取失败（%s），已保留安全默认值。" % error_string(error)
		push_warning(message)
		persistence_failed.emit(message)
		changed.emit(snapshot())
		return false

	var raw_fullscreen = config.get_value(
		WINDOW_SECTION, FULLSCREEN_KEY, current_fullscreen
	)
	fullscreen = (
		bool(raw_fullscreen) if raw_fullscreen is bool else current_fullscreen
	)
	master_volume_percent = _validated_percent(
		config.get_value(
			AUDIO_SECTION, MASTER_VOLUME_KEY, MAX_VOLUME_PERCENT
		),
		MAX_VOLUME_PERCENT
	)
	sfx_volume_percent = _validated_percent(
		config.get_value(
			AUDIO_SECTION, SFX_VOLUME_KEY, MAX_VOLUME_PERCENT
		),
		MAX_VOLUME_PERCENT
	)
	_apply_all()
	changed.emit(snapshot())
	return true


func save_settings() -> bool:
	var config := ConfigFile.new()
	config.set_value(WINDOW_SECTION, FULLSCREEN_KEY, fullscreen)
	config.set_value(
		AUDIO_SECTION, MASTER_VOLUME_KEY, master_volume_percent
	)
	config.set_value(AUDIO_SECTION, SFX_VOLUME_KEY, sfx_volume_percent)
	var error := config.save(settings_path)
	if error == OK:
		return true
	var message := "用户设置保存失败（%s），本次调整仅在当前运行有效。" % error_string(error)
	push_warning(message)
	persistence_failed.emit(message)
	return false


func set_fullscreen(enabled: bool, persist: bool = true) -> bool:
	fullscreen = enabled
	_apply_window_mode()
	changed.emit(snapshot())
	return not persist or save_settings()


func set_master_volume_percent(value: int, persist: bool = true) -> bool:
	master_volume_percent = clampi(
		value, MIN_VOLUME_PERCENT, MAX_VOLUME_PERCENT
	)
	_apply_bus_volume(MASTER_BUS, master_volume_percent)
	changed.emit(snapshot())
	return not persist or save_settings()


func set_sfx_volume_percent(value: int, persist: bool = true) -> bool:
	sfx_volume_percent = clampi(
		value, MIN_VOLUME_PERCENT, MAX_VOLUME_PERCENT
	)
	_apply_bus_volume(SFX_BUS, sfx_volume_percent)
	changed.emit(snapshot())
	return not persist or save_settings()


func snapshot() -> Dictionary:
	return {
		"settings_path": settings_path,
		"fullscreen": fullscreen,
		"master_volume_percent": master_volume_percent,
		"sfx_volume_percent": sfx_volume_percent,
	}


func _apply_all() -> void:
	_apply_window_mode()
	_apply_audio()


func _apply_audio() -> void:
	_apply_bus_volume(MASTER_BUS, master_volume_percent)
	_apply_bus_volume(SFX_BUS, sfx_volume_percent)


func _apply_window_mode() -> void:
	var target_mode := (
		DisplayServer.WINDOW_MODE_FULLSCREEN
		if fullscreen
		else DisplayServer.WINDOW_MODE_WINDOWED
	)
	if DisplayServer.window_get_mode() != target_mode:
		DisplayServer.window_set_mode(target_mode)


func _apply_bus_volume(bus_name: StringName, percent: int) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		push_error("Missing required audio bus: %s" % bus_name)
		return
	var muted := percent <= MIN_VOLUME_PERCENT
	AudioServer.set_bus_mute(bus_index, muted)
	AudioServer.set_bus_volume_db(
		bus_index,
		-80.0 if muted else linear_to_db(float(percent) / 100.0)
	)


func _window_is_fullscreen() -> bool:
	return DisplayServer.window_get_mode() in [
		DisplayServer.WINDOW_MODE_FULLSCREEN,
		DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN,
	]


static func _validated_percent(value: Variant, fallback: int) -> int:
	if value is int or value is float:
		return clampi(
			roundi(float(value)), MIN_VOLUME_PERCENT, MAX_VOLUME_PERCENT
		)
	return fallback
