extends RefCounted
class_name VerticalSliceMapSurface

const CRYSTAL_REGION_X := -20.0
const CRYSTAL_GATE_RETURN_X := -35.0
const POLLUTION_REGION_X := 240.0
const POLLUTION_DEEP_Y := -40.0
const POLLUTION_GATE_RETURN_X := 235.0
const RUIN_OUTER_RING_X := 390.0
const RUIN_GATE_RETURN_X := 355.0
const OUTER_RING_BARRIER_X := 540.0
const OUTER_RING_BARRIER_RETURN_X := 514.0
const DEEP_RUIN_REGION_X := 700.0
const INNER_PHASE_WELL_REGION_X := 1460.0
const PHASE_WELL_SINK_REGION_X := 1760.0
const PHASE_WELL_CHAMBER_REGION_X := 2040.0
const PHASE_WELL_LOOM_REGION_X := 2320.0
const PHASE_WELL_FRAME_REGION_X := 2600.0
const PHASE_WELL_TETHER_REGION_X := 2880.0
const DEMO_STABILIZATION_CORE_REGION_X := 3640.0
const DEEP_RUIN_GATE_RETURN_X := 676.0
const INNER_PHASE_WELL_GATE_RETURN_X := 1432.0
const PHASE_WELL_SINK_GATE_RETURN_X := 1732.0
const PHASE_WELL_CHAMBER_GATE_RETURN_X := 2012.0
const PHASE_WELL_LOOM_GATE_RETURN_X := 2292.0
const PHASE_WELL_FRAME_GATE_RETURN_X := 2572.0
const PHASE_WELL_TETHER_GATE_RETURN_X := 2852.0
const DEMO_STABILIZATION_CORE_GATE_RETURN_X := 3612.0
const PHASE_RELAY_PAD_FALLBACK_POSITION := Vector2(-210, -40)
const PHASE_RETURN_ANCHOR_FALLBACK_POSITION := Vector2(852, 92)


static func get_region_id_for_position(map_position: Vector2) -> String:
	if map_position.x >= DEMO_STABILIZATION_CORE_REGION_X:
		return "region.demo_stabilization_core"
	if map_position.x >= PHASE_WELL_TETHER_REGION_X:
		return "region.phase_well_tether"
	if map_position.x >= PHASE_WELL_FRAME_REGION_X:
		return "region.phase_well_frame"
	if map_position.x >= PHASE_WELL_LOOM_REGION_X:
		return "region.phase_well_loom"
	if map_position.x >= PHASE_WELL_CHAMBER_REGION_X:
		return "region.phase_well_chamber"
	if map_position.x >= PHASE_WELL_SINK_REGION_X:
		return "region.phase_well_sink"
	if map_position.x >= INNER_PHASE_WELL_REGION_X:
		return "region.inner_phase_well"
	if map_position.x >= DEEP_RUIN_REGION_X:
		return "region.deep_ruin_threshold"
	if map_position.x >= RUIN_OUTER_RING_X:
		return "region.ruin_outer_ring"
	if map_position.x >= POLLUTION_REGION_X and map_position.y >= POLLUTION_DEEP_Y:
		return "region.pollution_edge"
	if map_position.x >= CRYSTAL_REGION_X:
		return "region.crystal_vein_field"
	return "region.outpost_platform"


