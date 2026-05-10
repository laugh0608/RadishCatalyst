extends RefCounted
class_name HudHintPresenter

var target_region_resolver: QuestTargetRegionResolver


func configure(data_registry: DataRegistry, map: VerticalSliceMap) -> void:
	if data_registry == null:
		target_region_resolver = null
		return
	target_region_resolver = QuestTargetRegionResolver.new(data_registry)
	target_region_resolver.configure_from_map(map)


func format_runtime_hint(world_state: WorldState, character_state: CharacterState, quest_id: String) -> String:
	var direction_hint := format_direction_hint(world_state, character_state, quest_id)
	var onboarding_hint := format_onboarding_hint(world_state, character_state, quest_id)
	var lines: Array[String] = []
	_append_runtime_hint_line(lines, "方向", direction_hint)
	if onboarding_hint != direction_hint:
		_append_runtime_hint_line(lines, "提示", onboarding_hint)
	return "\n".join(lines)


func format_direction_hint(world_state: WorldState, character_state: CharacterState, quest_id: String) -> String:
	if quest_id.is_empty():
		if _has_completed_phase_well_chamber(world_state):
			return "井心室断面已经交出第一份相位井纺核：更东侧风险线又一次转成了基地可继续放大的新收益锚点。"
		if _has_completed_phase_well_sink(world_state):
			return "相位井心核已带回：先回基地解析心核，把更东侧井心室断面真正压成下一包可执行目标。"
		if _has_completed_inner_phase_well(world_state):
			return "内层相位井井芯样本已带回：先回基地解析井芯样本，把更东侧井底裂口真正压成下一包可执行目标。"
		if _has_completed_phase_well_lock(world_state):
			return "相位井定位器已带回：先回基地解析定位器，把更东侧内层相位井真正落成新的推进包。"
		if _has_completed_phase_fault_spire(world_state):
			return "裂相尖塔已校准：先回基地解析内层故障轨迹，再把更东侧相位井锁压成下一包深段目标。"
		if _has_completed_phase_relay_anchor(world_state):
			if world_state.current_region_id == "region.outpost_platform":
				return "相位回投台已就绪：先在基地按 E 返回最近校准的前线回传锚点，再追踪更东侧裂相碎屑。"
			return "前线回传锚点已在线：先回基地用相位回投台重返前线，再把裂相碎屑带回基地继续加工。"
		if _has_completed_second_deep_pass(world_state):
			return "深段读数矩阵已整理完成：返回深段固定点，把它部署成前线回传锚点。"
		if _has_completed_deep_ruin_entry(world_state):
			return "深段样块已带回：先回基地解析样块，别让这份深段收益停在背包里。"
		if _has_completed_deep_signal_analysis(world_state):
			return "更深遗迹坐标已解析；返回遗迹外圈最东侧，把坐标写入深段入口门禁。"
		if _is_slice_complete(world_state):
			return "遗迹外圈第一版已完成；返回基地整理补给，等待更深区域。"
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
			return "前往污染边界东侧检查封锁遗迹入口，打开遗迹外圈通路。"
		"quest.scout_ruin_outer_ring":
			return "穿过封锁入口进入遗迹外圈，回收两处继电残片。"
		"quest.assemble_phase_anchor":
			return "回基地使用基础反应器，组装稳相信标。"
		"quest.stabilize_outer_ring_barrier":
			return "带着稳相信标返回遗迹外圈，在抖动雾幕前部署后再继续深入。"
		"quest.secure_outer_ring_signal":
			return "穿过已稳定的抖动雾幕，向东检查外圈中继台。"
		"quest.salvage_signal_echo":
			return "继续留在遗迹外圈深段，清理相位守卫并回收外圈回波匣。"
		"quest.analyze_deep_signal":
			return "回基地使用基础反应器，解析深段回波并整理更深遗迹坐标。"
		"quest.unlock_deep_ruin_entrance":
			return "带着更深遗迹坐标返回遗迹外圈最东侧，写入深段入口门禁。"
		"quest.harvest_phase_filament":
			return "进入深段入口，清理深段守卫并回收两处相位纤丝。"
		"quest.refine_phase_filament":
			return "回处理点过滤器，精炼相位纤丝并保留副产污染浆液。"
		"quest.assemble_deep_override":
			return "回基地使用基础反应器，把谐振滤芯和污染浆液组装成深段覆写栓。"
		"quest.unlock_deep_ruin_cache":
			return "带着深段覆写栓返回深段入口，覆写锁扣并取出样块。"
		"quest.analyze_deep_core":
			return "回基地使用基础反应器，解析深段样块并整理路由印片。"
		"quest.activate_deep_array":
			return "带着深段路由印片返回深段，点亮阵列台、清理追袭体并回收两束相位导管。"
		"quest.assemble_deep_signal_matrix":
			return "回基地使用基础反应器，把相位导管和污染浆液整理成可部署锚点的深段读数矩阵。"
		"quest.deploy_phase_relay_anchor":
			return "带着深段读数矩阵返回深段固定点，部署前线回传锚点。"
		"quest.reenter_phase_frontline":
			if world_state.current_region_id == "region.outpost_platform":
				return "在基地按 E 使用相位回投台，返回最近校准的锚点并继续追踪更东侧裂相碎屑。"
			return "先用前线回传锚点回基地，再在相位回投台按 E 回到当前锚点。"
		"quest.trace_phase_splinters":
			return "从锚点继续向东推进，击败裂相猎手并回收两处裂相碎屑。"
		"quest.refine_phase_splinters":
			return "回处理点污染过滤器，把裂相碎屑筛成透镜胚片并保留副产污染浆液。"
		"quest.tune_relay_lens":
			return "回基地使用基础反应器，把透镜胚片、污染浆液和基础零件调准成中继调谐镜。"
		"quest.inspect_phase_fault_spire":
			return "带着中继调谐镜返回更东侧裂相尖塔，校准后带回第一份内层故障轨迹。"
		"quest.analyze_inner_fault_trace":
			return "回基地使用基础反应器，解析内层故障轨迹并整理相位井坐标印片。"
		"quest.collect_fault_residue":
			return "返回裂相尖塔更东侧，击退内层潜猎体并回收两处故障残渣。"
		"quest.refine_fault_residue":
			return "回处理点污染过滤器，把故障残渣稳定成可用于下一步开锁的故障芯。"
		"quest.assemble_phase_well_key":
			return "回基地使用基础反应器，把坐标印片、稳定故障芯和基础零件组装成相位井钥。"
		"quest.unlock_phase_well":
			return "带着相位井钥返回更东侧相位井锁，钉住后带回第一份定位器。"
		"quest.analyze_phase_well_locator":
			return "回基地使用基础反应器，解析相位井定位器并整理内层相位井路由片。"
		"quest.collect_well_flux":
			return "沿定位器路由继续向东推进，击退井口哨戒体并回收两处井涌碎屑。"
		"quest.refine_well_flux":
			return "回处理点污染过滤器，把井涌碎屑筛成可继续组装的相位井稳流芯。"
		"quest.assemble_phase_well_probe":
			return "回基地使用基础反应器，把相位井路由片、稳流芯和基础零件组装成相位井探针。"
		"quest.inspect_inner_phase_well":
			return "带着相位井探针返回更东侧内层相位井，读取第一份井芯样本。"
		"quest.analyze_phase_well_core":
			return "回基地使用基础反应器，解析井芯样本并整理相位井频谱片。"
		"quest.collect_well_ash":
			return "沿井芯频谱继续向东推进，击退井底潜伏体并回收两处井壁余烬。"
		"quest.refine_well_ash":
			return "回处理点污染过滤器，把井壁余烬稳定成可继续组装的相位井稳相格。"
		"quest.assemble_phase_well_pike":
			return "回基地使用基础反应器，把相位井频谱片、稳相格和基础零件组装成井底穿钉。"
		"quest.inspect_phase_well_sink":
			return "带着井底穿钉返回更东侧井底裂口，凿开后带回第一份相位井心核。"
		"quest.analyze_phase_well_heart":
			return "回基地使用基础反应器，解析相位井心核并整理相位井脉搏片。"
		"quest.collect_heart_spine":
			return "沿心核脉搏继续向东推进，击退心室撕裂体并回收两处心棘残片。"
		"quest.refine_heart_spine":
			return "回处理点污染过滤器，把心棘残片稳定成可继续组装的相位井抑振骨。"
		"quest.assemble_phase_well_shunt":
			return "回基地使用基础反应器，把相位井脉搏片、抑振骨和基础零件组装成井心分流栓。"
		"quest.inspect_phase_well_chamber":
			return "带着井心分流栓返回更东侧井心室断面，勘验后带回第一份相位井纺核。"
		_:
			return "按当前目标推进。"


