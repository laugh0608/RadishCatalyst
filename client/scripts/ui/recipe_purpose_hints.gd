extends RefCounted
class_name RecipePurposeHints


static func format_recipe_goal_hint(recipe_id: String, world_state: WorldState = null) -> String:
	match recipe_id:
		"recipe.process_crystal_ore":
			return "把晶体矿物转成基础零件，支撑校准件、过滤模块、地基和补给。"
		"recipe.reclaim_basic_parts":
			return "把污染处理副产的污染浆液回收成基础零件，让副产物重新服务补给、地基、模块和稳相信标。"
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
			return _format_pollution_residue_goal_hint(world_state)
		"recipe.phase_anchor":
			return "把外圈继电残片、污染浆液和基础零件组装成稳相信标；缺零件时先回收一份浆液。"
		"recipe.core_stabilization_buffer":
			return "把修复凝胶、抗污染药剂、污染浆液和基础零件整成终点前缓冲包，降低核心守卫第一段回写压力。"
		"recipe.deep_signal_analysis":
			return "把外圈回波记录和污染处理副产整理成裂相坐标，做完返回封锁遗迹最东侧写入门禁。"
		"recipe.deep_core_imprint":
			return "把裂相样块解析成路由印片，做完直接返回裂相阵列台点亮第二轮导管回收线。"
		"recipe.deep_signal_matrix":
			return "把相位导管整理成深段读数矩阵，做完带回裂相脊固定点部署前线回传锚点。"
		"recipe.phase_splinter_refining":
			return "把回投后回收的裂相碎屑筛成透镜胚片，做完继续去基础反应器调准中继调谐镜。"
		"recipe.relay_tuning_lens":
			return "把透镜胚片调准成中继调谐镜，做完带回裂相尖塔逼出内层故障轨迹。"
		"recipe.inner_fault_analysis":
			return "把内层故障轨迹解析成坐标印片，做完返回更东侧裂相锁位继续推进。"
		"recipe.fault_residue_stabilization":
			return "把故障残渣稳定成故障芯，做完继续去基础反应器组装裂相锁钥。"
		"recipe.phase_well_key":
			return "把坐标印片和稳定故障芯组装成裂相锁钥，做完返回裂相锁位带回回声定位器。"
		"recipe.phase_well_locator_analysis":
			return "把回声定位器解析成回声路由片，做完继续推进更东侧回声台地。"
		"recipe.well_flux_stabilization":
			return "把回声碎屑稳定成稳流芯，做完继续去基础反应器组装回声探针。"
		"recipe.phase_well_probe":
			return "把回声路由片和稳流芯组装成回声探针，做完返回回声台地读取回声芯样本。"
		"recipe.phase_well_core_analysis":
			return "把回声芯样本解析成盐壳频谱片，做完继续推进更东侧盐壳浅滩。"
		"recipe.well_ash_stabilization":
			return "把盐壳余烬稳定成稳相格，做完继续去基础反应器组装盐壳穿钉。"
		"recipe.phase_well_pike":
			return "把盐壳频谱片和稳相格组装成盐壳穿钉，做完返回盐壳浅滩读取碎晶心核。"
		"recipe.phase_well_heart_analysis":
			return "把碎晶心核解析成碎晶脉搏片，做完继续推进更东侧碎晶沟谷。"
		"recipe.heart_spine_stabilization":
			return "把心棘残片稳定成碎晶抑振骨，做完继续去基础反应器组装碎晶分流栓。"
		"recipe.phase_well_shunt":
			return "把碎晶脉搏片和抑振骨组装成碎晶分流栓，做完返回碎晶沟谷读取风蚀张力核。"
		"recipe.phase_well_spindle_analysis":
			return "把风蚀张力核解析成风蚀经片，做完继续推进更东侧风蚀管廊。"
		"recipe.weft_bundle_stabilization":
			return "把纬束残团稳定成风蚀张力肋，做完继续去基础反应器组装风蚀梭栓。"
		"recipe.phase_well_shuttle":
			return "把风蚀经片和张力肋组装成风蚀梭栓，做完返回风蚀管廊读取锁相织构核。"
		"recipe.phase_well_weave_core_analysis":
			return "把锁相织构核解析成锁相纹谱片，做完继续推进更东侧锁相框架。"
		"recipe.selvedge_strip_stabilization":
			return "把边缕残条稳定成锁相框架肋，做完继续去基础反应器组装锁相键栓。"
		"recipe.phase_well_frame_key":
			return "把锁相纹谱片和框架肋组装成锁相键栓，做完返回锁相框架读取锚定结核。"
		"recipe.phase_well_knot_core_analysis":
			return "把锚定结核解析成锚定系谱片，做完去锚定桥检查两端结点并回收锚索残股。"
		"recipe.tether_fiber_stabilization":
			return "把锚索残股稳定成锚定系固肋，做完继续去基础反应器组装锚定桩。"
		"recipe.phase_well_tether_spike":
			return "把锚定系谱片和系固肋组装成锚定桩，做完返回锚定桥读取稳场锚核。"
		"recipe.phase_well_anchor_core_analysis":
			return "把稳场锚核解析成归谱片和锚核落尘，做完继续推进锚定桥东侧稳场任务。"
		"recipe.anchor_core_dust_stabilization":
			return "把锚核落尘稳定成稳场滤囊，做完继续去基础反应器组装稳场校锚桩。"
		"recipe.phase_well_anchor_stake":
			return "把归谱片和稳场滤囊组装成稳场校锚桩，做完返回锚场回稳窗部署。"
		"recipe.phase_well_echo_shard_analysis":
			return "把稳窗余响片解析成稳窗读数，做完先回锚场回稳窗确认前线回充，再按序校准稳窗节点。"
		"recipe.stability_echo_report":
			return "把稳窗回波样本解析成前线行动回报，做完回前线行动台确认补给短行动。"
		"recipe.short_action_feedback":
			return "把补给回执读数解析成短行动反馈记录，做完回前线行动台确认巡线短行动。"
		"recipe.route_action_feedback":
			return "把巡线信标读数解析成巡线反馈记录，做完回基地行动选择台，在稳场补给、相位测绘和压力清障之间做真实取舍。"
		"recipe.phase_survey_feedback":
			return "把两处相位测绘记录解析成路线提示收益，做完到前线行动台确认测绘路线整备槽。"
	return ""


