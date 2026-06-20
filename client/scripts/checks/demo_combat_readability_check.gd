extends SceneTree

const PrototypeHudScene := preload("res://scenes/ui/PrototypeHud.tscn")
const VerticalSliceMapScene := preload("res://scenes/maps/VerticalSliceMap.tscn")

var failures: Array[String] = []
var data_registry := DataRegistry.new()


func _init() -> void:
	if not data_registry.load_all():
		failures.append("data registry should load all static data")
	else:
		_run_checks()

	if failures.is_empty():
		print("Demo combat readability checks passed.")
		_cleanup()
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	_cleanup()
	quit(1)


func _run_checks() -> void:
	_check_formatter_exposes_player_enemy_and_supply_state()
	_check_attack_result_carries_combat_feedback()
	_check_hud_panel_uses_current_target_and_recent_feedback()


func _check_formatter_exposes_player_enemy_and_supply_state() -> void:
	var world := WorldState.create_default()
	world.current_region_id = "region.pollution_edge"
	var character := CharacterState.create_default()
	character.health = 58.0
	character.protection = 32.0
	character.inventory.add_item("item.resistance_vial_t1", 1)
	var enemy := _create_enemy("enemy.polluted_skitter", "enemy_instance.polluted_skitter_gate_pressure")
	enemy.set_tactical_scan_marked(true)

	var text := DemoCombatReadabilityFormatter.format_panel_text(data_registry, world, character, enemy)
	_expect_text_contains(text, "自身: 生命 58/100 WARN / SP 32/100 LOW", "panel shows player vitals pressure")
	_expect_text_contains(text, "补给: 1 修复凝胶x1/生命低可用", "panel shows repair gel combat value")
	_expect_text_contains(text, "2 抗污染药剂 Ix1/SP低可用", "panel shows resistance vial combat value")
	_expect_text_contains(text, "目标: HP 30/30 / 中威胁 / 生命 / SP承压", "panel shows enemy hp threat and pressure")
	_expect_text_contains(text, "MODE: SCAN / PRESSURE", "panel shows enemy state")
	_expect_combat_panel_font_safe(text)
	enemy.free()


func _check_attack_result_carries_combat_feedback() -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	get_root().add_child(map)
	map.setup(data_registry)
	var world := WorldState.create_default()
	var character := CharacterState.create_default()
	map.sync_enemy_states(world)
	var enemy := map.get_node("Enemies/NativeSkitter") as PrototypeEnemy
	map.player.position = enemy.position

	var result := map.try_attack(character, world)
	_expect_equal(bool(result.get("success", false)), true, "first combat hit succeeds")
	_expect_equal(bool(result.get("enemy_defeated", true)), false, "first combat hit keeps enemy active")
	var feedback: Dictionary = result.get("combat_feedback", {})
	_expect_text_contains(String(feedback.get("summary", "")), "命中: -", "combat feedback records hit damage")
	_expect_text_contains(String(feedback.get("pressure", "")), "生命 -4", "combat feedback records health pressure")
	_expect_equal(map.get_current_combat_target() == enemy, true, "map exposes current combat target")
	map.free()


func _check_hud_panel_uses_current_target_and_recent_feedback() -> void:
	var hud := PrototypeHudScene.instantiate() as PrototypeHud
	get_root().add_child(hud)
	var world := WorldState.create_default()
	var character := CharacterState.create_default()
	character.health = 42.0
	character.protection = 51.0
	var enemy := _create_enemy("enemy.treatment_skitter", "enemy_instance.treatment_skitter")
	var feedback := DemoCombatReadabilityFormatter.format_hit_feedback(
		enemy,
		10.0,
		25.0,
		42.0,
		33.0,
		51.0,
		51.0,
		"处理点掠行体 反击，生命 -9。"
	)

	hud.show_combat_feedback(feedback)
	hud.update_combat_readability(data_registry, world, character, enemy)
	var panel := hud.get_node("CombatPanel") as ColorRect
	var label := hud.get_node("CombatPanel/CombatLabel") as Label
	_expect_equal(panel.visible, true, "combat panel is visible with target")
	_expect_text_contains(label.text, "目标: HP 35/35 / 中威胁 / 生命承压", "hud panel shows focused enemy")
	_expect_text_contains(label.text, "最近: 命中: -10, HP 25", "hud panel shows recent hit")
	_expect_text_contains(label.text, "承压: 生命 -9", "hud panel shows pressure delta")
	_expect_combat_panel_font_safe(label.text)

	enemy.free()
	hud.free()


func _create_enemy(definition_id: String, instance_id: String) -> PrototypeEnemy:
	var enemy := PrototypeEnemy.new()
	enemy.definition_id = definition_id
	enemy.instance_id = instance_id
	var definition := data_registry.get_definition(definition_id)
	var base_stats: Dictionary = definition.get("base_stats", {})
	enemy.setup(
		data_registry.get_text(String(definition.get("display_name_key", definition_id))),
		float(base_stats.get("max_health", 20.0)),
		String(definition.get("category", "basic"))
	)
	enemy.configure_readability_tags(
		DemoCombatReadabilityFormatter.format_enemy_threat_label(data_registry, enemy),
		DemoCombatReadabilityFormatter.format_enemy_pressure_label(data_registry, enemy)
	)
	return enemy


func _expect_equal(actual, expected, context: String) -> void:
	if actual == expected:
		return
	failures.append("%s: expected %s, got %s" % [context, str(expected), str(actual)])


func _expect_text_contains(text: String, expected: String, context: String) -> void:
	if text.contains(expected):
		return
	failures.append("%s: missing '%s' in '%s'" % [context, expected, text])


func _expect_combat_panel_font_safe(text: String) -> void:
	for glyph in ["：", "；", "，", "。", "·", "→", "Ⅰ", "Ⅱ", "Ⅲ", "防护", "稳定", "警戒", "危险", "敌人", "掠行体", "近战压制", "扫描锁定", "压力点"]:
		if text.contains(glyph):
			failures.append("combat panel keeps glyph-risk text '%s' in '%s'" % [glyph, text])


func _cleanup() -> void:
	data_registry.free()
