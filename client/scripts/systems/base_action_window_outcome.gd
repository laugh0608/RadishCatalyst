extends RefCounted
class_name BaseActionWindowOutcome

const PLAN_STEADY_SUPPLY := "steady_supply_buffer"
const PLAN_PHASE_SURVEY := "phase_survey_intel"
const PLAN_PRESSURE_CLEARANCE := "pressure_clearance_guard"

const OUTCOMES := {
	PLAN_STEADY_SUPPLY: {
		"window_target": "读取 1 处稳相缓存并回收稳定样本",
		"window_result": "稳相垫片压低窗口抖动并带回稳相缓存样本，处理后生成强化资源回收依据",
		"resolution": "前线异常窗口已按低风险补给计划处理：稳相垫片压低了窗口抖动并带回稳相缓存样本，回基地行动台可把它改良成下一轮资源回收依据。",
		"payoff": "稳相缓存样本已改良为下一轮强化资源回收依据，可支撑低风险补给或覆盖测绘往返。",
		"plan_notes": {
			PLAN_STEADY_SUPPLY: "稳相缓存样本已归档，补给候选会继续强调强化回收和短目标",
			PLAN_PHASE_SURVEY: "稳相缓存样本已归档，测绘候选可预告补给缓冲覆盖两处读数往返",
			PLAN_PRESSURE_CLEARANCE: "稳相缓存样本已归档，清障候选会先说明防护补给再处理扰点"
		},
		"carryovers": {
			PLAN_STEADY_SUPPLY: "稳相缓存承接：目标预告=短目标补给回收；路线扰动=低；资源回收=强化基础零件缓冲。",
			PLAN_PHASE_SURVEY: "稳相缓存承接：基础零件 / 修复凝胶可覆盖两处读数往返；目标预告：测绘仍需西侧和东侧两处读数。",
			PLAN_PRESSURE_CLEARANCE: "稳相缓存承接：清障前会先说明防护补给如何覆盖扰点处理。"
		}
	},
	PLAN_PHASE_SURVEY: {
		"window_target": "读取西侧边界和东侧扰动 2 处路线回波",
		"window_result": "回波透镜校准两处路线回波并带回透镜校准读数，处理后生成低扰动目标预告依据",
		"resolution": "前线异常窗口已按信息侦测计划处理：回波透镜校准了两处路线回波并带回透镜校准读数，回基地行动台可把它作为下一轮低扰动目标预告依据。",
		"payoff": "透镜校准读数已转成下一轮低扰动目标预告依据，可支撑补给投放、复测路线或提前判断清障扰点。",
		"plan_notes": {
			PLAN_STEADY_SUPPLY: "透镜校准读数已归档，补给候选会贴近西侧已显形路线投放",
			PLAN_PHASE_SURVEY: "透镜校准读数已归档，测绘候选会以低扰动路线复核两处回波",
			PLAN_PRESSURE_CLEARANCE: "透镜校准读数已归档，清障候选会提前标出东侧短时扰动位置"
		},
		"carryovers": {
			PLAN_STEADY_SUPPLY: "透镜校准承接：目标预告=西侧低压边界补给投放；路线扰动=低；防护消耗=低。",
			PLAN_PHASE_SURVEY: "透镜校准承接：目标预告=复核西侧边界 / 东侧扰动来源；路线扰动=低；防护消耗=低。",
			PLAN_PRESSURE_CLEARANCE: "透镜校准承接：目标预告=东侧短时扰动位置；路线扰动=中；防护消耗=中。"
		}
	},
	PLAN_PRESSURE_CLEARANCE: {
		"window_target": "清理 1 处压力扰点并读取扰动残压",
		"window_result": "防护涂层承接扰动残压并带回涂层样本，处理后生成改良防护整备依据",
		"resolution": "前线异常窗口已按压力清障计划处理：防护涂层接住扰动残压并带回涂层样本，回基地行动台可把它改良成下一轮防护整备依据。",
		"payoff": "防护涂层样本已改良为下一轮风险回落依据，可支撑低压补给、测绘预告或低消耗清障。",
		"plan_notes": {
			PLAN_STEADY_SUPPLY: "涂层样本已归档，补给候选可在低压窗口回收资源缓冲",
			PLAN_PHASE_SURVEY: "涂层样本已归档，测绘候选可把低干扰路线转成目标预告",
			PLAN_PRESSURE_CLEARANCE: "涂层样本已改良，清障候选会说明低消耗防护整备"
		},
		"carryovers": {
			PLAN_STEADY_SUPPLY: "涂层样本承接：目标预告=低压窗口补给回收；路线扰动=低；防护消耗=低。",
			PLAN_PHASE_SURVEY: "涂层样本承接：目标预告=低干扰路线测绘；路线扰动=中；防护消耗=低。",
			PLAN_PRESSURE_CLEARANCE: "涂层样本承接：目标预告=继续清障扰点；路线扰动=中；防护消耗=低。"
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
