extends SceneTree

var failures: Array[String] = []
var data_registry := DataRegistry.new()


func _init() -> void:
	if not data_registry.load_all():
		failures.append("data registry should load all static data")
	else:
		_run_checks()

	if failures.is_empty():
		print("Demo quick slot supply readability checks passed.")
		_cleanup()
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	_cleanup()
	quit(1)


func _run_checks() -> void:
	_check_default_quick_slot_readability()
	_check_pressure_quick_slot_readability()
	_check_supply_success_updates_readability()
	_check_supply_failure_keeps_recovery_route()


func _check_default_quick_slot_readability() -> void:
	var world := WorldState.create_default()
	var character := CharacterState.create_default()
	var hud_text := HudStatusPresenter.new().format_vitals_text(data_registry, world, character)
	_expect_text_contains(hud_text, "快捷栏：1 修复凝胶x1/满", "default repair gel slot is readable")
	_expect_text_contains(hud_text, "2 抗污染药剂 Ix0/缺:过滤器", "default missing vial names refill device")


func _check_pressure_quick_slot_readability() -> void:
	var world := WorldState.create_default()
	world.current_region_id = "region.pollution_edge"
	var character := CharacterState.create_default()
	character.health = 42.0
	character.protection = 38.0
	character.inventory.add_item("item.resistance_vial_t1", 1)
	var hud_text := HudStatusPresenter.new().format_vitals_text(data_registry, world, character)
	_expect_text_contains(hud_text, "1 修复凝胶x1/生命低可用", "low health marks repair gel as useful")
	_expect_text_contains(hud_text, "2 抗污染药剂 Ix1/防护低可用", "low protection marks resistance vial as useful")


func _check_supply_success_updates_readability() -> void:
	var world := WorldState.create_default()
	var character := CharacterState.create_default()
	character.health = 50.0
	var result := character.use_quick_slot(0, data_registry)
	_expect_equal(bool(result.get("success", false)), true, "repair gel quick slot succeeds when wounded")
	var hud_text := HudStatusPresenter.new().format_vitals_text(data_registry, world, character)
	_expect_text_contains(hud_text, "1 修复凝胶x0/缺:反应器", "used repair gel points back to reactor refill")
	var feedback: Dictionary = result.get("supply_feedback", {})
	_expect_text_contains(String(feedback.get("detail", "")), "剩余 0", "supply feedback shows remaining count")


func _check_supply_failure_keeps_recovery_route() -> void:
	var character := CharacterState.create_default()
	var result := character.use_quick_slot(1, data_registry)
	_expect_equal(bool(result.get("success", false)), false, "missing resistance vial fails cleanly")
	var feedback: Dictionary = result.get("failure_feedback", {})
	_expect_text_contains(String(feedback.get("detail", "")), "污染过滤器", "missing vial routes to pollution filter")
	var log_text := HudLogPresenter.new(data_registry).format_result_log(result)
	_expect_text_contains(log_text, "补给不足", "missing supply log names blocker")
	_expect_text_contains(log_text, "污染过滤器", "missing supply log keeps recovery route")


func _expect_equal(actual, expected, context: String) -> void:
	if actual == expected:
		return
	failures.append("%s: expected %s, got %s" % [context, str(expected), str(actual)])


func _expect_text_contains(text: String, expected: String, context: String) -> void:
	if text.contains(expected):
		return
	failures.append("%s: missing '%s' in '%s'" % [context, expected, text])


func _cleanup() -> void:
	data_registry.free()
