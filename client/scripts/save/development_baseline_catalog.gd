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
	},
	{
		"id": "baseline.s6_inner_fault_trace_ready",
		"code": "S6",
		"display_name": "S6 内层故障轨迹已回收",
		"completed_through": "quest.inspect_phase_fault_spire",
		"summary": "裂相尖塔已校准，第一份内层故障轨迹已带回，下一步回基地解析并继续推进相位井锁。",
		"recommended_for": "内层故障轨迹解析、故障残渣回收、相位井钥组装、相位井锁与旧存档兼容回归。"
	},
	{
		"id": "baseline.s7_phase_well_locator_ready",
		"code": "S7",
		"display_name": "S7 相位井定位器已带回",
		"completed_through": "quest.unlock_phase_well",
		"summary": "相位井锁已钉住，定位器已带回，下一步回基地解析并推进更东侧内层相位井。",
		"recommended_for": "定位器解析、井涌碎屑回收、探针整备、内层相位井与旧存档兼容回归。"
	},
	{
		"id": "baseline.s8_phase_well_core_ready",
		"code": "S8",
		"display_name": "S8 相位井芯样本已带回",
		"completed_through": "quest.inspect_inner_phase_well",
		"summary": "内层相位井已勘验，井芯样本已带回，下一步回基地解析并推进更东侧井底裂口。",
		"recommended_for": "井芯样本解析、井壁余烬回收、稳相格处理、井底穿钉、井底裂口与旧存档兼容回归。"
	},
	{
		"id": "baseline.s9_phase_well_heart_ready",
		"code": "S9",
		"display_name": "S9 相位井心核已带回",
		"completed_through": "quest.inspect_phase_well_sink",
		"summary": "井底裂口已凿开，相位井心核已带回，下一步回基地解析并推进更东侧井心室断面。",
		"recommended_for": "相位井心核解析、心棘残片回收、抑振骨处理、井心分流栓、井心室断面与旧存档兼容回归。"
	},
	{
		"id": "baseline.s10_phase_well_spindle_ready",
		"code": "S10",
		"display_name": "S10 相位井纺核已带回",
		"completed_through": "quest.inspect_phase_well_chamber",
		"summary": "井心室断面已勘验，相位井纺核已带回，下一步回基地解析并推进更东侧井纺室断面。",
		"recommended_for": "相位井纺核解析、纬束残团回收、张力肋处理、井纺梭栓、井纺室断面与第二回投锚点兼容回归。"
	},
	{
		"id": "baseline.s11_phase_well_weave_core_ready",
		"code": "S11",
		"display_name": "S11 相位井织核已带回",
		"completed_through": "quest.inspect_phase_well_loom",
		"summary": "井纺室断面已勘验，相位井织核已带回，下一步回基地解析并推进更东侧井纹架断面。",
		"recommended_for": "相位井织核解析、边缕残条回收、纹架肋处理、井纹架键栓、井纹架断面与第二回投锚点兼容回归。"
	},
	{
		"id": "baseline.s12_phase_well_knot_core_ready",
		"code": "S12",
		"display_name": "S12 相位井结核已带回",
		"completed_through": "quest.inspect_phase_well_frame",
		"summary": "井纹架断面已勘验，相位井结核已带回，下一步回基地解析并推进更东侧井系桥断面。",
		"recommended_for": "相位井结核解析、系索残股回收、系固肋处理、井系定桩和井系桥断面与第二回投锚点兼容回归。"
	},
	{
		"id": "baseline.s13_phase_well_anchor_core_ready",
		"code": "S13",
		"display_name": "S13 相位井锚核已带回",
		"completed_through": "quest.inspect_phase_well_tether",
		"summary": "井系桥断面已勘验，相位井锚核已带回，下一步回基地解析并把井系桥东侧改造成锚场回稳窗口。",
		"recommended_for": "相位井锚核解析、锚核落尘稳定、井系校锚桩组装、锚场回稳短守场与稳定窗口提示回归。"
	},
	{
		"id": "baseline.s14_phase_well_anchor_field_stabilized",
		"code": "S14",
		"display_name": "S14 锚场回稳已完成",
		"completed_through": "quest.stabilize_phase_well_anchor_field",
		"summary": "井系桥东侧锚场回稳已完成，稳定窗口已生成，相位井余响片已带回。",
		"recommended_for": "锚场完成态、局部稳定窗口收益、相位井余响片后续设计和下一包入口判断。"
	},
	{
		"id": "baseline.s15_phase_well_stability_readout_ready",
		"code": "S15",
		"display_name": "S15 稳窗读数已解析",
		"completed_through": "quest.analyze_phase_well_echo_shard",
		"summary": "相位井余响片已解析成稳窗读数，下一步返回锚场按现场相位序校准三处节点。",
		"recommended_for": "稳窗读数完成态、现场校准目标、锚场回访回充和前线容错反馈回归。"
	},
	{
		"id": "baseline.s16_phase_well_stability_window_calibrated",
		"code": "S16",
		"display_name": "S16 稳窗相位序已校准",
		"completed_through": "quest.calibrate_phase_well_stability_window",
		"summary": "西侧、中央和东侧三处稳窗校准点已按顺序写入，现场校准模板完成。",
		"recommended_for": "现场校准完成态、局部定序目标、前线容错收益和阶段收口判断。"
	},
	{
		"id": "baseline.s17_frontline_action_report_ready",
		"code": "S17",
		"display_name": "S17 前线行动回报已归档",
		"completed_through": "quest.analyze_stability_echo_sample",
		"summary": "基地前线行动台、稳窗回波探点和回报解析已跑通第一条最短闭环。",
		"recommended_for": "基地选择、前线行动、返回解析和下一组核心循环入口判断。"
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
