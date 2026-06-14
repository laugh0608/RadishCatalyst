extends RefCounted
class_name ProcessingRecipeHintFormatter


static func get_completion_next_step(recipe_id: String, world_state: WorldState = null) -> String:
	match recipe_id:
		"recipe.process_crystal_ore":
			if (
				world_state != null
				and FieldOutfittingRuntime.is_logistics_material_processed(world_state)
				and not FieldOutfittingRuntime.is_logistics_maintenance_confirmed(world_state)
			):
				return "后勤补料晶体已加工成基础零件；到出发整备台确认维护材料，再回前哨核心补给并从外勤出发口准备下一趟外勤。"
			if (
				world_state != null
				and FieldOutfittingRuntime.has_crystal_logistics_return_materials(world_state)
				and not FieldOutfittingRuntime.is_logistics_material_processed(world_state)
			):
				return "后勤补料材料已带回；完成这次基础零件加工后，到出发整备台确认维护材料。"
			return "基础零件已补足；它们会用于反应器校准、过滤模块和地基。若当前任务还差更高阶配方，可按 R 切换到目标配方。"
		"recipe.reclaim_basic_parts":
			if world_state != null and world_state.quest_state.has_active_quest("quest.enter_pollution_edge"):
				return "污染浆液已回收成基础零件；如果药剂或后续浆液不足，回污染边界副产口袋或药剂储备口袋补沉积物，再回过滤器处理。"
			if world_state != null and world_state.quest_state.has_active_quest("quest.unlock_ruin_signal"):
				return "污染浆液已回收成基础零件；带基础过滤模块和抗污染药剂回封锁入口确认信号。"
			if world_state != null and world_state.quest_state.has_active_quest("quest.assemble_phase_anchor"):
				return "污染浆液已回收成基础零件；继续确认稳相信标是否还留有组装用浆液，不足就回污染脊补沉积物再处理。"
			return "污染浆液已回收成基础零件；继续补给、地基或模块制造，副产物不再只是库存负担。"
		"recipe.reactor_calibrator":
			return "反应器采样通道已校准；前往异常晶体采样并回收周边残留物。"
		"recipe.analyze_anomaly_sample":
			return "样本过滤参数已确认；切换到过滤介质和基础过滤模块配方。"
		"recipe.make_filter_media":
			return "切换到基础过滤模块配方，把过滤介质和基础零件组装成远征模块。"
		"recipe.basic_filter_module":
			return "按 F 启用基础过滤模块；启用后污染消耗和污染反击压力降低，处理点北缘清障和沉积物采集会更稳。"
		"recipe.foundation_t1":
			return "前往污染边界北缘清理地块并铺设基础地基；若材料不足，回晶体矿脉区到处理点入口前补晶体或残骸。"
		"recipe.cleanse_residue":
			return _get_pollution_vial_completion_next_step(world_state)
		"recipe.repair_gel":
			return "把修复凝胶留在快捷栏 1，前往处理点北缘清障；生命偏低时按 1 使用。"
		"recipe.phase_anchor":
			return "带着稳相信标返回遗迹外圈，在抖动雾幕前部署后再继续深入。"
		"recipe.core_stabilization_buffer":
			return "核心稳压缓冲包已就绪；带回核心稳定站挑战阶段守卫，第一次回写压力会被缓冲包吸收一段。"
		"recipe.deep_signal_analysis":
			return "带着裂相坐标返回封锁遗迹最东侧，写入裂相脊入口门禁。"
		"recipe.phase_filament_refining":
			return "把谐振滤芯、副产污染浆液和基础零件送到基础反应器，组装裂相覆写栓。"
		"recipe.deep_override_key":
			return "带着裂相覆写栓返回裂相脊入口深处，覆写锁扣并取出样块。"
		"recipe.deep_core_imprint":
			return "带着裂相路由印片返回裂相阵列台，点亮第二轮导管回收线。"
		"recipe.deep_signal_matrix":
			return "深段第二轮读数已整理完成；返回深段固定点部署前线回传锚点，并准备从回投台重返前线。"
		"recipe.phase_splinter_refining":
			return "透镜胚片和副产污染浆液已筛出；继续这次远征整备，回基地基础反应器调准中继调谐镜。"
		"recipe.relay_tuning_lens":
			return "带着中继调谐镜返回更东侧裂相尖塔，逼出第一份内层故障轨迹。"
		"recipe.inner_fault_analysis":
			return "裂相坐标印片已整理完成；返回裂相尖塔更东侧，击退潜猎体并回收故障残渣。"
		"recipe.fault_residue_stabilization":
			return "稳定故障芯和副产污染浆液已筛出；继续这次裂相锁位整备，回基地基础反应器组装裂相锁钥。"
		"recipe.phase_well_key":
			return "带着裂相锁钥返回更东侧裂相锁位，钉住锁位并带回第一份定位器。"
		"recipe.phase_well_locator_analysis":
			return "回声路由片已整理完成；继续向东进入新暴露的回声台地边缘，先处理两处回声泄压阀，再击退哨戒体并回收回声碎屑。"
		"recipe.well_flux_stabilization":
			return "稳流芯和副产污染浆液已筛出；继续这次探针整备，回基地基础反应器组装回声探针。"
		"recipe.phase_well_probe":
			return "带着回声探针返回更东侧回声台地，读取第一份回声芯样本。"
		"recipe.phase_well_core_analysis":
			return "盐壳频谱片已整理完成；继续向东进入新暴露的盐壳浅滩边缘，先清掉两处盐壳硬壳，再击退潜伏体并回收盐壳余烬。"
		"recipe.well_ash_stabilization":
			return "稳相格和副产污染浆液已筛出；继续这次盐壳整备，回基地基础反应器组装盐壳穿钉。"
		"recipe.phase_well_pike":
			return "带着盐壳穿钉返回更东侧盐壳浅滩，凿开裂口并带回第一份碎晶心核。"
		"recipe.phase_well_heart_analysis":
			return "碎晶脉搏片已整理完成；继续向东进入新暴露的碎晶沟谷边缘，先写入两处碎晶分流读数，再击退撕裂体并回收心棘残片。"
		"recipe.heart_spine_stabilization":
			return "抑振骨和副产污染浆液已筛出；继续这次碎晶整备，回基地基础反应器组装碎晶分流栓。"
		"recipe.phase_well_shunt":
			return "带着碎晶分流栓返回更东侧碎晶沟谷断面，勘验断面并带回第一份风蚀张力核。"
		"recipe.phase_well_spindle_analysis":
			return "风蚀经片已整理完成；继续向东进入新暴露的风蚀管廊边缘，先检查两处风蚀张力绕轮，再击退纠缠体并回收纬束残团。"
		"recipe.weft_bundle_stabilization":
			return "张力肋和副产污染浆液已筛出；继续这次风蚀整备，回基地基础反应器组装风蚀梭栓。"
		"recipe.phase_well_shuttle":
			return "带着风蚀梭栓返回更东侧风蚀管廊断面，勘验断面并带回第一份锁相织构核。"
		"recipe.phase_well_weave_core_analysis":
			return "锁相纹谱片已整理完成；继续向东进入新暴露的锁相框架边缘，先清理一条锁相侧路障，再击退锁相刮裂体并回收边缕残条。"
		"recipe.selvedge_strip_stabilization":
			return "锁相框架肋和副产污染浆液已筛出；继续这次锁相框架整备，回基地基础反应器组装锁相键栓。"
		"recipe.phase_well_frame_key":
			return "带着锁相键栓返回更东侧锁相框架断面，勘验断面并带回第一份锚定结核。"
		"recipe.phase_well_knot_core_analysis":
			return "锚定系谱片已整理完成；继续向东进入新暴露的锚定桥边缘，先检查两处锚定桥结点，再击退锚定缚结体并回收锚索残股。"
		"recipe.tether_fiber_stabilization":
			return "锚定系固肋和副产污染浆液已筛出；继续这次锚定桥整备，回基地基础反应器组装锚定桩。"
		"recipe.phase_well_tether_spike":
			return "带着锚定桩返回更东侧锚定桥断面，勘验断面并带回第一份稳场锚核。"
		"recipe.phase_well_anchor_core_analysis":
			return "归谱片和锚核落尘已整理完成；先回处理点污染过滤器稳定锚核落尘，再回基地组装稳场校锚桩。"
		"recipe.anchor_core_dust_stabilization":
			return "稳场滤囊和副产污染浆液已筛出；继续这次锚场整备，回基地基础反应器组装稳场校锚桩。"
		"recipe.phase_well_anchor_stake":
			return "带着稳场校锚桩返回锚定桥东侧锚场回稳窗，部署后先清两处压力钉，再压制稳场守脉体并收束稳窗余响片。"
		"recipe.phase_well_echo_shard_analysis":
			return "稳窗读数已整理完成；先回锚场回稳窗确认前线回充，再按西侧、中央、东侧顺序校准三处稳窗节点。"
		"recipe.stability_echo_report":
			return "前线行动回报已归档；回基地前线行动台确认补给短行动，本趟只派发补给回执标记。"
		"recipe.short_action_feedback":
			return "短行动反馈已归档；第二条基地确认、前线短目标、回基地反馈闭环已完成，回前线行动台确认巡线短行动，本趟只派发巡线信标。"
		"recipe.route_action_feedback":
			return "巡线反馈已归档；回基地行动选择台，在稳场补给、相位测绘和压力清障之间选择下一趟短行动。"
		"recipe.steady_supply_feedback":
			return "稳场补给反馈已归档；低风险补给选择已经跑通一轮基地选择、前线目标和返回收益。"
		"recipe.phase_survey_feedback":
			return "相位测绘反馈已归档；侦测选择已经跑通一轮基地选择、两处前线读数和返回收益，下一步到前线行动台确认测绘路线整备槽。"
		"recipe.pressure_clearance_feedback":
			return "压力清障反馈已归档；高风险清障选择已经跑通一轮基地选择、前线清障和返回收益。"
		_:
			return "查看当前任务目标，选择下一次加工或外出行动。"