func format_onboarding_hint(world_state: WorldState, character_state: CharacterState, quest_id: String) -> String:
	if quest_id.is_empty():
		if _has_completed_phase_well_chamber(world_state):
			return "相位井纺核已经带回基地，这说明相位井心核后的更深门槛也已经成功压成下一轮基地回投锚点。"
		if _has_completed_phase_well_sink(world_state):
			return "相位井心核不是收尾；要先回基地把它解析成脉搏片，井心室断面才会真正变成新的可执行推进包。"
		if _has_completed_inner_phase_well(world_state):
			return "井芯样本只是下一轮的起点；要先回基地把它解析成频谱片，井底裂口才会真正变成新的可执行推进包。"
		if _has_completed_phase_well_lock(world_state):
			return "相位井定位器不是收尾；先回基地解析它，才能把更东侧内层相位井真正变成新的可验证主线。"
		if _has_completed_phase_fault_spire(world_state):
			return "裂相尖塔已经校准完成：内层故障轨迹必须先回基地解析，才能把更东侧相位井锁真正变成下一包可验证内容。"
		if _has_completed_phase_relay_anchor(world_state):
			if world_state.current_region_id == "region.outpost_platform":
				return "前线回传锚点链已打通：先在基地相位回投台回到当前锚点，再把更东侧裂相碎屑带回基地加工。"
			return "前线回传锚点已经上线：这次要用它把回基地补给和更深收益串成真正的新主线，而不是停在便利功能。"
		if _has_completed_second_deep_pass(world_state):
			return "深段读数矩阵不是终点；要把它带回深段部署成前线回传锚点，才能真正缩短第二轮往返。"
		if _has_completed_deep_ruin_entry(world_state):
			return "第一份深段样块只是开始；要把它回基地解析成路由印片，才能继续放大深段收益。"
		if _has_completed_deep_signal_analysis(world_state):
			return "更深入口价值已经落成可执行坐标；这次要把它真正写回现场门禁，而不是停在背包里。"
		if _is_slice_complete(world_state):
			return "遗迹外圈的第二闭环已跑通，整理补给后等待更深内容。"
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
			return "先确认封锁入口信号，真正把主线推进到遗迹外圈。"
		"quest.scout_ruin_outer_ring":
			return "先把外圈继电残片带回基地；它们是下一次深入所需开路物的核心输入。"
		"quest.assemble_phase_anchor":
			return "稳相信标会直接改变再次深入的结果；污染浆液来自过滤器的上一次处理副产。"
		"quest.stabilize_outer_ring_barrier":
			return "部署稳相信标后，抖动雾幕才会让出外圈深段通路。"
		"quest.secure_outer_ring_signal":
			return "外圈中继台会给出更深遗迹的稳定回波，作为这条第二闭环的收束点。"
		"quest.salvage_signal_echo":
			return "相位守卫压着真正的深段回报；把回波匣带回基地后，才能把这次深入变成下一段入口价值。"
		"quest.analyze_deep_signal":
			return "这次加工不是补给，而是把深段回波整理成更深遗迹坐标，确认外圈收益真实反哺下一次远征。"
		"quest.unlock_deep_ruin_entrance":
			return "这一步要把更深遗迹坐标真正写回现场门禁，别让坐标只停在任务列表里。"
		"quest.harvest_phase_filament":
			return "相位纤丝是这包内容的新外勤收益；先带回基地精炼，再决定能不能继续开锁。"
		"quest.refine_phase_filament":
			return "先用污染过滤器剥掉相位纤丝上的污染层；副产污染浆液会直接作为下一步组装输入。"
		"quest.assemble_deep_override":
			return "深段覆写栓会把过滤器副产的污染浆液和外勤材料重新变成开路物，决定下一次深入是否有效。"
		"quest.unlock_deep_ruin_cache":
			return "只有带着基地组装的覆写栓回来，深段锁扣才会交出第一份真正的深段收益。"
		"quest.analyze_deep_core":
			return "这次回基地不是收尾，而是把深段样块继续整理成新的路由印片，明确下一次深入的落点。"
		"quest.activate_deep_array":
			return "阵列台点亮后才会暴露第二轮风险和收益；追袭体与相位导管要在同一趟深段外勤里一起解决。"
		"quest.assemble_deep_signal_matrix":
			return "把相位导管再次带回基地整理成读数矩阵后，还要把它带回深段部署成回传锚点，才算真正解决第二轮空跑。"
		"quest.deploy_phase_relay_anchor":
			return "这次返回深段不是继续拿材料，而是把基地加工出来的读数矩阵真正写回前线回传锚点，开启前线 -> 基地 -> 前线的快速往返。"
		"quest.reenter_phase_frontline":
			return "先真正用一次回投台，让回传链从便利功能变成明确主线动作；回到锚点后再继续看更东侧新风险。"
		"quest.trace_phase_splinters":
			return "裂相碎屑是回传后的第一份新深段收益；它们必须再回基地加工，才能证明这条更深推进线不是纯跑图。"
		"quest.refine_phase_splinters":
			return "先用污染过滤器把裂相碎屑筛成透镜胚片；副产污染浆液会直接回到下一步中继调谐镜组装。"
		"quest.tune_relay_lens":
			return "中继调谐镜会把过滤器副产重新变成开路物，决定裂相尖塔能否吐出第一份内层故障轨迹。"
		"quest.inspect_phase_fault_spire":
			return "这一步要把基地调准的中继调谐镜真正带回前线，逼出新的深段收益，而不是让它停在背包里。"
		"quest.analyze_inner_fault_trace":
			return "内层故障轨迹不是纪念品；要先回基地把它反解成坐标印片，新的更深门锁才会显形。"
		"quest.collect_fault_residue":
			return "更东侧新敌人和故障残渣要一起解决；这一步负责把新的前线风险和下一次基地加工输入同时带回来。"
		"quest.refine_fault_residue":
			return "先用污染过滤器稳定故障残渣；副产污染浆液会继续反哺相位井钥组装，不需要新设备。"
		"quest.assemble_phase_well_key":
			return "相位井钥会把分析产物和过滤结果重新变成开路物，决定相位井锁能否交出新的定位器。"
		"quest.unlock_phase_well":
			return "这一步要把基地组装的相位井钥真正带回前线，让回传链明确指向下一轮更深相位井目标。"
		"quest.analyze_phase_well_locator":
			return "定位器必须先回基地解析，新的更东侧井口区才会真正解锁成可执行目标，而不是停在任务奖励里。"
		"quest.collect_well_flux":
			return "新井口哨戒体和井涌碎屑要在同一趟外勤里一起解决，这一步负责把新风险和下一步加工输入同时带回来。"
		"quest.refine_well_flux":
			return "先用污染过滤器稳定井涌碎屑；副产污染浆液会继续反哺探针组装，不需要引入第三台设备。"
		"quest.assemble_phase_well_probe":
			return "相位井探针会把定位器分析结果和过滤器输出重新变成开路物，决定内层相位井能否交出第一份井芯样本。"
		"quest.inspect_inner_phase_well":
			return "这一步要把基地组装的相位井探针真正带回前线，让更东侧内层相位井第一次给出明确收益。"
		"quest.analyze_phase_well_core":
			return "井芯样本不是收尾；要先回基地把它反解成频谱片，新的井底裂口风险才会真正显形。"
		"quest.collect_well_ash":
			return "井底潜伏体和井壁余烬要在同一趟外勤里一起解决，这一步负责把新的前线压力和下一次基地加工输入同时带回来。"
		"quest.refine_well_ash":
			return "先用污染过滤器稳定井壁余烬；副产污染浆液会继续反哺井底穿钉组装，不需要引入第三台设备。"
		"quest.assemble_phase_well_pike":
			return "井底穿钉会把井芯分析产物和过滤结果重新变成开路物，决定井底裂口能否交出第一份相位井心核。"
		"quest.inspect_phase_well_sink":
			return "这一步要把基地组装的井底穿钉真正带回前线，让井芯样本后的更深收益第一次落成实体战利品。"
		"quest.analyze_phase_well_heart":
			return "相位井心核不是纪念品；要先回基地把它反解成脉搏片，新的井心室断面风险才会真正显形。"
		"quest.collect_heart_spine":
			return "井心室的新敌人和心棘残片要在同一趟外勤里一起解决，这一步负责把新风险和下一次基地加工输入同时带回来。"
		"quest.refine_heart_spine":
			return "先用污染过滤器稳定心棘残片；副产污染浆液会继续反哺井心分流栓组装，不需要引入第三台设备。"
		"quest.assemble_phase_well_shunt":
			return "井心分流栓会把心核分析产物和过滤结果重新变成开路物，决定井心室断面能否交出第一份相位井纺核。"
		"quest.inspect_phase_well_chamber":
			return "这一步要把基地组装的井心分流栓真正带回前线，让相位井心核后的更深收益继续落成实体战利品。"
		_:
			return "按当前目标推进；失败时查看日志和撤离反馈。"


