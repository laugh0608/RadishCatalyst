extends SceneTree

const DemoCardScene := preload(
	"res://scenes/slice/SliceDemoCompletionCard.tscn"
)

var failures: Array[String] = []
var _assertion_count := 0


class FakeCombatController:
	extends Node
	signal demo_completed


class FakeWorld:
	extends Node
	signal return_to_startup_requested

	var combat_controller := FakeCombatController.new()
	var save_result := true


	func _init() -> void:
		add_child(combat_controller)


	func save_now() -> bool:
		return save_result


func _init() -> void:
	call_deferred("_execute")


func _execute() -> void:
	_check_spatial_layers_and_footprints()
	_check_collector_transition_and_storage_route()
	_check_collector_to_core_route()
	_check_demo_completion_card()
	if failures.is_empty():
		print(
			"Slice playtest remediation package 1 checks passed (%d assertions)."
			% _assertion_count
		)
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)


func _check_spatial_layers_and_footprints() -> void:
	var map := (
		load(SliceWorld.MAP_SCENE) as PackedScene
	).instantiate() as Node2D
	var ground_structures := map.get_node("GroundStructures") as Node2D
	var world_layer := map.get_node("World") as Node2D
	_expect_equal(
		ground_structures.y_sort_enabled,
		false,
		"ground structures stay outside y sort"
	)
	_expect_equal(world_layer.y_sort_enabled, true, "device world keeps y sort")

	var conveyor_definition := SliceBuildingCatalog.find(
		SliceBuildingCatalog.CONVEYOR_ID
	)
	var floor_definition := SliceBuildingCatalog.find(
		SliceBuildingCatalog.FLOOR_ID
	)
	var reactor_definition := SliceBuildingCatalog.find(
		SliceBuildingCatalog.REACTOR_ID
	)
	_expect_equal(
		conveyor_definition.spatial_layer,
		SliceBuildingDefinition.SPATIAL_LAYER_GROUND,
		"conveyor is assigned to the ground layer"
	)
	_expect_equal(
		floor_definition.spatial_layer,
		SliceBuildingDefinition.SPATIAL_LAYER_GROUND,
		"industrial floor is assigned to the ground layer"
	)
	_expect_equal(
		conveyor_definition.blocks_movement,
		false,
		"conveyor no longer blocks player movement"
	)
	_expect_equal(
		reactor_definition.footprint,
		Vector2i(3, 3),
		"reactor keeps a three-by-three occupied footprint"
	)

	var shell := SliceWorld.new()
	shell._map = map
	shell._ground = map.get_node("GroundLayer")
	shell._industrial_floor = map.get_node("IndustrialFloorLayer")
	shell._logistics_transitions = map.get_node(
		"GroundStructures/LogisticsTransitions"
	)
	var conveyor := shell._spawn_building(
		conveyor_definition,
		"package1-ground-conveyor",
		Vector2i(30, 10),
		1,
		{}
	)
	var reactor := shell._spawn_building(
		reactor_definition,
		"package1-world-reactor",
		Vector2i(34, 9),
		0,
		{}
	)
	_expect_equal(
		conveyor.get_parent(),
		ground_structures,
		"spawned conveyor is parented to ground structures"
	)
	_expect_equal(
		reactor.get_parent(),
		world_layer,
		"spawned reactor remains in the y-sorted device world"
	)
	_expect_equal(
		conveyor.get_node_or_null("Footprint"),
		null,
		"conveyor has no blocking collision body"
	)
	var reactor_shape := (
		(reactor.get_node("Footprint/Collision") as CollisionShape2D).shape
		as RectangleShape2D
	)
	_expect_equal(
		reactor_shape.size,
		Vector2(96, 96),
		"reactor collision derives from its three-by-three footprint"
	)
	var reactor_sprite := reactor.get_node("Sprite") as Sprite2D
	_expect_equal(
		reactor_sprite.texture.get_size(),
		Vector2(96, 90),
		"reactor visual fits the occupied width without phantom docks"
	)
	map.free()
	shell.free()


