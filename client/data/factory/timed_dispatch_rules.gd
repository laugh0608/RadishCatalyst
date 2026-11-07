extends RefCounted

const Tech := preload("res://data/factory/integrated_progression.gd")
const SUPPLY_ID := "factory_integrated_timed_dispatch_starter_v1"
const RULESET_ID := "factory_integrated_timed_dispatch_v1"
const TYPE := "timed_dispatch"
const SHAPE := {"name": "节拍调度器", "w": 1, "d": 1}
const MODEL_PATH := "res://assets/factory/grid-controls/timed-dispatch.glb"
const TICKS_PER_SECOND := 20
const DEPARTURE_INTERVAL := 21
const MIN_PERIOD_S := 5
const MAX_PERIOD_S := 600
const MAX_QUOTA := 60
const ASSEMBLY_PACKS := 1
const NODE := {"name": "定量调度", "level": 3, "requires": [Tech.POWDERS], "sample": false,
	"cost": {"metal_plate": 2, "catalyst": 1}, "recipes": [], "devices": [TYPE],
	"effect": "装配节拍调度器。允许一种物品进入单槽，按周期窗口与额度送出。"}


static func departure_limit(ticks: int) -> int:
	# A ready item may depart on the first tick. Each refill costs a snapshot step.
	return (ticks + DEPARTURE_INTERVAL - 1) / DEPARTURE_INTERVAL


static func quota_limit(window_s: int) -> int:
	return mini(MAX_QUOTA, departure_limit(window_s * TICKS_PER_SECOND))
