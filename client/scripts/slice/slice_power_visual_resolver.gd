class_name SlicePowerVisualResolver
extends RefCounted

## Resolves derived logical power edges to non-persistent sprite anchors. The
## graph never depends on these positions, so visual calibration cannot alter
## reachability, saves or the deterministic parent tree.


static func resolve_links(
	connections: Array[Dictionary],
	buildings: Array[SliceBuildingInstance],
	core_anchor_offset: Vector2,
	relay_fallback_offset: Vector2
) -> Array[Dictionary]:
	var links: Array[Dictionary] = []
	for connection in connections:
		var from_position := Vector2(
			connection.get("from_position", Vector2.ZERO)
		)
		var to_position := Vector2(
			connection.get("to_position", Vector2.ZERO)
		)
		links.append({
			"from_position": anchor_world_position(
				String(connection.get("parent_id", "")),
				from_position,
				to_position,
				buildings,
				core_anchor_offset,
				relay_fallback_offset
			),
			"to_position": anchor_world_position(
				String(connection.get("child_id", "")),
				to_position,
				from_position,
				buildings,
				core_anchor_offset,
				relay_fallback_offset
			),
		})
	return links


static func anchor_world_position(
	node_id: String,
	logic_position: Vector2,
	toward_position: Vector2,
	buildings: Array[SliceBuildingInstance],
	core_anchor_offset: Vector2,
	relay_fallback_offset: Vector2
) -> Vector2:
	if node_id == SlicePowerGrid.CORE_NODE_ID:
		return logic_position + core_anchor_offset
	for instance in buildings:
		if instance.instance_id == node_id:
			return instance.power_visual_anchor_toward_world_position(
				toward_position
			)
	return logic_position + relay_fallback_offset