func _check_collector_transition_and_storage_route() -> void:
	var collector := _make_collector(
		"package1-storage-collector", Vector2i(10, 10)
	)
	var first_belt := _make_conveyor(
		"package1-storage-belt-a", Vector2i(13, 11), 1
	)
	var second_belt := _make_conveyor(
		"package1-storage-belt-b", Vector2i(14, 11), 1
	)
	var storage := _make_storage(
		"package1-storage-target", Vector2i(15, 10)
	)
	storage.set_mode(SliceStorage.MODE_TRANSFER)
	collector.buffer = 1
	var instances: Array[SliceBuildingInstance] = [
		collector, first_belt, second_belt, storage,
	]
	var grid := SliceLogisticsGrid.new()
	grid.rebuild(instances)
	var output := collector.logistics_endpoints()[0]
	_expect_equal(
		output.connection_distance,
		2,
		"collector output explicitly spans one transition cell"
	)
	_expect_equal(
		output.connection_cell,
		Vector2i(13, 11),
		"collector terminal belt stays beyond the transition cell"
	)

	var transition_layer := SliceLogisticsTransitionLayer.new()
	transition_layer.set_transitions(grid.placement_preview_ports(), 32.0)
	_expect_equal(
		transition_layer.transition_count(),
		1,
		"connected collector creates exactly one visible transition"
	)
	_expect_equal(
		transition_layer.has_transition_at(Vector2i(12, 11)),
		true,
		"collector transition occupies the explicit approach cell"
	)
	for _step in range(240):
		grid.tick(SliceLogisticsGrid.SIMULATION_STEP_SECONDS)
	_expect_equal(collector.buffer, 0, "collector source removes one crystal")
	_expect_equal(
		storage.inventory.count(SliceWorld.ITEM_CRYSTAL),
		1,
		"collector crystal reaches storage through simulated belts"
	)

	first_belt.building_rotation = 3
	grid.rebuild(instances)
	transition_layer.set_transitions(grid.placement_preview_ports(), 32.0)
	_expect_equal(
		transition_layer.transition_count(),
		0,
		"wrong-way terminal belt removes the transition visual"
	)
	transition_layer.free()
	_free_instances(instances)


func _check_collector_to_core_route() -> void:
	var collector := _make_collector(
		"package1-core-collector", Vector2i(10, 10)
	)
	var first_belt := _make_conveyor(
		"package1-core-belt-a", Vector2i(13, 11), 1
	)
	var second_belt := _make_conveyor(
		"package1-core-belt-b", Vector2i(14, 11), 1
	)
	collector.buffer = 1
	var core := Node2D.new()
	core.position = Vector2(512, 352)
	var core_inventory := Inventory.new(
		SliceInventoryProfiles.category_core_storage()
	)
	var core_logistics := SliceCoreLogistics.new()
	core_logistics.setup(core, null, core_inventory, true, 32.0)
	var instances: Array[SliceBuildingInstance] = [
		collector, first_belt, second_belt,
	]
	var grid := SliceLogisticsGrid.new()
	grid.rebuild(instances, "", core_logistics.endpoints())
	for _step in range(240):
		grid.tick(SliceLogisticsGrid.SIMULATION_STEP_SECONDS)
	_expect_equal(collector.buffer, 0, "core route removes collector crystal")
	_expect_equal(
		core_inventory.count(SliceWorld.ITEM_CRYSTAL),
		1,
		"collector crystal reaches repaired core through simulated belts"
	)
	_free_instances(instances)
	core.free()


func _check_demo_completion_card() -> void:
	var fake_world := FakeWorld.new()
	root.add_child(fake_world)
	var card := DemoCardScene.instantiate() as SliceDemoCompletionCard
	root.add_child(card)
	card.setup(fake_world)
	_expect_equal(
		card.is_open(),
		false,
		"completed-world setup does not replay a session completion card"
	)
	fake_world.combat_controller.demo_completed.emit()
	_expect_equal(card.is_open(), true, "delivery signal opens completion card")
	_expect_equal(paused, true, "completion card pauses gameplay")
	_expect_equal(
		card.root_control.visible,
		true,
		"completion acknowledgement is visible"
	)
	card.close()
	_expect_equal(card.is_open(), false, "continue action closes completion card")
	_expect_equal(paused, false, "continue action resumes gameplay")
	card.free()
	fake_world.free()


func _make_collector(id: String, origin: Vector2i) -> SliceCollector:
	var collector := (
		load("res://scenes/slice/SliceCollector.tscn") as PackedScene
	).instantiate() as SliceCollector
	var definition := SliceBuildingCatalog.find(
		SliceBuildingCatalog.COLLECTOR_ID
	)
	collector.configure_building(id, definition.building_id, origin, 0)
	collector.apply_definition(definition, 32.0)
	return collector


func _make_conveyor(
	id: String, origin: Vector2i, rotation: int
) -> SliceConveyor:
	var conveyor := (
		load("res://scenes/slice/SliceConveyor.tscn") as PackedScene
	).instantiate() as SliceConveyor
	var definition := SliceBuildingCatalog.find(
		SliceBuildingCatalog.CONVEYOR_ID
	)
	conveyor.configure_building(id, definition.building_id, origin, rotation)
	conveyor.apply_definition(definition, 32.0)
	return conveyor


func _make_storage(id: String, origin: Vector2i) -> SliceStorage:
	var storage := (
		load("res://scenes/slice/SliceStorage.tscn") as PackedScene
	).instantiate() as SliceStorage
	var definition := SliceBuildingCatalog.find(
		SliceBuildingCatalog.STORAGE_ID
	)
	storage.configure_building(id, definition.building_id, origin, 0)
	storage.apply_definition(definition, 32.0)
	return storage


func _free_instances(instances: Array[SliceBuildingInstance]) -> void:
	for instance in instances:
		instance.free()


func _expect_equal(actual, expected, context: String) -> void:
	_assertion_count += 1
	if actual != expected:
		failures.append(
			"%s: expected %s, got %s" % [context, expected, actual]
		)
