class_name SliceSaveScheduler
extends RefCounted

## Coalesces high-frequency slice mutations and owns the decision of when a
## durable snapshot is published. SliceWorld remains the only state authority;
## SliceSaveService remains the only validator and file publisher.

const DEFAULT_DEBOUNCE_SECONDS := 2.0

var debounce_seconds := DEFAULT_DEBOUNCE_SECONDS
var _save_service
var _dirty := false
var _elapsed := 0.0
var _write_blocked := false
var _pending_load_context: Dictionary = {}
var _last_error_message := ""


func setup(save_service, delay_seconds: float = DEFAULT_DEBOUNCE_SECONDS) -> void:
	_save_service = save_service
	debounce_seconds = maxf(0.0, delay_seconds)


func request_save() -> bool:
	if _write_blocked:
		return false
	if not _dirty:
		_elapsed = 0.0
	_dirty = true
	return true


func advance(delta: float, state_factory: Callable) -> Dictionary:
	if not _dirty:
		return _not_attempted_result()
	_elapsed += maxf(0.0, delta)
	if _elapsed < debounce_seconds:
		return _not_attempted_result()
	return flush(state_factory)


func flush(state_factory: Callable) -> Dictionary:
	_dirty = true
	if _write_blocked:
		return _failed_result("载入世界未完整重建，已阻止写盘。")
	if _save_service == null:
		return _failed_result("保存调度器尚未配置保存服务。")
	if not state_factory.is_valid():
		return _failed_result("保存调度器缺少有效的状态构造回调。")

	var state = state_factory.call()
	if not state is Dictionary:
		return _failed_result("保存状态构造回调没有返回 Dictionary。")
	var result: Dictionary
	if not _pending_load_context.is_empty():
		result = _save_service.commit_loaded_state(
			state, _pending_load_context
		)
	else:
		result = _save_service.save_state(state)
	result = result.duplicate(true)
	result["attempted"] = true
	if bool(result.get("success", false)):
		_dirty = false
		_elapsed = 0.0
		_pending_load_context = {}
		_last_error_message = ""
		return result

	_elapsed = 0.0
	_last_error_message = String(
		result.get("message", "保存服务返回失败。")
	)
	return result


func set_pending_load_context(context: Dictionary) -> void:
	_pending_load_context = context.duplicate(true)


func set_write_blocked(blocked: bool) -> void:
	_write_blocked = blocked


func is_dirty() -> bool:
	return _dirty


func pending_load_context() -> Dictionary:
	return _pending_load_context.duplicate(true)


func last_error_message() -> String:
	return _last_error_message


func _not_attempted_result() -> Dictionary:
	return {
		"attempted": false,
		"success": false,
		"message": "",
	}


func _failed_result(message: String) -> Dictionary:
	_elapsed = 0.0
	_last_error_message = message
	return {
		"attempted": true,
		"success": false,
		"message": message,
	}
