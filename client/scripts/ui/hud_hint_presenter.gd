extends RefCounted
class_name HudHintPresenter


func format_direction_hint(world_state: WorldState, character_state: CharacterState, quest_id: String) -> String:
	if quest_id.is_empty():
		if _is_slice_complete(world_state):
			return "第一切片原型已收束；返回基地整理补给，后续区域待开放。"
		return "按当前目标推进。"

	match quest_id:
		"quest.restore_outpost":
			return "检查左侧前哨核心，解锁晶体矿脉导航。"
		"quest.scout_crystal_field":
			return "向东进入蓝色晶体矿脉区，采集晶体矿物。"
		"quest.calibrate_reactor":
			if world_state.quest_state.get_objective_progress(quest_id, "gather_item", "item.salvage_scrap") < 4.0:
				return "在晶体矿脉区回收外勤残骸，凑齐导电废件后回基地。"
			return "回基地使用基础反应器，组装反应器校准件。"
		"quest.bring_back_sample":
			if world_state.quest_state.get_objective_progress(quest_id, "sample_object", "map_object.anomaly_crystal") <= 0.0:
				return "向东南采样异常晶体；采样后就近确认周边残留。"
			return "采样完成，继续回收异常晶体周边残留点。"
		"quest.analyze_anomaly_sample":
			if world_state.quest_state.get_objective_progress(quest_id, "gather_item", "item.anomaly_residue") < 2.0:
				return "回到异常晶体周边，回收两处异常残留点。"
			return "回基地使用基础反应器，分析异常样本。"
		"quest.make_filter_module":
			return "回基地使用基础反应器，组装基础过滤模块。"
		"quest.prepare_treatment_supplies":
			if world_state.quest_state.get_objective_progress(quest_id, "craft_item", "item.repair_gel") <= 0.0:
				return "回基地用基础反应器调制修复凝胶，给处理点施工做准备。"
			return "前往处理点北缘，清理徘徊的原生掠行体。"
		"quest.expand_treatment_point":
			return "前往污染边界北缘，清理地块、铺设地基并建造过滤器。"
		"quest.enter_pollution_edge":
			if not world_state.unlocked_region_ids.has("region.pollution_edge"):
				return "按 F 启用过滤模块，再向东进入黄色污染边界。"
			if character_state.protection < character_state.max_protection * 0.5:
				return "防护偏低，先用 2 补充或回基地再深入污染边界。"
			return "向东南进入黄色污染边界，采集沉积物并处理药剂。"
		"quest.defeat_elite_node":
			return "污染深处仍有精英节点，携带补给后继续向东推进。"
		"quest.unlock_ruin_signal":
			return "向污染边界东侧检查封锁遗迹入口；此处仅确认后续信号。"
		_:
			return "按当前目标推进。"


func format_onboarding_hint(world_state: WorldState, character_state: CharacterState, quest_id: String) -> String:
	if quest_id.is_empty():
		if _is_slice_complete(world_state):
			return "更深区域信号已确认，整理补给后等待后续内容。"
		return "查看当前目标和附近交互提示，按顺序推进。"

	match quest_id:
		"quest.restore_outpost":
			return "先恢复前哨核心；基地设备会告诉你缺什么资源。"
		"quest.scout_crystal_field":
			if world_state.current_region_id != "region.crystal_vein_field":
				return "晶体矿物是第一批加工输入，先去蓝色晶体区。"
			return "采集晶体簇；遇到掠行体时先用基础攻击处理威胁。"
		"quest.calibrate_reactor":
			if world_state.quest_state.get_objective_progress(quest_id, "gather_item", "item.salvage_scrap") < 4.0:
				return "外勤残骸提供导电废件；回收两处残骸后回基地加工校准件。"
			return "靠近基础反应器，切换到反应器校准件配方并等待加工完成。"
		"quest.bring_back_sample":
			if world_state.quest_state.get_objective_progress(quest_id, "sample_object", "map_object.anomaly_crystal") <= 0.0:
				return "采样异常晶体；样本分析还需要周边残留物校验。"
			return "采样已完成，先在周边回收残留物，再回基地加工分析。"
		"quest.analyze_anomaly_sample":
			if world_state.quest_state.get_objective_progress(quest_id, "gather_item", "item.anomaly_residue") < 2.0:
				return "异常残留物用于校验样本，回收两处后再回基地加工分析。"
			return "靠近基础反应器，切换到异常样本分析配方并等待完成。"
		"quest.make_filter_module":
			return "基础反应器负责制造远征产物；先补齐配方输入，再等待加工完成。"
		"quest.prepare_treatment_supplies":
			if world_state.quest_state.get_objective_progress(quest_id, "craft_item", "item.repair_gel") <= 0.0:
				return "先调制 1 份修复凝胶；后续处理点施工会经过敌人巡游区。"
			return "带上修复凝胶，清理处理点北缘的原生掠行体。"
		"quest.expand_treatment_point":
			if world_state.count_base_structures("building.foundation_t1") < 2:
				return "污染过滤器不能直接落地，先清理地块并铺设 2 块地基。"
			return "地基已满足要求，建造污染过滤器来处理沉积物。"
		"quest.enter_pollution_edge":
			if String(character_state.equipment.get("suit_module", "")).is_empty():
				return "启用基础过滤模块后再深入污染区，防护消耗会降低。"
			if character_state.protection < character_state.max_protection * 0.5:
				return "防护偏低，先使用抗污染药剂或回基地补给。"
			return "收集污染沉积物，用过滤器处理药剂，再清理受扰敌人。"
		"quest.defeat_elite_node":
			return "污染残核是本轮危险区域挑战；带好修复凝胶和抗污染药剂再压制精英节点。"
		"quest.unlock_ruin_signal":
			return "检查封锁遗迹入口即可结束本切片，不会进入新区域。"
		_:
			return "按当前目标推进；失败时查看日志和撤离反馈。"


func _is_slice_complete(world_state: WorldState) -> bool:
	return world_state.quest_state.unlocked_effects.has("slice_01_complete")
