extends RefCounted
class_name InteractableTargetSelector

const CURRENT_OBJECTIVE_INTERACTION_RANGE := 58.0
const DIRECT_INTERACTION_RANGE := 34.0
const FORWARD_INTERACTION_RANGE := 56.0
const FORWARD_INTERACTION_DOT_MIN := 0.55


static func select_interactable(
	player: PlayerController,
	interactables_root: Node2D,
	world_state: WorldState
) -> PrototypeInteractable:
	var objective_interactable := _get_current_objective_priority_interactable(player, interactables_root, world_state)
	if _is_current_objective_interactable_selectable(player, objective_interactable):
		return objective_interactable

	var nearest_interactable: PrototypeInteractable = null
	var nearest_distance := INF
	for child in interactables_root.get_children():
		if not child is PrototypeInteractable:
			continue
		var interactable := child as PrototypeInteractable
		if not interactable.can_interact():
			continue
		var distance := player.position.distance_to(interactable.position)
		if not _is_general_interactable_selectable(player, interactable, distance) or distance >= nearest_distance:
			continue
		nearest_interactable = interactable
		nearest_distance = distance
	return nearest_interactable


static func _get_current_objective_priority_interactable(
	player: PlayerController,
	interactables_root: Node2D,
	world_state: WorldState
) -> PrototypeInteractable:
	if player == null or interactables_root == null or world_state == null:
		return null
	if world_state.quest_state.has_active_quest("quest.restore_outpost"):
		return interactables_root.get_node_or_null("OutpostCore") as PrototypeInteractable
	if world_state.quest_state.has_active_quest("quest.scout_crystal_field"):
		return _get_nearest_current_objective_interactable(
			player,
			interactables_root,
			["map_object.crystal_cluster"]
		)
	return null


static func _get_nearest_current_objective_interactable(
	player: PlayerController,
	interactables_root: Node2D,
	definition_ids: Array[String]
) -> PrototypeInteractable:
	var nearest_interactable: PrototypeInteractable = null
	var nearest_distance := INF
	for child in interactables_root.get_children():
		if not child is PrototypeInteractable:
			continue
		var interactable := child as PrototypeInteractable
		if not interactable.can_interact() or not definition_ids.has(interactable.definition_id):
			continue
		var distance := player.position.distance_to(interactable.position)
		if distance >= nearest_distance:
			continue
		nearest_interactable = interactable
		nearest_distance = distance
	return nearest_interactable


static func _is_current_objective_interactable_selectable(
	player: PlayerController,
	interactable: PrototypeInteractable
) -> bool:
	if interactable == null or not interactable.can_interact():
		return false
	var distance := player.position.distance_to(interactable.position)
	if distance <= DIRECT_INTERACTION_RANGE:
		return true
	if distance > CURRENT_OBJECTIVE_INTERACTION_RANGE:
		return false
	return _is_interactable_in_player_facing(player, interactable)


static func _is_general_interactable_selectable(
	player: PlayerController,
	interactable: PrototypeInteractable,
	distance: float
) -> bool:
	if distance <= DIRECT_INTERACTION_RANGE:
		return true
	if distance > FORWARD_INTERACTION_RANGE:
		return false
	return _is_interactable_in_player_facing(player, interactable)


static func _is_interactable_in_player_facing(player: PlayerController, interactable: PrototypeInteractable) -> bool:
	var direction_to_target := interactable.position - player.position
	if direction_to_target.length_squared() <= 0.001:
		return true
	return player.get_facing_direction().dot(direction_to_target.normalized()) >= FORWARD_INTERACTION_DOT_MIN