static func get_processing_started_appendix(recipe_id: String, world_state: WorldState = null) -> String:
	match recipe_id:
		"recipe.cleanse_residue":
			return _get_pollution_residue_processing_started_appendix(world_state)
		_:
			return ""


static func should_return_for_second_pollution_residue_batch(world_state: WorldState) -> bool:
	if world_state == null:
		return false
	if not world_state.quest_state.has_active_quest("quest.enter_pollution_edge"):
		return false
	return world_state.quest_state.get_objective_progress("quest.enter_pollution_edge", "gather_item", "item.polluted_residue") < 4.0


static func _get_pollution_residue_processing_started_appendix(world_state: WorldState = null) -> String:
	if world_state != null:
		if _is_logistics_maintenance_retest_context(world_state):
			return "本次会把后勤维护复测沉积转成抗污染药剂和污染浆液；完成后回前哨核心补给，多余污染浆液可回基地基础反应器回收基础零件。"
		if _is_core_archive_pressure_retest_context(world_state):
			return "本次会把复测压力沉积转成抗污染药剂和污染浆液；完成后回前哨核心补药剂，多余污染浆液可回基地基础反应器回收基础零件。"
		if _is_core_archive_return_residue_context(world_state):
			return "本次会把归档维护回访沉积转成抗污染药剂和污染浆液；完成后回前哨核心补满药剂，再从外勤出发口复测核心稳定站。"
		if world_state.quest_state.has_active_quest("quest.assemble_phase_anchor"):
			return "本次会产出抗污染药剂并留下污染浆液；完成后回基地基础反应器组装稳相信标，药剂留给遗迹外圈承压。"
		if world_state.quest_state.has_active_quest("quest.salvage_signal_echo"):
			return "本次会产出抗污染药剂并留下污染浆液；浆液保留给深段回波解析，药剂留给外圈继续承压。"
		if world_state.quest_state.has_active_quest("quest.prepare_demo_stabilization_buffer"):
			return "本次会产出抗污染药剂并留下污染浆液；完成后回基础反应器整备核心稳压缓冲包，药剂留给核心站排压。"
	if should_return_for_second_pollution_residue_batch(world_state):
		return "本次会产出抗污染药剂并留下污染浆液；完成后带药剂回污染边界，清理受扰敌人和门前压力点。"
	return ""


