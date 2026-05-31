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
	_check_core_loop_layout()


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


func _check_core_loop_layout() -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	host.root.add_child(map)
	map.setup(host.data_registry)

	var outpost := map.get_node("Interactables/OutpostCore") as PrototypeInteractable
	var reactor := map.get_node("Interactables/BasicReactor") as PrototypeInteractable
	var base_choice := map.get_node("Interactables/BaseSupplyChoiceConsole") as PrototypeInteractable
	host._expect_equal(
		reactor.position.x > outpost.position.x,
		true,
		"first-hour base reactor sits on the exit side of the outpost core"
	)
	host._expect_equal(
		base_choice.position.x < reactor.position.x,
		true,
		"first-hour late action terminals stay away from the first manufacturing exit"
	)

	var first_crystal := map.get_node("Interactables/CrystalCluster") as PrototypeInteractable
	var side_crystal := map.get_node("Interactables/CrystalClusterSidePocket") as PrototypeInteractable
	var approach_crystal := map.get_node("Interactables/CrystalClusterTreatmentApproach") as PrototypeInteractable
	var south_wreckage := map.get_node("Interactables/FieldWreckageSouthPocket") as PrototypeInteractable
	var gate_cache := map.get_node("Interactables/FieldWreckageGateCache") as PrototypeInteractable
	var approach_wreckage := map.get_node("Interactables/FieldWreckageTreatmentApproach") as PrototypeInteractable
	var anomaly := map.get_node("Interactables/AnomalyCrystal") as PrototypeInteractable
	var native := map.get_node("Enemies/NativeSkitter") as PrototypeEnemy
	var treatment_skitter := map.get_node("Enemies/TreatmentSkitter") as PrototypeEnemy
	host._expect_equal(
		first_crystal.position.distance_to(native.position) > 120.0,
		true,
		"first-hour first crystal node starts before the low-pressure combat pocket"
	)
	host._expect_equal(
		side_crystal.position.distance_to(native.position) <= VerticalSliceMap.ATTACK_RANGE,
		true,
		"first-hour side crystal pocket introduces optional low-pressure combat"
	)
	host._expect_equal(
		south_wreckage.position.y > first_crystal.position.y and anomaly.position.y > first_crystal.position.y,
		true,
		"first-hour salvage and anomaly sample line sits off the main crystal route"
	)
	host._expect_equal(
		gate_cache.position.x > south_wreckage.position.x,
		true,
		"first-hour gate cache gives a final scrap pocket before treatment construction"
	)
	host._expect_equal(
		approach_crystal.position.x > gate_cache.position.x and approach_wreckage.position.x > gate_cache.position.x,
		true,
		"first-hour treatment approach adds resource choices after the first salvage pocket"
	)
	host._expect_equal(
		approach_wreckage.position.distance_to(treatment_skitter.position) <= VerticalSliceMap.ATTACK_RANGE,
		true,
		"first-hour treatment approach salvage is tied to the first guarded construction lane"
	)

	var rough_ground := map.get_node("Interactables/RoughGroundNorth") as PrototypeInteractable
	var filter_site := map.get_node("Interactables/PollutionFilterBuildSite") as PrototypeInteractable
	var entry_residue := map.get_node("Interactables/PollutionResidue") as PrototypeInteractable
	var outer_residue := map.get_node("Interactables/PollutionResidueOuterPocket") as PrototypeInteractable
	var deep_residue := map.get_node("Interactables/PollutionResidueDeep") as PrototypeInteractable
	var ridge_residue := map.get_node("Interactables/PollutionResidueRidgeCache") as PrototypeInteractable
	var polluted := map.get_node("Enemies/PollutedSkitter") as PrototypeEnemy
	var ridge_polluted := map.get_node("Enemies/PollutedSkitterRidge") as PrototypeEnemy
	var gate_polluted := map.get_node("Enemies/PollutedSkitterGatePressure") as PrototypeEnemy
	var elite := map.get_node("Enemies/EliteResidueNode") as PrototypeEnemy
	var ruin_gate := map.get_node("Interactables/RuinGate") as PrototypeInteractable
	host._expect_equal(
		rough_ground.position.y < VerticalSliceMap.POLLUTION_DEEP_Y and filter_site.position.y < VerticalSliceMap.POLLUTION_DEEP_Y,
		true,
		"first-hour treatment construction stays in the safe northern belt"
	)
	host._expect_equal(
		entry_residue.position.x >= VerticalSliceMap.POLLUTION_REGION_X and entry_residue.position.y >= VerticalSliceMap.POLLUTION_DEEP_Y,
		true,
		"first-hour entry residue sits inside the pollution danger field"
	)
	host._expect_equal(
		entry_residue.position.x < outer_residue.position.x and outer_residue.position.x < deep_residue.position.x,
		true,
		"first-hour pollution residue pockets step from entry to deep risk"
	)
	host._expect_equal(
		polluted.position.distance_to(entry_residue.position) <= VerticalSliceMap.ATTACK_RANGE,
		true,
		"first-hour first pollution residue is guarded by visible pressure"
	)
	host._expect_equal(
		deep_residue.position.distance_to(elite.position) <= VerticalSliceMap.ATTACK_RANGE,
		true,
		"first-hour deep pollution reward sits near the higher-risk elite node"
	)
	host._expect_equal(
		ridge_residue.position.x > outer_residue.position.x and ridge_residue.position.x < ruin_gate.position.x,
		true,
		"first-hour ridge residue gives a risky optional pickup before the ruin gate"
	)
	host._expect_equal(
		ridge_polluted.position.distance_to(ridge_residue.position) <= VerticalSliceMap.ATTACK_RANGE,
		true,
		"first-hour ridge residue is guarded by visible pollution pressure"
	)
	host._expect_equal(
		gate_polluted.position.distance_to(ruin_gate.position) <= VerticalSliceMap.ATTACK_RANGE,
		true,
		"first-hour ruin gate has a visible pollution pressure guard"
	)
	host._expect_equal(
		gate_polluted.position.x > outer_residue.position.x and gate_polluted.position.x < ruin_gate.position.x,
		true,
		"first-hour gate pressure sits between residue collection and ruin signal"
	)
	host._expect_equal(
		ruin_gate.position.x > elite.position.x,
		true,
		"first-hour ruin gate remains beyond the elite pollution pressure"
	)
	map.free()
