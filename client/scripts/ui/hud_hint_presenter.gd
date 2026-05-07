extends RefCounted
class_name HudHintPresenter

var target_region_resolver: QuestTargetRegionResolver


func configure(data_registry: DataRegistry, map: VerticalSliceMap) -> void:
	if data_registry == null:
		target_region_resolver = null
		return
	target_region_resolver = QuestTargetRegionResolver.new(data_registry)
	target_region_resolver.configure_from_map(map)


func format_direction_hint(world_state: WorldState, character_state: CharacterState, quest_id: String) -> String:
	if quest_id.is_empty():
		if _is_slice_complete(world_state):
			return "第一切片原型已收束；返回基地整理补给，后续区域待开放。"
		return "按当前目标推进。"

	var target_region_id := _get_target_region_id(world_state, quest_id)
	match quest_id:
		"quest.restore_outpost":
			return "检查左侧前哨核心，解锁晶体矿脉导航。"
		"quest.scout_crystal_field":
			return "向东进入蓝色晶体矿脉区，采集晶体矿物。"
		"quest.calibrate_reactor":
			if target_region_id != "region.outpost_platform":
				return "在晶体矿脉区回收外勤残骸，凑齐导电废件后回基地。"
			return "回基地使用基础反应器，组装反应器校准件。"
		"quest.bring_back_sample":
			if world_state.quest_state.get_objective_progress(quest_id, "sample_object", "map_object.anomaly_crystal") <= 0.0:
				return "向东南采样异常晶体；采样后就近确认周边残留。"
			return "采样完成，继续回收异常晶体周边残留点。"
		"quest.analyze_anomaly_sample":
			if target_region_id != "region.outpost_platform":
				return "回到异常晶体周边，回收两处异常残留点。"
			return "回基地使用基础反应器，分析异常样本。"
		"quest.make_filter_module":
			return "回基地使用基础反应器，组装基础过滤模块。"
		"quest.prepare_treatment_supplies":
			if target_region_id == "region.outpost_platform":
				return "回基地用基础反应器调制修复凝胶，它是下一段清障战斗补给。"
			return "确认快捷栏 1 带修复凝胶，前往处理点北缘清理掠行体。"
		"quest.expand_treatment_point":
			return "前往处理点北缘，清理地块、铺设地基并建造过滤器。"
		"quest.enter_pollution_edge":
			if not world_state.unlocked_region_ids.has("region.pollution_edge"):
				return "按 F 启用过滤模块，再向东进入黄色污染边界。"
			if target_region_id == "region.crystal_vein_field":
				return "返回处理点过滤器处理沉积物，先调制抗污染药剂再深入污染边界。"
			if character_state.protection < character_state.max_protection * 0.5:
				return "防护偏低，按 2 使用抗污染药剂；药剂来自过滤器处理沉积物。"
			return "向东南进入黄色污染边界，采集沉积物并处理药剂。"
		"quest.defeat_elite_node":
			return "污染残核会持续压低防护，带抗污染药剂后继续向东推进。"
		"quest.unlock_ruin_signal":
			return "前往污染边界东侧检查封锁遗迹入口；此处仅确认后续信号。"
		_:
			return "按当前目标推进。"


func format_onboarding_hint(world_state: WorldState, character_state: CharacterState, quest_id: String) -> String:
	if quest_id.is_empty():
		if _is_slice_complete(world_state):
			return "更深区域信号已确认，整理补给后等待后续内容。"
		return "查看当前目标和附近交互提示，按顺序推进。"

	var target_region_id := _get_target_region_id(world_state, quest_id)
	match quest_id:
		"quest.restore_outpost":
			return "先恢复前哨核心；基地设备会告诉你缺什么资源。"
		"quest.scout_crystal_field":
			if target_region_id == "region.crystal_vein_field" and world_state.current_region_id != target_region_id:
				return "晶体矿物是第一批加工输入，先去蓝色晶体区。"
			return "采集晶体簇；遇到掠行体时先用基础攻击处理威胁。"
		"quest.calibrate_reactor":
			if target_region_id != "region.outpost_platform":
				return "外勤残骸提供导电废件；回收两处残骸后回基地加工校准件。"
			return "靠近基础反应器，切换到反应器校准件配方并等待加工完成。"
		"quest.bring_back_sample":
			if world_state.quest_state.get_objective_progress(quest_id, "sample_object", "map_object.anomaly_crystal") <= 0.0:
				return "采样异常晶体；样本分析还需要周边残留物校验。"
			return "采样已完成，先在周边回收残留物，再回基地加工分析。"
		"quest.analyze_anomaly_sample":
			if target_region_id != "region.outpost_platform":
				return "异常残留物用于校验样本，回收两处后再回基地加工分析。"
			return "靠近基础反应器，切换到异常样本分析配方并等待完成。"
		"quest.make_filter_module":
			return "基础反应器负责制造远征产物；先补齐配方输入，再等待加工完成。"
		"quest.prepare_treatment_supplies":
			if target_region_id == "region.outpost_platform":
				return "先调制 1 份修复凝胶；它是下一段清障战斗的生命补给。"
			return "带上修复凝胶，生命偏低时按 1 使用，再清理处理点北缘的原生掠行体。"
		"quest.expand_treatment_point":
			if world_state.count_base_structures("building.foundation_t1") < 2:
				return "污染过滤器不能直接落地，先清理地块并铺设 2 块地基。"
			return "地基已满足要求，建造污染过滤器来处理沉积物。"
		"quest.enter_pollution_edge":
			if String(character_state.equipment.get("suit_module", "")).is_empty():
				return "启用基础过滤模块后再深入污染区，防护消耗会降低。"
			if target_region_id == "region.crystal_vein_field":
				return "先回处理点过滤器处理沉积物，把抗污染药剂做出来，再继续深入污染区。"
			if character_state.protection < character_state.max_protection * 0.5:
				return "防护偏低，先使用抗污染药剂；缺药剂就回污染过滤器处理沉积物。"
			return "收集污染沉积物，用过滤器处理药剂，再清理受扰敌人。"
		"quest.defeat_elite_node":
			return "污染残核是本轮危险区域挑战；抗污染药剂用于维持防护，修复凝胶用于保命。"
		"quest.unlock_ruin_signal":
			return "检查封锁遗迹入口即可结束本切片，不会进入新区域。"
		_:
			return "按当前目标推进；失败时查看日志和撤离反馈。"


func _is_slice_complete(world_state: WorldState) -> bool:
	return world_state.quest_state.unlocked_effects.has("slice_01_complete")


func _get_target_region_id(world_state: WorldState, quest_id: String) -> String:
	if target_region_resolver == null:
		return ""
	return target_region_resolver.resolve_target_region_id(world_state, quest_id)