static func _get_pollution_vial_completion_next_step(world_state: WorldState = null) -> String:
	if world_state != null:
		if _is_logistics_maintenance_retest_context(world_state):
			return "后勤维护复测沉积已处理成抗污染药剂和污染浆液；回前哨核心把药剂补到 %s，再确认下一趟外勤准备。" % _format_resistance_vial_target(world_state)
		if _is_core_archive_pressure_retest_context(world_state):
			return "复测压力沉积已处理成抗污染药剂和污染浆液；回前哨核心把药剂补到 %s，再把多余污染浆液回基础反应器回收基础零件。" % _format_resistance_vial_target(world_state)
		if _is_core_archive_return_residue_context(world_state):
			return "归档维护回访沉积已处理成抗污染药剂和污染浆液；回前哨核心把抗污染药剂补到 %s，再从外勤出发口复测核心稳定站或回污染边界确认承压。" % _format_resistance_vial_target(world_state)
		if world_state.quest_state.has_active_quest("quest.assemble_phase_anchor"):
			return "污染浆液已就绪；回基地基础反应器组装稳相信标，抗污染药剂留给遗迹外圈承压。"
		if world_state.quest_state.has_active_quest("quest.salvage_signal_echo"):
			return "污染回波沉积已处理成药剂和污染浆液；浆液就是深段回波解析输入，回外圈回收回波匣后再回基地解析裂相坐标。"
		if world_state.quest_state.has_active_quest("quest.prepare_demo_stabilization_buffer"):
			return "核心缓冲补料已处理成药剂和污染浆液；回基础反应器整备核心稳压缓冲包，药剂留给核心站排压。"
	if should_return_for_second_pollution_residue_batch(world_state):
		return "带药剂回污染边界，补第二批沉积物，清理受扰敌人和门前压力点；抗污染药剂留在快捷栏 2。"
	return "带药剂回污染边界，清理受扰敌人和门前压力点；抗污染药剂留在快捷栏 2，用于维持遗迹门前防护。"


