extends RefCounted

const VerticalSliceMapScene := preload("res://scenes/maps/VerticalSliceMap.tscn")
const PrototypeHudScene := preload("res://scenes/ui/PrototypeHud.tscn")

var host


func _init(check_host) -> void:
	host = check_host


func run() -> void:
	_check_interactable_focus_labels()
	_check_enemy_focus_labels()
	_check_hud_map_runtime_labels()


func _check_interactable_focus_labels() -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	host.root.add_child(map)
	map.setup(host.data_registry)
	map.refresh_world_interactables(WorldState.create_default())
	var crystal := map.get_node("Interactables/CrystalCluster") as PrototypeInteractable
	var crystal_east := map.get_node("Interactables/CrystalClusterEast") as PrototypeInteractable
	host._expect_equal(crystal.label.visible, false, "first-hour non-current crystal label starts hidden")
	host._expect_equal(crystal.marker.scale, Vector2.ONE, "first-hour non-current crystal marker is not enlarged")

	map.player.position = crystal.position
	map.update_current_interactable()
	host._expect_equal(map.current_interactable, crystal, "first-hour nearest crystal becomes current interactable")
	host._expect_equal(crystal.label.visible, true, "first-hour current crystal label is visible")
	host._expect_equal(crystal.marker.scale, PrototypeInteractable.FOCUSED_MARKER_SCALE, "first-hour current crystal marker is enlarged")
	host._expect_equal(crystal_east.label.visible, false, "first-hour nearby non-current crystal label remains hidden")
	map.free()


func _check_enemy_focus_labels() -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	host.root.add_child(map)
	map.setup(host.data_registry)
	var world := WorldState.create_default()
	map.sync_enemy_states(world)
	var enemy := map.get_node("Enemies/NativeSkitter") as PrototypeEnemy
	var patrol := map.get_node("Enemies/NativeSkitterPatrol") as PrototypeEnemy
	host._expect_equal(enemy.label.visible, false, "first-hour enemy label starts hidden when out of range")

	map.player.position = enemy.position
	map.update_current_interactable()
	host._expect_equal(enemy.label.visible, true, "first-hour nearest attack target label is visible")
	host._expect_equal(enemy.sprite.scale, PrototypeEnemy.FOCUSED_SPRITE_SCALE, "first-hour nearest attack target is enlarged")
	host._expect_equal(patrol.label.visible, false, "first-hour non-current enemy label remains hidden")
	map.free()


func _check_hud_map_runtime_labels() -> void:
	var hud := PrototypeHudScene.instantiate() as PrototypeHud
	host.root.add_child(hud)
	hud._ensure_runtime_nodes()
	host._expect_equal(
		hud._format_map_marker_runtime_label("基地\n当前\n目标"),
		"基地\n当前 / 目标",
		"first-hour minimap keeps current target state compact"
	)
	host._expect_equal(
		hud._format_map_marker_runtime_label("晶体\n未解锁"),
		"晶体",
		"first-hour minimap hides low-value locked status text"
	)
	hud._set_control_rect(hud.map_panel, Vector2.ZERO, Vector2(560.0, 232.0))
	hud._layout_map_panel_contents()
	host._expect_equal(
		hud.map_marker_labels[0].position.y != hud.map_marker_labels[1].position.y,
		true,
		"first-hour minimap marker labels use staggered lanes"
	)
	hud.free()
