extends RefCounted

const Storage := preload("res://data/factory/grid_storage_rules.gd")
const Feedback := preload("res://data/factory/storage_feedback_rules.gd")
const SUPPLY_ID := "factory_integrated_load_groups_starter_v1"
const RULESET_ID := "factory_integrated_load_groups_v1"
const RESEARCH := "load_management"
const MAX_MEMBERS := 8
const INTERVAL := 20
const RESUME_W := 20000
const RESERVE_J := 100000
const PRECISION_J := 1000
const MEMBER_TYPES := ["refinery", "assembler"]
const EXCLUDED_RECIPE := "cell_assembly"
# Own-buffer budget, step-start sampling, whole-group validity, and retained
# decisions on reconnect are part of this identity's versioned semantics.
const BEHAVIOR_VERSION := 1
const NODE := {"name": "负载管理", "level": 3, "requires": [Feedback.RESEARCH], "sample": false,
	"cost": {"construction_pack": 1, "metal_plate": 2, "porous_carrier": 2}, "recipes": [], "devices": [],
	"effect": "在储能配置可推迟组，预计功率不足时暂停新批，保留在制和手动启停。"}


static func defaults() -> Dictionary:
	return {"enabled": false, "member_ids": [], "reserve_j": RESERVE_J, "latch": "pending", "evaluation_ticks_left": 0}


static func valid_reserve(value: Variant) -> bool:
	return value is int and value >= 0 and value <= Storage.CAPACITY_J and value % PRECISION_J == 0


static func eligible(e: Dictionary) -> bool:
	return e.get("type", "") in MEMBER_TYPES and e.get("recipe_id", "") != EXCLUDED_RECIPE


static func decision(previous: String, margin_w: int) -> String:
	if margin_w < 0:
		return "block"
	if margin_w >= RESUME_W:
		return "allow"
	return "block" if previous == "pending" else previous


static func buffer_w(stored_j: int, reserve_j: int, horizon_ticks: int) -> int:
	return mini(int(Storage.DISCHARGE_KW * 1000), maxi(0, stored_j - reserve_j) * INTERVAL / horizon_ticks)
