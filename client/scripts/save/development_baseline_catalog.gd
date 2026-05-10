extends RefCounted
class_name DevelopmentBaselineCatalog

const BASELINE_DEFINITIONS := [
	{
		"id": "baseline.s0_new_game",
		"code": "S0",
		"display_name": "S0 新档",
		"completed_through": "",
		"summary": "从恢复前哨开始，覆盖完整冷启动主线。",
		"recommended_for": "全链路空档复测、早期目标理解、共享系统回归。"
	},
	{
		"id": "baseline.s1_treatment_ready",
		"code": "S1",
		"display_name": "S1 处理点已就绪",
		"completed_through": "quest.expand_treatment_point",
		"summary": "已完成处理点扩建，下一步进入污染边界。",
		"recommended_for": "过滤模块启用、污染边界、药剂处理与污染战斗回归。"
	},
	{
		"id": "baseline.s2_outer_ring_secured",
		"code": "S2 外圈中继已确认",
		"completed_through": "quest.secure_outer_ring_signal",
		"summary": "遗迹外圈主闭环已完成，下一步回收外圈回波匣。",
		"recommended_for": "外圈回波匣、深段回波、基地解析与第二闭环入口回归。"
	},
	{
		"id": "baseline.s3_deep_entrance_open",
		"code": "S3",
		"display_name": "S3 深段门禁已开",
		"completed_through": "quest.unlock_deep_ruin_entrance",
		"summary": "更深遗迹坐标已写入，下一步进入深段回收相位纤丝。",
		"recommended_for": "深段入口、相位纤丝回收、过滤器精炼和覆写栓链路回归。"
	},
	{
		"id": "baseline.s4_deep_cache_open",
		"code": "S4",
		"display_name": "S4 深段样块已回收",
		"completed_through": "quest.unlock_deep_ruin_cache",
		"summary": "深段样块已带回，下一步在基地解析并进入第二轮阵列线。",
		"recommended_for": "深段样块解析、阵列点亮、追袭体与相位导管链路回归。"
	},
	{
		"id": "baseline.s5_phase_relay_online",
		"code": "S5",
		"display_name": "S5 前线回传已上线",
		"completed_through": "quest.deploy_phase_relay_anchor",
		"summary": "前线回传锚点和基地相位回投台都已在线，下一步从回投台重返前线并追踪裂相碎屑。",
		"recommended_for": "前线回传、基地回投、回传后的新深段内容、旧进度兼容与节奏回归。"
	}
]


static func get_baseline_definitions() -> Array[Dictionary]:
	var definitions: Array[Dictionary] = []
	for definition in BASELINE_DEFINITIONS:
		var baseline_definition: Dictionary = definition
		definitions.append(baseline_definition.duplicate(true))
	return definitions


static func get_baseline_ids() -> Array[String]:
	var baseline_ids: Array[String] = []
	for definition in BASELINE_DEFINITIONS:
		var baseline_definition: Dictionary = definition
		baseline_ids.append(String(baseline_definition.get("id", "")))
	return baseline_ids


static func get_definition(baseline_id: String) -> Dictionary:
	for definition in BASELINE_DEFINITIONS:
		var candidate: Dictionary = definition
		if String(candidate.get("id", "")) == baseline_id:
			return candidate.duplicate(true)
	return {}


static func get_default_baseline_id() -> String:
	if BASELINE_DEFINITIONS.is_empty():
		return ""
	var first_definition: Dictionary = BASELINE_DEFINITIONS[0]
	return String(first_definition.get("id", ""))
