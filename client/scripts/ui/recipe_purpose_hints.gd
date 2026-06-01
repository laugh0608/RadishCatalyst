extends RefCounted
class_name RecipePurposeHints


static func format_recipe_goal_hint(recipe_id: String) -> String:
	match recipe_id:
		"recipe.process_crystal_ore":
			return "把晶体矿物转成基础零件，支撑校准件、过滤模块、地基和补给。"
		"recipe.reactor_calibrator":
			return "校准反应器采样通道，做完就去异常晶体采样。"
		"recipe.analyze_anomaly_sample":
			return "把异常样本和残留物分析成过滤参数，做完会开放过滤介质和模块制造。"
		"recipe.make_filter_media":
			return "制造基础过滤模块的中间材料，做完继续组装基础过滤模块。"
		"recipe.basic_filter_module":
			return "降低污染区防护消耗，做完按 F 启用后再准备处理点补给。"
		"recipe.repair_gel":
			return "准备下一段处理点战斗补给，生命偏低时按 1 使用。"
		"recipe.foundation_t1":
			return "制造处理点地基材料，做完去处理点北缘铺设两块地基；缺料时回访处理点入口前的晶体和残骸。"
		"recipe.cleanse_residue":
			return "把污染沉积物处理成抗污染药剂，按 2 补防护后继续深入污染边界。"
	return ""


static func format_build_goal_hint(building_id: String) -> String:
	match building_id:
		"building.foundation_t1":
			return "给污染过滤器提供落点；铺好两块后继续建造污染过滤器。"
		"building.pollution_filter":
			return "把污染沉积物处理成抗污染药剂，支撑再次深入污染边界。"
	return ""
