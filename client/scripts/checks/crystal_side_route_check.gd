extends RefCounted

const VerticalSliceMapScene := preload("res://scenes/maps/VerticalSliceMap.tscn")

var host


func _init(check_host) -> void:
	host = check_host


func run(root: Node) -> void:
	_check_side_route_layout(root)
	_check_side_route_gather_feedback()
	_check_side_route_guard_feedback(root)


func _check_side_route_layout(root: Node) -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	map.setup(host.data_registry)
	var pocket := map.get_node("OpeningSceneLayer/CrystalLogisticsResourcePocket") as ColorRect
	var crystal_marker := map.get_node("OpeningSceneLayer/CrystalLogisticsCrystalMarker") as ColorRect
	var salvage_marker := map.get_node("OpeningSceneLayer/CrystalLogisticsSalvageMarker") as ColorRect
	var guard_marker := map.get_node("OpeningSceneLayer/CrystalLogisticsGuardMarker") as ColorRect
	var crystal := map.get_node("Interactables/CrystalClusterLogisticsPocket") as PrototypeInteractable
	var wreckage := map.get_node("Interactables/FieldWreckageLogisticsPocket") as PrototypeInteractable
	var guard := map.get_node("Enemies/NativeSkitterLogisticsGuard") as PrototypeEnemy
	host._expect_equal(
		crystal.position.x >= VerticalSliceMap.CRYSTAL_REGION_X
			and wreckage.position.x < VerticalSliceMap.POLLUTION_REGION_X
			and guard.position.x < VerticalSliceMap.POLLUTION_REGION_X,
		true,
		"crystal logistics side route stays inside the crystal field"
	)
	host._expect_equal(
		_is_rect_covering_position(pocket, crystal.position)
			and _is_rect_covering_position(pocket, wreckage.position)
			and _is_rect_covering_position(crystal_marker, crystal.position)
			and _is_rect_covering_position(salvage_marker, wreckage.position)
			and _is_rect_covering_position(guard_marker, guard.position),
		true,
		"crystal logistics side route scene markers align with playable objects"
	)
	host._expect_equal(
		guard.position.distance_to(crystal.position) <= VerticalSliceMap.ATTACK_RANGE
			and guard.position.distance_to(wreckage.position) <= VerticalSliceMap.ATTACK_RANGE,
		true,
		"crystal logistics side route ties extra resources to visible low-pressure combat"
	)
	map.free()


func _check_side_route_gather_feedback() -> void:
	var gather_system := GatherSystem.new(host.data_registry)
	var world := WorldState.create_default()
	var character := CharacterState.create_default()
	var crystal_result := gather_system.interact_with_object(
		"map_object_instance.crystal_cluster_logistics_pocket",
		"map_object.crystal_cluster",
		"gather",
		character,
		world
	)
	host._expect_equal(bool(crystal_result.get("success", false)), true, "crystal logistics pocket gather succeeds")
	host._expect_text_contains(
		String(crystal_result.get("message", "")),
		"支撑储存箱、整备台和后续地基材料",
		"crystal logistics pocket points gathered ore back to base construction"
	)
	host._expect_equal(
		int(character.inventory.items.get("item.crystal_ore", 0)),
		3,
		"crystal logistics pocket grants crystal ore"
	)
	var wreckage_result := gather_system.interact_with_object(
		"map_object_instance.field_wreckage_logistics_pocket",
		"map_object.field_wreckage",
		"gather",
		character,
		world
	)
	host._expect_equal(bool(wreckage_result.get("success", false)), true, "field wreckage logistics pocket gather succeeds")
	host._expect_text_contains(
		String(wreckage_result.get("message", "")),
		"整备台和后续基建材料",
		"field wreckage logistics pocket points scrap back to base construction"
	)
	host._expect_equal(
		int(character.inventory.items.get("item.salvage_scrap", 0)),
		2,
		"field wreckage logistics pocket grants salvage scrap"
	)


func _check_side_route_guard_feedback(root: Node) -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	map.setup(host.data_registry)
	var world := WorldState.create_default()
	var character := CharacterState.create_default()
	map.sync_enemy_states(world)
	var guard := map.get_node("Enemies/NativeSkitterLogisticsGuard") as PrototypeEnemy
	map.player.position = guard.position
	map.try_attack(character, world)
	var defeated_result := map.try_attack(character, world)
	host._expect_equal(bool(defeated_result.get("enemy_defeated", false)), true, "crystal logistics guard can be defeated")
	host._expect_text_contains(
		String(defeated_result.get("message", "")),
		"晶体侧路暂时安全",
		"crystal logistics guard defeat points back to the side route"
	)
	host._expect_equal(
		bool(world.get_enemy("enemy_instance.native_skitter_logistics_guard").get("is_defeated", false)),
		true,
		"crystal logistics guard defeat is stored in world state"
	)
	host._expect_equal(
		world.has_enemy_drops_granted("enemy_instance.native_skitter_logistics_guard"),
		true,
		"crystal logistics guard drop grant is stored"
	)
	map.free()


func _is_rect_covering_position(rect: ColorRect, position: Vector2) -> bool:
	if rect == null:
		return false
	return (
		rect.offset_left <= position.x
		and rect.offset_right >= position.x
		and rect.offset_top <= position.y
		and rect.offset_bottom >= position.y
	)
