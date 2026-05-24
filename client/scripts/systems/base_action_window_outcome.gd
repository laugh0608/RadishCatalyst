extends RefCounted
class_name BaseActionWindowOutcome

const PLAN_STEADY_SUPPLY := "steady_supply_buffer"
const PLAN_PHASE_SURVEY := "phase_survey_intel"
const PLAN_PRESSURE_CLEARANCE := "pressure_clearance_guard"

const OUTCOMES := {
	PLAN_STEADY_SUPPLY: {
		"window_target": "读取 1 处稳相缓存并回收稳定样本",
		"window_result": "稳相垫片压低窗口抖动，处理后生成稳定样本和资源缓冲依据",
		"resolution": "前线异常窗口已按低风险补给计划处理：稳相垫片压低了窗口抖动，回基地行动台可把稳定样本作为下一轮资源缓冲依据。",
		"payoff": "稳定样本已转成下一轮资源缓冲依据，可支撑低风险补给或覆盖测绘往返。",
		"plan_notes": {
			PLAN_STEADY_SUPPLY: "稳定样本已归档，补给候选会继续强调资源缓冲和短目标",
			PLAN_PHASE_SURVEY: "稳定样本已归档，测绘候选可预告补给缓冲覆盖两处读数往返",
			PLAN_PRESSURE_CLEARANCE: "稳定样本已归档，清障候选会先说明防护补给再处理扰点"
		},
		"carryovers": {
			PLAN_STEADY_SUPPLY: "资源缓冲承接：稳定样本已归档，补给计划继续压低目标密度并回收基础零件。",
			PLAN_PHASE_SURVEY: "资源缓冲承接：稳定样本已归档，基础零件 / 修复凝胶可覆盖两处读数往返；目标预告：测绘仍需西侧和东侧两处读数。",
			PLAN_PRESSURE_CLEARANCE: "资源缓冲承接：稳定样本已归档，清障前会先说明防护补给如何覆盖扰点处理。"
		}
	},
	PLAN_PHASE_SURVEY: {
		"window_target": "读取西侧边界和东侧扰动 2 处路线回波",
		"window_result": "回波透镜放大路线读数，处理后生成目标预告和路线扰动依据",
		"resolution": "前线异常窗口已按信息侦测计划处理：回波透镜放大了路线读数，回基地行动台可把它作为下一轮目标预告依据。",
		"payoff": "路线读数已转成下一轮目标预告依据，可支撑补给投放或提前判断清障扰点。",
		"plan_notes": {
			PLAN_STEADY_SUPPLY: "路线读数已归档，补给候选会贴近西侧已显形路线投放",
			PLAN_PHASE_SURVEY: "路线读数已归档，测绘候选会继续复核西侧边界和东侧扰动来源",
			PLAN_PRESSURE_CLEARANCE: "路线读数已归档，清障候选会提前标出东侧短时扰动位置"
		},
		"carryovers": {
			PLAN_STEADY_SUPPLY: "路线情报承接：目标预告=西侧低压边界补给投放；路线扰动=避开东侧短时扰动；防护消耗=低。",
			PLAN_PHASE_SURVEY: "路线情报承接：目标预告=复核西侧边界 / 东侧扰动来源；路线扰动=中；防护消耗=低。",
			PLAN_PRESSURE_CLEARANCE: "路线情报承接：目标预告=东侧短时扰动位置；路线扰动=高；防护消耗=中。"
		}
	},
	PLAN_PRESSURE_CLEARANCE: {
		"window_target": "清理 1 处压力扰点并读取扰动残压",
		"window_result": "防护涂层先承接残压，处理后生成防护消耗回落依据",
		"resolution": "前线异常窗口已按压力清障计划处理：防护涂层先接住扰动残压，回基地行动台可把它作为下一轮防护整备依据。",
		"payoff": "扰动残压已转成下一轮风险回落依据，可支撑低压补给、测绘预告或继续防护清障。",
		"plan_notes": {
			PLAN_STEADY_SUPPLY: "残压已收束，补给候选可在低压窗口回收资源缓冲",
			PLAN_PHASE_SURVEY: "残压已收束，测绘候选可把低干扰路线转成目标预告",
			PLAN_PRESSURE_CLEARANCE: "残压已收束，清障候选会继续说明防护整备和风险回落"
		},
		"carryovers": {
			PLAN_STEADY_SUPPLY: "残压回落承接：目标预告=低压窗口补给回收；路线扰动=低；防护消耗=低。",
			PLAN_PHASE_SURVEY: "残压回落承接：目标预告=低干扰路线测绘；路线扰动=中；防护消耗=低。",
			PLAN_PRESSURE_CLEARANCE: "残压回落承接：目标预告=继续清障扰点；路线扰动=中；防护消耗=中。"
		}
	}
}


static func get_window_target(plan_key: String, fallback: String = "") -> String:
	return String(_get_outcome(plan_key).get("window_target", fallback))


static func get_window_result(plan_key: String, fallback: String = "") -> String:
	return String(_get_outcome(plan_key).get("window_result", fallback))


static func get_resolution(plan_key: String) -> String:
	return String(_get_outcome(plan_key).get("resolution", "前线异常窗口已处理：返回基地行动台安排下一轮。"))


static func get_payoff(plan_key: String) -> String:
	return String(_get_outcome(plan_key).get("payoff", ""))


static func get_plan_note(source_plan_key: String, plan_key: String) -> String:
	var plan_notes: Dictionary = _get_outcome(source_plan_key).get("plan_notes", {})
	return String(plan_notes.get(plan_key, ""))


static func get_carryover(source_plan_key: String, plan_key: String) -> String:
	var carryovers: Dictionary = _get_outcome(source_plan_key).get("carryovers", {})
	return String(carryovers.get(plan_key, ""))


static func _get_outcome(plan_key: String) -> Dictionary:
	return OUTCOMES.get(plan_key, {})
