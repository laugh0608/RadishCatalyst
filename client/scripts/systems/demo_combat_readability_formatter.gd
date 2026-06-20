extends RefCounted
class_name DemoCombatReadabilityFormatter

const LOW_RATIO := 0.35
const MEDIUM_RATIO := 0.65


static func format_panel_text(
	data_registry: DataRegistry,
	world_state: WorldState,
	character_state: CharacterState,
	enemy: PrototypeEnemy,
	recent_feedback: Dictionary = {}
) -> String:
	var lines: Array[String] = [
		"战斗现场",
		_format_player_vitals_line(character_state),
		_format_quick_supply_line(data_registry, character_state)
	]
	if enemy != null and enemy.can_be_attacked():
		lines.append(_format_enemy_line(data_registry, enemy))
		lines.append("MODE: %s" % _format_enemy_status_label(enemy))
	else:
		lines.append("目标: NONE / close range")
	var recent_lines := format_recent_feedback_lines(recent_feedback)
	lines.append_array(recent_lines)
	return _sanitize_combat_panel_text("\n".join(lines))


static func format_enemy_threat_label(data_registry: DataRegistry, enemy: PrototypeEnemy) -> String:
	if enemy == null:
		return "未知威胁"
	var definition := data_registry.get_definition(enemy.definition_id)
	var base_stats: Dictionary = definition.get("base_stats", {})
	var damage_types: Array = definition.get("damage_types", [])
	var attack := float(base_stats.get("attack", 0.0))
	if enemy.definition_id == "enemy.demo_stabilization_guard" or enemy.enemy_category == "elite_node":
		return "高威胁"
	if attack >= 14.0:
		return "高威胁"
	if attack >= 9.0 or damage_types.has("pollution"):
		return "中威胁"
	return "低威胁"


static func format_enemy_pressure_label(data_registry: DataRegistry, enemy: PrototypeEnemy) -> String:
	if enemy == null:
		return "未知承压"
	var definition := data_registry.get_definition(enemy.definition_id)
	var damage_types: Array = definition.get("damage_types", [])
	if damage_types.has("pollution"):
		return "生命 / 防护承压"
	return "生命承压"


static func format_hit_feedback(
	_enemy: PrototypeEnemy,
	damage: float,
	enemy_health: float,
	health_before: float,
	health_after: float,
	protection_before: float,
	protection_after: float,
	counter_message: String
) -> Dictionary:
	return {
		"title": "命中反馈",
		"summary": "命中: -%s, HP %s" % [
			_format_amount(damage),
			_format_amount(enemy_health)
		],
		"pressure": _format_pressure_delta(
			health_before,
			health_after,
			protection_before,
			protection_after
		),
		"counter": _compact_counter_message(counter_message)
	}


static func format_defeat_feedback(_enemy: PrototypeEnemy, drops_message: String, followup: String = "") -> Dictionary:
	var details: Array[String] = ["敌人反击停止"]
	if not drops_message.strip_edges().is_empty():
		details.append(_strip_sentence_end(drops_message))
	if not followup.strip_edges().is_empty():
		details.append(_strip_sentence_end(followup))
	return {
		"title": "击败反馈",
		"summary": "击败目标",
		"pressure": _sanitize_combat_panel_text(" / ".join(details)),
		"counter": ""
	}


static func format_no_target_feedback(message: String) -> Dictionary:
	return {
		"title": "攻击未命中",
		"summary": "NO TARGET",
		"pressure": _sanitize_combat_panel_text(_strip_sentence_end(message)),
		"counter": "close range"
	}


static func format_recent_feedback_lines(feedback: Dictionary) -> Array[String]:
	if feedback.is_empty():
		return []
	var lines: Array[String] = []
	var summary := String(feedback.get("summary", "")).strip_edges()
	if not summary.is_empty():
		lines.append("最近: %s" % _sanitize_combat_panel_text(summary))
	var pressure := String(feedback.get("pressure", "")).strip_edges()
	if not pressure.is_empty():
		lines.append("承压: %s" % _sanitize_combat_panel_text(pressure))
	return lines


static func _format_player_vitals_line(character_state: CharacterState) -> String:
	return "自身: 生命 %.0f/%.0f %s / SP %.0f/%.0f %s" % [
		character_state.health,
		character_state.max_health,
		_format_ratio_state(character_state.health, character_state.max_health),
		character_state.protection,
		character_state.max_protection,
		_format_ratio_state(character_state.protection, character_state.max_protection)
	]


static func _format_quick_supply_line(data_registry: DataRegistry, character_state: CharacterState) -> String:
	var parts: Array[String] = []
	for index in range(character_state.quick_slots.size()):
		var item_id := String(character_state.quick_slots[index])
		if item_id.is_empty():
			parts.append("%d 空" % (index + 1))
			continue
		var count := _get_inventory_amount(character_state.inventory, item_id)
		parts.append("%d %sx%s/%s" % [
			index + 1,
			_get_display_name(data_registry, item_id),
			_format_amount(count),
			_format_supply_state(item_id, count, character_state)
		])
	if parts.is_empty():
		return "补给: none"
	return "补给: %s" % " / ".join(parts)


