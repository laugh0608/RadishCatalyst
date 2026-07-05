extends RefCounted
class_name DevelopmentBaselineCatalog

const DEMO_BASELINE_IDS: Array[String] = [
	"baseline.s0_new_game",
	"baseline.s2_outer_ring_secured",
	"baseline.s21_demo_stabilization_core_ready",
	"baseline.s22_demo_completion_outpost_review"
]
const DEFAULT_DEMO_BASELINE_ID := "baseline.s2_outer_ring_secured"
const VISUAL_REVIEW_CHECKPOINT_IDS: Array[String] = [
	"visual_review.outpost_base",
	"visual_review.crystal_mine",
	"visual_review.crystal_collector_output",
	"visual_review.base_handoff",
	"visual_review.pollution_boundary",
	"visual_review.core_station"
]
const DEFAULT_VISUAL_REVIEW_CHECKPOINT_ID := "visual_review.outpost_base"

const VISUAL_REVIEW_CHECKPOINT_DEFINITIONS := [
	{
		"id": "visual_review.outpost_base",
		"code": "V0",
		"display_name": "基地首屏",
		"baseline_id": "baseline.s0_new_game",
		"region_id": "region.outpost_platform",
		"position": Vector2(-250.0, -48.0),
		"summary": "前哨核心、基础反应器、储存、整备台和出发门。",
		"watch": "观察基地设备轮廓、地面格栅、维护线和工业链输入 / 输出是否清楚。"
	},
	{
		"id": "visual_review.crystal_mine",
		"code": "V1",
		"display_name": "晶体矿脉",
		"baseline_id": "baseline.s1_treatment_ready",
		"region_id": "region.crystal_vein_field",
		"position": Vector2(150.0, -176.0),
		"summary": "可采集矿面、富矿脊线、残骸回收场和回基地装车轨。",
		"watch": "观察晶体区是否像资源场，而不是蓝色大块和旧交互标记。"
	},
	{
		"id": "visual_review.crystal_collector_output",
		"code": "V1A",
		"display_name": "采集器输出",
		"baseline_id": "baseline.s0_new_game",
		"region_id": "region.crystal_vein_field",
		"position": Vector2(96.0, -118.0),
		"summary": "手持采样、基础晶体采集器、输出托盘和回基地装车口。",
		"watch": "观察采集器建成后矿面、输出托盘和回基地物流端口是否能读出。"
	},
	{
		"id": "visual_review.base_handoff",
		"code": "V1B",
		"display_name": "入库整备交接",
		"baseline_id": "baseline.s0_new_game",
		"region_id": "region.outpost_platform",
		"position": Vector2(-118.0, -24.0),
		"summary": "采集器产物回基地后进入反应器、储存箱和出发整备台交接。",
		"watch": "观察收料、反应器进料、产物入库和出发整备端口是否连成同一段路径。"
	},
	{
		"id": "visual_review.pollution_boundary",
		"code": "V2",
		"display_name": "污染边界",
		"baseline_id": "baseline.s1_treatment_ready",
		"region_id": "region.pollution_edge",
		"position": Vector2(298.0, -72.0),
		"summary": "污染沉积、危险边界、过滤施工、处理输入 / 输出和回收现场。",
		"watch": "观察污染区是否像处理边界和回收现场，而不是黄绿色旧色块。"
	},
	{
		"id": "visual_review.pollution_short_challenge",
		"code": "V2A",
		"display_name": "污染整备短挑战",
		"baseline_id": "baseline.s1_treatment_ready",
		"region_id": "region.pollution_edge",
		"position": Vector2(298.0, 24.0),
		"summary": "过滤模块、抗污染药剂、修复凝胶、压力门短路线、局部受扰敌人和沉积物回收交接。",
		"watch": "观察整备检查位、短战斗口袋和沉积物回过滤器是否能直接读成污染边界短挑战。"
	},
	{
		"id": "visual_review.core_station",
		"code": "V3",
		"display_name": "核心稳定站",
		"baseline_id": "baseline.s21_demo_stabilization_core_ready",
		"region_id": "region.demo_stabilization_core",
		"position": Vector2(3744.0, 112.0),
		"summary": "终点入口、侧边补给、守卫压力场、回写缓存和核心写入装置。",
		"watch": "观察终点工程现场是否成立，后续视觉第二轮优先看这里。"
	}
]

