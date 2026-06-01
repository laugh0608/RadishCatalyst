extends RefCounted
class_name BaseActionPlanPreview

const PLAN_STEADY_SUPPLY := "steady_supply_buffer"
const PLAN_PHASE_SURVEY := "phase_survey_intel"
const PLAN_PRESSURE_CLEARANCE := "pressure_clearance_guard"
const OVERPRESSURE_MODULE_NAME := "三模块联锁"

const OVERPRESSURE_WINDOW_PREVIEW := {
	"label": "高压窗口",
	"choice_label": "高压窗口",
	"target": "稳住 1 处高压异常窗口并压制扰点",
	"reward": "高压窗口稳定数据",
	"risk": "高",
	"risk_detail": "需要同时依赖补给缓冲、低扰动路线和低消耗防护",
	"risk_profile": "目标密度 高；路线扰动 中；防护消耗 中",
	"cost": "占用本次出发整备槽，复用三类模块归档收益",
	"module": OVERPRESSURE_MODULE_NAME,
	"module_effect": "稳相垫片、回波透镜和防护涂层共同支撑更危险的高压窗口处理"
}

const PLAN_PREVIEWS := {
	PLAN_STEADY_SUPPLY: {
		"label": "低风险补给",
		"choice_label": "稳场补给",
		"target": "读取 1 处稳场补给投放点",
		"reward": "基础零件 +2、修复凝胶 +1",
		"risk": "低",
		"risk_detail": "不增加前线读点，适合补资源缓冲",
		"risk_profile": "目标密度 低；路线扰动 低；防护消耗 低",
		"cost": "占用本次出发整备槽，回投时一次性消耗",
		"module": "稳相垫片",
		"module_effect": "压低窗口抖动并带回稳相缓存样本，回基地后强化下一轮资源回收"
	},
	PLAN_PHASE_SURVEY: {
		"label": "信息侦测",
		"choice_label": "相位测绘",
		"target": "读取西侧和东侧 2 处相位测绘点",
		"reward": "目标显形和路线风险预告",
		"risk": "中",
		"risk_detail": "需要按低压读数线避开东侧短时扰动",
		"risk_profile": "目标密度 中；路线扰动 中；防护消耗 低",
		"cost": "占用本次出发整备槽，不额外发放资源",
		"module": "回波透镜",
		"module_effect": "校准两处路线回波并带回透镜读数，回基地后降低下一轮路线扰动"
	},
	PLAN_PRESSURE_CLEARANCE: {
		"label": "压力清障",
		"choice_label": "压力清障",
		"target": "击退 1 个清障扰动守卫并清除 1 处前线压力扰点",
		"reward": "修复凝胶 +1、抗污染药剂 +1",
		"risk": "高",
		"risk_detail": "需要处理一场短战斗和一处高压扰点",
		"risk_profile": "目标密度 低；路线扰动 高；防护消耗 中",
		"cost": "占用本次出发整备槽，回投时一次性装入",
		"module": "防护涂层",
		"module_effect": "承接清障残压并带回涂层样本，回基地后改良下一轮防护整备"
	}
}


static func get_plan_preview(plan_key: String) -> Dictionary:
	return PLAN_PREVIEWS.get(plan_key, {})


static func get_overpressure_window_preview() -> Dictionary:
	return OVERPRESSURE_WINDOW_PREVIEW