static func _format_pollution_residue_goal_hint(world_state: WorldState = null) -> String:
	if world_state != null:
		if world_state.quest_state.has_active_quest("quest.assemble_phase_anchor"):
			return "把沉积物处理成药剂并留下污染浆液；药剂支撑遗迹外圈承压，浆液要留给稳相信标组装。"
		if world_state.quest_state.has_active_quest("quest.salvage_signal_echo") or world_state.quest_state.has_active_quest("quest.analyze_deep_signal"):
			return "把污染回波沉积处理成药剂并留下污染浆液；药剂支撑外圈承压，浆液要留给深段回波解析。"
		if world_state.quest_state.has_active_quest("quest.prepare_demo_stabilization_buffer"):
			return "把核心补料沉积处理成药剂并留下污染浆液；污染浆液要留给核心稳压缓冲包，药剂支撑核心站排压。"
	return "把沉积物处理成药剂并留下污染浆液；药剂支撑污染回访，浆液可回基础反应器回收成基础零件。"


static func format_build_goal_hint(building_id: String) -> String:
	match building_id:
		"building.basic_storage":
			return "接入前哨整备补给，外出消耗修复凝胶后回基地可补到 1 份。"
		"building.field_outfitting_station":
			return "把已制造模块装入防护服，让基地后勤直接改变外勤承压。"
		"building.foundation_t1":
			return "给污染过滤器提供落点；铺好两块后继续建造污染过滤器。"
		"building.pollution_filter":
			return "把污染沉积物处理成抗污染药剂，支撑再次深入污染边界。"
	return ""
