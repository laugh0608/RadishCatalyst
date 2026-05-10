extends RefCounted
class_name CharacterProgressionStats

const BASE_HEALTH := 100.0
const BASE_PROTECTION := 100.0
const LEGACY_SYNC_LOG_MESSAGE := "旧进度已接入：生命与防护上限已按深段里程碑同步。"
const PROGRESSION_MILESTONES := [
	{
		"quest_id": "quest.unlock_deep_ruin_cache",
		"health_bonus": 15.0,
		"protection_bonus": 15.0
	},
	{
		"quest_id": "quest.inspect_phase_fault_spire",
		"health_bonus": 15.0,
		"protection_bonus": 15.0
	},
	{
		"quest_id": "quest.unlock_phase_well",
		"health_bonus": 15.0,
		"protection_bonus": 15.0
	},
	{
		"quest_id": "quest.inspect_inner_phase_well",
		"health_bonus": 15.0,
		"protection_bonus": 15.0
	},
	{
		"quest_id": "quest.inspect_phase_well_sink",
		"health_bonus": 15.0,
		"protection_bonus": 15.0
	},
	{
		"quest_id": "quest.inspect_phase_well_chamber",
		"health_bonus": 15.0,
		"protection_bonus": 15.0
	},
	{
		"quest_id": "quest.inspect_phase_well_loom",
		"health_bonus": 15.0,
		"protection_bonus": 15.0
	}
]


static func get_expected_vitals(quest_state: QuestState) -> Dictionary:
	var max_health := BASE_HEALTH
	var max_protection := BASE_PROTECTION
	if quest_state == null:
		return {
			"max_health": max_health,
			"max_protection": max_protection
		}

	for milestone in PROGRESSION_MILESTONES:
		if not quest_state.has_completed_quest(String(milestone.get("quest_id", ""))):
			continue
		max_health += float(milestone.get("health_bonus", 0.0))
		max_protection += float(milestone.get("protection_bonus", 0.0))

	return {
		"max_health": max_health,
		"max_protection": max_protection
	}


static func sync_character_state(
	character_state: CharacterState,
	quest_state: QuestState,
	refill_mode: String = "clamp"
) -> Dictionary:
	if character_state == null:
		return {
			"changed": false
		}

	var expected := get_expected_vitals(quest_state)
	var expected_max_health := float(expected.get("max_health", BASE_HEALTH))
	var expected_max_protection := float(expected.get("max_protection", BASE_PROTECTION))
	var previous_max_health := maxf(1.0, character_state.max_health)
	var previous_max_protection := maxf(1.0, character_state.max_protection)
	var max_health_delta := expected_max_health - character_state.max_health
	var max_protection_delta := expected_max_protection - character_state.max_protection
	var changed := not is_equal_approx(max_health_delta, 0.0) or not is_equal_approx(max_protection_delta, 0.0)

	var previous_health_ratio := clampf(character_state.health / previous_max_health, 0.0, 1.0)
	var previous_protection_ratio := clampf(character_state.protection / previous_max_protection, 0.0, 1.0)
	var previous_health := character_state.health
	var previous_protection := character_state.protection

	character_state.max_health = expected_max_health
	character_state.max_protection = expected_max_protection

	match refill_mode:
		"gain":
			if max_health_delta > 0.0:
				character_state.health += max_health_delta
			if max_protection_delta > 0.0:
				character_state.protection += max_protection_delta
		"preserve_ratio":
			character_state.health = expected_max_health * previous_health_ratio
			character_state.protection = expected_max_protection * previous_protection_ratio
		_:
			pass

	character_state.health = clampf(character_state.health, 0.0, character_state.max_health)
	character_state.protection = clampf(character_state.protection, 0.0, character_state.max_protection)

	return {
		"changed": changed,
		"max_health_delta": max_health_delta,
		"max_protection_delta": max_protection_delta,
		"health_delta": character_state.health - previous_health,
		"protection_delta": character_state.protection - previous_protection
	}


static func format_reward_message(sync_result: Dictionary) -> String:
	var max_health_delta := float(sync_result.get("max_health_delta", 0.0))
	var max_protection_delta := float(sync_result.get("max_protection_delta", 0.0))
	if max_health_delta <= 0.0 and max_protection_delta <= 0.0:
		return ""
	return "生命上限 +%s，防护上限 +%s" % [
		_format_amount(max_health_delta),
		_format_amount(max_protection_delta)
	]


static func _format_amount(amount: float) -> String:
	if is_equal_approx(amount, roundf(amount)):
		return str(int(amount))
	return "%.1f" % amount