static func resolve_region_gate_block(world_state: WorldState, map_position: Vector2) -> Dictionary:
	if not world_state.unlocked_region_ids.has("region.crystal_vein_field") and map_position.x > CRYSTAL_GATE_RETURN_X:
		return _gate_block(
			CRYSTAL_GATE_RETURN_X,
			map_position,
			"晶体矿脉区尚未标记：先检查前哨核心，恢复基础导航。"
		)

	if (
		not world_state.unlocked_region_ids.has("region.pollution_edge")
		and map_position.x > POLLUTION_GATE_RETURN_X
		and map_position.y >= POLLUTION_DEEP_Y
	):
		return _gate_block(
			POLLUTION_GATE_RETURN_X,
			map_position,
			"污染边界尚未稳定：先扩建处理点并启用基础过滤模块。"
		)

	if not world_state.unlocked_region_ids.has("region.ruin_outer_ring") and map_position.x > RUIN_GATE_RETURN_X:
		return _gate_block(
			RUIN_GATE_RETURN_X,
			map_position,
			"遗迹外圈仍被封锁：先检查封锁遗迹入口，确认外圈通路。"
		)

	if _is_outer_ring_barrier_locked(world_state) and map_position.x > OUTER_RING_BARRIER_X:
		return _gate_block(
			OUTER_RING_BARRIER_RETURN_X,
			map_position,
			"遗迹外圈深段仍被抖动雾幕阻断：先回基地组装稳相信标，再返回部署。"
		)

	if _is_deep_ruin_gate_locked(world_state) and map_position.x > DEEP_RUIN_GATE_RETURN_X:
		return _gate_block(
			DEEP_RUIN_GATE_RETURN_X,
			map_position,
			"裂相脊入口仍未校准：先带着裂相坐标回到门禁写入。"
		)

	if not world_state.unlocked_region_ids.has("region.inner_phase_well") and map_position.x > INNER_PHASE_WELL_GATE_RETURN_X:
		return _gate_block(
			INNER_PHASE_WELL_GATE_RETURN_X,
			map_position,
			"回声台地仍未定位：先回基地解析回声定位器，再回来继续向东推进。"
		)

	if not world_state.unlocked_region_ids.has("region.phase_well_sink") and map_position.x > PHASE_WELL_SINK_GATE_RETURN_X:
		return _gate_block(
			PHASE_WELL_SINK_GATE_RETURN_X,
			map_position,
			"盐壳浅滩仍未稳定：先回基地解析回声芯样本，再带着新的盐壳穿钉回来继续向东推进。"
		)

	if not world_state.unlocked_region_ids.has("region.phase_well_chamber") and map_position.x > PHASE_WELL_CHAMBER_GATE_RETURN_X:
		return _gate_block(
			PHASE_WELL_CHAMBER_GATE_RETURN_X,
			map_position,
			"碎晶沟谷断面仍未稳定：先回基地解析碎晶心核，再带着新的碎晶分流栓回来继续向东推进。"
		)

	if not world_state.unlocked_region_ids.has("region.phase_well_loom") and map_position.x > PHASE_WELL_LOOM_GATE_RETURN_X:
		return _gate_block(
			PHASE_WELL_LOOM_GATE_RETURN_X,
			map_position,
			"风蚀管廊断面仍未稳定：先回基地解析风蚀张力核，再带着新的风蚀梭栓回来继续向东推进。"
		)

	if not world_state.unlocked_region_ids.has("region.phase_well_frame") and map_position.x > PHASE_WELL_FRAME_GATE_RETURN_X:
		return _gate_block(
			PHASE_WELL_FRAME_GATE_RETURN_X,
			map_position,
			"锁相框架断面仍未稳定：先回基地解析锁相织构核，再带着新的锁相键栓回来继续向东推进。"
		)

	if not world_state.unlocked_region_ids.has("region.phase_well_tether") and map_position.x > PHASE_WELL_TETHER_GATE_RETURN_X:
		return _gate_block(
			PHASE_WELL_TETHER_GATE_RETURN_X,
			map_position,
			"锚定桥断面仍未稳定：先回基地解析锚定结核，再带着新的锚定桩回来继续向东推进。"
		)

	if not world_state.unlocked_region_ids.has("region.demo_stabilization_core") and map_position.x > DEMO_STABILIZATION_CORE_GATE_RETURN_X:
		return _gate_block(
			DEMO_STABILIZATION_CORE_GATE_RETURN_X,
			map_position,
			"核心稳定站仍未接管：先完成锚定桥稳定窗口和高压窗口归档。"
		)

	return {}


static func get_phase_relay_pad_return_position(interactables_root: Node) -> Vector2:
	return get_interactable_return_position(
		interactables_root,
		"map_object_instance.phase_relay_pad",
		PHASE_RELAY_PAD_FALLBACK_POSITION
	)


static func get_phase_return_anchor_return_position(
	interactables_root: Node,
	anchor_instance_id: String
) -> Vector2:
	return get_interactable_return_position(
		interactables_root,
		anchor_instance_id,
		PHASE_RETURN_ANCHOR_FALLBACK_POSITION
	)


static func get_interactable_return_position(
	interactables_root: Node,
	instance_id: String,
	fallback_position: Vector2
) -> Vector2:
	var interactable := _find_interactable(interactables_root, instance_id)
	if interactable == null:
		return fallback_position
	return interactable.position + Vector2(0, 30)


static func get_interactable_region_id(
	interactables_root: Node,
	instance_id: String,
	fallback_region_id: String
) -> String:
	var interactable := _find_interactable(interactables_root, instance_id)
	if interactable == null:
		return fallback_region_id
	return get_region_id_for_position(interactable.position)


static func _gate_block(return_x: float, map_position: Vector2, message: String) -> Dictionary:
	return {
		"return_position": Vector2(return_x, map_position.y),
		"message": message
	}


static func _find_interactable(interactables_root: Node, instance_id: String) -> PrototypeInteractable:
	if interactables_root == null:
		return null
	for child in interactables_root.get_children():
		if not child is PrototypeInteractable:
			continue
		if child.instance_id != instance_id:
			continue
		return child
	return null


static func _is_outer_ring_barrier_locked(world_state: WorldState) -> bool:
	return not world_state.quest_state.has_completed_quest("quest.stabilize_outer_ring_barrier")


static func _is_deep_ruin_gate_locked(world_state: WorldState) -> bool:
	return not world_state.quest_state.has_completed_quest("quest.unlock_deep_ruin_entrance")