const BASELINE_DEFINITIONS := [
	{
		"id": "baseline.s0_new_game",
		"code": "S0",
		"display_name": "S0 新档",
		"completed_through": "",
		"summary": "从恢复前哨开始，覆盖完整冷启动主线。",
		"recommended_for": "全链路空档复测、早期目标理解、共享系统回归。",
		"demo_baseline_order": 1,
		"demo_baseline_focus": "冷启动回基地、制造和再次外出判断。",
		"demo_baseline_watch": "观察首屏 HUD、前哨核心、晶体区和处理点入口。"
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
		"recommended_for": "外圈回波匣、深段回波、基地解析与第二闭环入口回归。",
		"demo_baseline_order": 2,
		"demo_baseline_focus": "外圈承压、沉积过滤和污染浆液去向。",
		"demo_baseline_watch": "观察是否知道先处理沉积物，再带污染浆液回基地解析。"
	},
	{
		"id": "baseline.s3_deep_entrance_open",
		"code": "S3",
		"display_name": "S3 裂相脊入口已开",
		"completed_through": "quest.unlock_deep_ruin_entrance",
		"summary": "裂相坐标已写入，下一步进入裂相脊入口回收相位纤丝。",
		"recommended_for": "裂相脊入口、相位纤丝回收、过滤器精炼和覆写栓链路回归。"
	},
	{
		"id": "baseline.s4_deep_cache_open",
		"code": "S4",
		"display_name": "S4 裂相样块已回收",
		"completed_through": "quest.unlock_deep_ruin_cache",
		"summary": "裂相样块已带回，下一步在基地解析并进入第二轮阵列线。",
		"recommended_for": "裂相样块解析、阵列点亮、追袭体与相位导管链路回归。"
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
		"summary": "裂相尖塔已校准，第一份内层故障轨迹已带回，下一步回基地解析并继续推进裂相锁位。",
		"recommended_for": "内层故障轨迹解析、故障残渣回收、裂相锁钥组装、裂相锁位与旧存档兼容回归。"
	},
	{
		"id": "baseline.s7_phase_well_locator_ready",
		"code": "S7",
		"display_name": "S7 回声定位器已带回",
		"completed_through": "quest.unlock_phase_well",
		"summary": "裂相锁位已钉住，定位器已带回，下一步回基地解析并推进更东侧回声台地。",
		"recommended_for": "定位器解析、回声碎屑回收、探针整备、回声台地与旧存档兼容回归。"
	},
	{
		"id": "baseline.s8_phase_well_core_ready",
		"code": "S8",
		"display_name": "S8 回声芯样本已带回",
		"completed_through": "quest.inspect_inner_phase_well",
		"summary": "回声台地已勘验，回声芯样本已带回，下一步回基地解析并推进更东侧盐壳浅滩。",
		"recommended_for": "回声芯样本解析、盐壳余烬回收、稳相格处理、盐壳穿钉、盐壳浅滩与旧存档兼容回归。"
	},
	{
		"id": "baseline.s9_phase_well_heart_ready",
		"code": "S9",
		"display_name": "S9 碎晶心核已带回",
		"completed_through": "quest.inspect_phase_well_sink",
		"summary": "盐壳浅滩已凿开，碎晶心核已带回，下一步回基地解析并推进更东侧碎晶沟谷断面。",
		"recommended_for": "碎晶心核解析、心棘残片回收、抑振骨处理、碎晶分流栓、碎晶沟谷断面与旧存档兼容回归。"
	},
	{
		"id": "baseline.s10_phase_well_spindle_ready",
		"code": "S10",
		"display_name": "S10 风蚀张力核已带回",
		"completed_through": "quest.inspect_phase_well_chamber",
		"summary": "碎晶沟谷断面已勘验，风蚀张力核已带回，下一步回基地解析并推进更东侧风蚀管廊断面。",
		"recommended_for": "风蚀张力核解析、纬束残团回收、张力肋处理、风蚀梭栓、风蚀管廊断面与第二回投锚点兼容回归。"
	},
	{
		"id": "baseline.s11_phase_well_weave_core_ready",
		"code": "S11",
		"display_name": "S11 锁相织构核已带回",
		"completed_through": "quest.inspect_phase_well_loom",
		"summary": "风蚀管廊断面已勘验，锁相织构核已带回，下一步回基地解析并推进更东侧锁相框架断面。",
		"recommended_for": "锁相织构核解析、边缕残条回收、纹架肋处理、锁相键栓、锁相框架断面与第二回投锚点兼容回归。"
	},
	{
		"id": "baseline.s12_phase_well_knot_core_ready",
		"code": "S12",
		"display_name": "S12 锚定结核已带回",
		"completed_through": "quest.inspect_phase_well_frame",
		"summary": "锁相框架断面已勘验，锚定结核已带回，下一步回基地解析并推进更东侧锚定桥断面。",
		"recommended_for": "锚定结核解析、锚索残股回收、系固肋处理、锚定桩和锚定桥断面与第二回投锚点兼容回归。"
	},
	{
		"id": "baseline.s13_phase_well_anchor_core_ready",
		"code": "S13",
		"display_name": "S13 稳场锚核已带回",
		"completed_through": "quest.inspect_phase_well_tether",
		"summary": "锚定桥断面已勘验，稳场锚核已带回，下一步回基地解析并把锚定桥东侧改造成锚场回稳窗口。",
		"recommended_for": "稳场锚核解析、锚核落尘稳定、稳场校锚桩组装、锚场回稳短守场与稳定窗口提示回归。"
	},
	{
		"id": "baseline.s14_phase_well_anchor_field_stabilized",
		"code": "S14",
		"display_name": "S14 锚场回稳已完成",
		"completed_through": "quest.stabilize_phase_well_anchor_field",
		"summary": "锚定桥东侧锚场回稳已完成，稳定窗口已生成，稳窗余响片已带回。",
		"recommended_for": "锚场完成态、局部稳定窗口收益、稳窗余响片后续设计和下一包入口判断。"
	},
	{
		"id": "baseline.s15_phase_well_stability_readout_ready",
		"code": "S15",
		"display_name": "S15 稳窗读数已解析",
		"completed_through": "quest.analyze_phase_well_echo_shard",
		"summary": "稳窗余响片已解析成稳窗读数，下一步返回锚场按现场相位序校准三处节点。",
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
		"summary": "基地前线行动台、稳窗回波探点、回报解析和短行动补给收益已跑通第一条最短闭环，下一步确认补给短行动。",
		"recommended_for": "第一条轻量前线行动完成态、短行动补给收益和第二条行动入口判断。"
	},
	{
		"id": "baseline.s18_short_action_feedback_ready",
		"code": "S18",
		"display_name": "S18 短行动反馈已归档",
		"completed_through": "quest.analyze_supply_return_trace",
		"summary": "短行动补给台、锚定桥补给回执标记、回执解析和第二次基地反馈已跑通，下一步确认巡线短行动。",
		"recommended_for": "第二条轻量前线行动完成态、巡线行动入口和核心循环可延展性回归。"
	},
	{
		"id": "baseline.s19_route_action_feedback_ready",
		"code": "S19",
		"display_name": "S19 巡线反馈已归档",
		"completed_through": "quest.analyze_route_signal_trace",
		"summary": "巡线短行动台、锚定桥巡线信标、信标解析和第三次基地反馈已跑通，基地行动选择入口已激活。",
		"recommended_for": "第三条轻量前线行动完成态、稳场补给 / 相位测绘二选一入口和选择前提示回归。"
	},
	{
		"id": "baseline.s20_phase_survey_feedback_ready",
		"code": "S20",
		"display_name": "S20 相位测绘反馈已归档",
		"completed_through": "quest.analyze_phase_survey_trace",
		"summary": "基地选择相位测绘后，锚定桥前线两处测绘点和返回解析已跑通第一轮行动选择闭环。",
		"recommended_for": "基地行动二选一、相位测绘目标差异、测绘反馈收益和 S19 后新循环验收。"
	},
	{
		"id": "baseline.s21_demo_stabilization_core_ready",
		"code": "S21",
		"display_name": "S21 核心稳定站已开放",
		"completed_through": "quest.analyze_phase_survey_trace",
		"summary": "高压窗口稳定数据已归档，核心稳定站已解锁，下一步从锚定桥进入核心稳定站。",
		"recommended_for": "核心稳定站局部开发复测、阶段守卫、侧向补给缓存、核心设备写入和 demo 完成反馈。",
		"demo_baseline_order": 3,
		"demo_baseline_focus": "侧边补给、缓冲包和三档写入承压。",
		"demo_baseline_watch": "观察阶段守卫后是否理解先整备再写入，或直接写入的代价。"
	},
	{
		"id": "baseline.s22_demo_completion_outpost_review",
		"code": "S22",
		"display_name": "S22 Demo 完成后前哨整理",
		"completed_through": "quest.analyze_phase_survey_trace",
		"summary": "核心稳定站已写入完成，玩家已回到前哨整理补给、整备收益和复测记录。",
		"recommended_for": "Demo 完成后成果整理、HUD / 地图 / 前哨核心读法、存档读取后状态回归。",
		"demo_baseline_order": 4,
		"demo_baseline_focus": "完成后回前哨整理，而不是开启新章节或结算页。",
		"demo_baseline_watch": "观察 HUD、地图和前哨核心是否仍能读出 Demo 已完成与成果整理方向。"
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


static func get_demo_baseline_ids() -> Array[String]:
	return DEMO_BASELINE_IDS.duplicate()


static func get_visual_review_checkpoint_definitions() -> Array[Dictionary]:
	var definitions: Array[Dictionary] = []
	for checkpoint_id in VISUAL_REVIEW_CHECKPOINT_IDS:
		var checkpoint_definition := get_visual_review_checkpoint_definition(checkpoint_id)
		if not checkpoint_definition.is_empty():
			definitions.append(checkpoint_definition)
	return definitions


static func get_visual_review_checkpoint_ids() -> Array[String]:
	return VISUAL_REVIEW_CHECKPOINT_IDS.duplicate()


static func get_visual_review_checkpoint_definition(checkpoint_id: String) -> Dictionary:
	for definition in VISUAL_REVIEW_CHECKPOINT_DEFINITIONS:
		var candidate: Dictionary = definition
		if String(candidate.get("id", "")) == checkpoint_id:
			return candidate.duplicate(true)
	return {}


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


static func get_default_demo_baseline_id() -> String:
	return DEFAULT_DEMO_BASELINE_ID


static func get_default_visual_review_checkpoint_id() -> String:
	return DEFAULT_VISUAL_REVIEW_CHECKPOINT_ID