func _is_slice_complete(world_state: WorldState) -> bool:
	return world_state.quest_state.unlocked_effects.has("slice_01_complete")


func _has_completed_deep_signal_analysis(world_state: WorldState) -> bool:
	return world_state.quest_state.has_completed_quest("quest.analyze_deep_signal")


func _has_completed_deep_ruin_entry(world_state: WorldState) -> bool:
	return world_state.quest_state.has_completed_quest("quest.unlock_deep_ruin_cache")


func _has_completed_second_deep_pass(world_state: WorldState) -> bool:
	return world_state.quest_state.has_completed_quest("quest.assemble_deep_signal_matrix")


func _has_completed_phase_relay_anchor(world_state: WorldState) -> bool:
	return world_state.quest_state.has_completed_quest("quest.deploy_phase_relay_anchor")


func _has_completed_phase_well_chamber(world_state: WorldState) -> bool:
	return world_state.quest_state.has_completed_quest("quest.inspect_phase_well_chamber")


func _has_completed_phase_well_sink(world_state: WorldState) -> bool:
	return world_state.quest_state.has_completed_quest("quest.inspect_phase_well_sink")


func _has_completed_phase_well_lock(world_state: WorldState) -> bool:
	return world_state.quest_state.has_completed_quest("quest.unlock_phase_well")


func _has_completed_phase_fault_spire(world_state: WorldState) -> bool:
	return world_state.quest_state.has_completed_quest("quest.inspect_phase_fault_spire")


func _has_completed_inner_phase_well(world_state: WorldState) -> bool:
	return world_state.quest_state.has_completed_quest("quest.inspect_inner_phase_well")


func _get_target_region_id(world_state: WorldState, quest_id: String) -> String:
	if target_region_resolver == null:
		return ""
	return target_region_resolver.resolve_target_region_id(world_state, quest_id)


func _append_runtime_hint_line(lines: Array[String], label: String, text: String) -> void:
	var stripped_text := text.strip_edges()
	if stripped_text.is_empty():
		return
	lines.append("%s：%s" % [label, stripped_text])