static func _format_supply_state(item_id: String, count: float, character_state: CharacterState) -> String:
	if count <= 0.0:
		match item_id:
			"item.repair_gel":
				return "缺:反应器"
			"item.resistance_vial_t1":
				return "缺:过滤器"
			_:
				return "缺"
	match item_id:
		"item.repair_gel":
			if character_state.health < character_state.max_health * MEDIUM_RATIO:
				return "生命低可用"
			return "可用"
		"item.resistance_vial_t1":
			if character_state.protection < character_state.max_protection * MEDIUM_RATIO:
				return "SP低可用"
			return "可用"
		_:
			return "可用"


static func _format_enemy_line(data_registry: DataRegistry, enemy: PrototypeEnemy) -> String:
	return "目标: HP %.0f/%.0f / %s / %s" % [
		enemy.health,
		enemy.max_health,
		format_enemy_threat_label(data_registry, enemy),
		_sanitize_combat_panel_text(format_enemy_pressure_label(data_registry, enemy))
	]


static func _format_enemy_status_label(enemy: PrototypeEnemy) -> String:
	if enemy == null:
		return "NONE"
	var status := enemy.get_combat_status_label()
	var parts: Array[String] = []
	if status.contains("扫描锁定"):
		parts.append("SCAN")
	if status.contains("压力"):
		parts.append("PRESSURE")
	if status.contains("回写"):
		parts.append("CORE")
	if parts.is_empty():
		parts.append("ACTIVE")
	return " / ".join(parts)


static func _format_ratio_state(value: float, maximum: float) -> String:
	if maximum <= 0.0:
		return "未知"
	var ratio := value / maximum
	if ratio <= LOW_RATIO:
		return "LOW"
	if ratio <= MEDIUM_RATIO:
		return "WARN"
	return "OK"


static func _format_pressure_delta(
	health_before: float,
	health_after: float,
	protection_before: float,
	protection_after: float
) -> String:
	var health_loss := maxf(0.0, health_before - health_after)
	var protection_loss := maxf(0.0, protection_before - protection_after)
	if health_loss <= 0.0 and protection_loss <= 0.0:
		return "未承受反击"
	if protection_loss > 0.0:
		return "生命 -%s / SP -%s" % [
			_format_amount(health_loss),
			_format_amount(protection_loss)
		]
	return "生命 -%s" % _format_amount(health_loss)


static func _compact_counter_message(counter_message: String) -> String:
	var text := _strip_sentence_end(counter_message)
	var sentence_end := text.find("。")
	if sentence_end >= 0:
		return text.substr(0, sentence_end)
	return text


static func _get_inventory_amount(inventory: InventoryState, definition_id: String) -> float:
	if definition_id.begins_with("fluid."):
		return float(inventory.fluids.get(definition_id, 0.0))
	if definition_id.begins_with("equipment."):
		return float(inventory.equipment.get(definition_id, 0))
	return float(inventory.items.get(definition_id, 0))


static func _get_display_name(data_registry: DataRegistry, definition_id: String) -> String:
	var definition := data_registry.get_definition(definition_id)
	if definition.is_empty():
		return definition_id
	return data_registry.get_text(String(definition.get("display_name_key", definition_id)))


static func _format_amount(amount: float) -> String:
	if is_equal_approx(amount, roundf(amount)):
		return str(int(amount))
	return "%.1f" % amount


static func _sanitize_combat_panel_text(text: String) -> String:
	var sanitized := text
	var replacements := [
		["核心复测受扰掠行体", "目标"],
		["核心阶段守卫", "目标"],
		["原生掠行体", "目标"],
		["处理点掠行体", "目标"],
		["受扰掠行体", "目标"],
		["核心回写压力", "CORE"],
		["门前压力点", "PRESSURE"],
		["入口压力点", "PRESSURE"],
		["副产回收点", "PRESSURE"],
		["药剂储备点", "PRESSURE"],
		["近战压制", "ACTIVE"],
		["扫描锁定", "SCAN"],
		["防护", "SP"],
		["稳定", "OK"],
		["警戒", "WARN"],
		["危险", "LOW"],
		["敌人", "目标"],
		["：", ":"],
		["；", " / "],
		["，", ","],
		["。", ""],
		["·", " / "],
		["→", "->"],
		["Ⅰ", "I"],
		["Ⅱ", "II"],
		["Ⅲ", "III"]
	]
	for replacement in replacements:
		sanitized = sanitized.replace(String(replacement[0]), String(replacement[1]))
	return sanitized


static func _strip_sentence_end(text: String) -> String:
	var stripped := text.strip_edges()
	while stripped.ends_with("。"):
		stripped = stripped.substr(0, stripped.length() - 1)
	return stripped
