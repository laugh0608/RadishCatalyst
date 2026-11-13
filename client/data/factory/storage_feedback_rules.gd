extends RefCounted

const Storage := preload("res://data/factory/grid_storage_rules.gd")
const Timed := preload("res://data/factory/timed_dispatch_rules.gd")
const SUPPLY_ID := "factory_integrated_storage_feedback_starter_v1"
const RULESET_ID := "factory_integrated_storage_feedback_v1"
const RESEARCH := "storage_feedback"
const LOW_J := 1100000
const HIGH_J := 2000000
const PRECISION_J := 1000
# Versioned semantics include step-start sampling, midpoint ties closed,
# retained hysteresis on reconnect, and explicit takeover after source removal.
const BEHAVIOR_VERSION := 1
const NODE := {"name": "储能反馈", "level": 3, "requires": [Storage.TYPE, Timed.TYPE], "sample": false,
	"cost": {"metal_plate": 2, "porous_carrier": 1, "industrial_cell": 1}, "recipes": [], "devices": [],
	"effect": "在节拍器绑定同网储能，以高低电量决定是否允许送入电芯。"}


static func defaults() -> Dictionary:
	return {"mode": "timed", "source_id": 0, "low_j": LOW_J, "high_j": HIGH_J, "latch": "pending"}


static func valid_thresholds(low: Variant, high: Variant) -> bool:
	return low is int and high is int and low >= 0 and high <= Storage.CAPACITY_J and low < high \
		and low % PRECISION_J == 0 and high % PRECISION_J == 0


static func decision(config: Dictionary, joules: int) -> String:
	if config.latch == "pending":
		return "allow" if 2 * joules < config.low_j + config.high_j else "block"
	if joules <= config.low_j:
		return "allow"
	if joules >= config.high_j:
		return "block"
	return config.latch