static func _is_core_archive_return_residue_context(world_state: WorldState) -> bool:
	return (
		world_state != null
		and world_state.quest_state.has_completed_quest("quest.write_demo_stabilization_core")
		and FieldOutfittingRuntime.is_core_archive_maintained(world_state)
		and (
			bool(
				world_state.get_map_object(
					"map_object_instance.pollution_residue_core_archive_route_cache"
				).get("is_gathered", false)
			)
			or bool(
				world_state.get_map_object(
					"map_object_instance.pollution_residue_core_archive_return_cache"
				).get("is_gathered", false)
			)
		)
	)


static func _is_logistics_maintenance_retest_context(world_state: WorldState) -> bool:
	return (
		world_state != null
		and CoreStabilizationPressureFormatter.is_logistics_maintenance_retest_available(world_state)
		and CoreStabilizationPressureFormatter.has_logistics_maintenance_retest_residue(world_state)
	)


static func _is_core_archive_pressure_retest_context(world_state: WorldState) -> bool:
	return (
		world_state != null
		and world_state.quest_state.has_completed_quest("quest.write_demo_stabilization_core")
		and FieldOutfittingRuntime.is_core_archive_maintained(world_state)
		and bool(
			world_state.get_map_object(
				"map_object_instance.pollution_residue_core_archive_pressure_retest_cache"
			).get("is_gathered", false)
		)
	)


static func _format_resistance_vial_target(world_state: WorldState) -> String:
	var target := DepartureSupplyRuntime.get_resistance_vial_target(world_state)
	if target > DepartureSupplyRuntime.BASIC_RESISTANCE_VIAL_TARGET:
		return "%d/%d" % [target, target]
	return "满"
