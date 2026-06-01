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
	_check_treatment_entry_gather_feedback()
	_check_pollution_pressure_consumption()
	_check_ruin_gate_pressure_gate()


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
	var return_crystal := map.get_node("Interactables/CrystalClusterFoundationReturn") as PrototypeInteractable
	var return_wreckage := map.get_node("Interactables/FieldWreckageFoundationReturn") as PrototypeInteractable
	var anomaly := map.get_node("Interactables/AnomalyCrystal") as PrototypeInteractable
	var native := map.get_node("Enemies/NativeSkitter") as PrototypeEnemy
	var treatment_skitter := map.get_node("Enemies/TreatmentSkitter") as PrototypeEnemy
	var treatment_skitter_north := map.get_node("Enemies/TreatmentSkitterNorth") as PrototypeEnemy
	var treatment_skitter_return := map.get_node("Enemies/TreatmentSkitterReturn") as PrototypeEnemy
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
	host._expect_equal(
		approach_crystal.position.distance_to(treatment_skitter_north.position) <= VerticalSliceMap.ATTACK_RANGE,
		true,
		"first-hour treatment approach crystal is tied to the second guarded construction lane"
	)
	host._expect_equal(
		return_crystal.position.x > approach_crystal.position.x and return_wreckage.position.x > approach_wreckage.position.x,
		true,
		"first-hour treatment entrance adds a final crystal and salvage return pocket"
	)
	host._expect_equal(
		return_crystal.position.y < VerticalSliceMap.POLLUTION_DEEP_Y and return_wreckage.position.y < VerticalSliceMap.POLLUTION_DEEP_Y,
		true,
		"first-hour treatment entrance return pocket stays in the safe construction belt"
	)
	host._expect_equal(
		return_crystal.position.distance_to(treatment_skitter_return.position) <= VerticalSliceMap.ATTACK_RANGE
			and return_wreckage.position.distance_to(treatment_skitter_return.position) <= VerticalSliceMap.ATTACK_RANGE,
		true,
		"first-hour treatment entrance return pocket is tied to a low-pressure guard"
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


func _check_treatment_entry_gather_feedback() -> void:
	var gather_system := GatherSystem.new(host.data_registry)
	var world := WorldState.create_default()
	var character := CharacterState.create_default()
	var crystal_result := gather_system.interact_with_object(
		"map_object_instance.crystal_cluster_foundation_return",
		"map_object.crystal_cluster",
		"gather",
		character,
		world
	)
	host._expect_text_contains(
		String(crystal_result.get("message", "")),
		"回基地加工基础零件或地基材料",
		"first-hour treatment entrance crystal points back to manufacturing"
	)
	var wreckage_result := gather_system.interact_with_object(
		"map_object_instance.field_wreckage_foundation_return",
		"map_object.field_wreckage",
		"gather",
		character,
		world
	)
	host._expect_text_contains(
		String(wreckage_result.get("message", "")),
		"若地基或过滤器缺料",
		"first-hour treatment entrance salvage explains construction supply use"
	)


func _check_pollution_pressure_consumption() -> void:
	var gather_system := GatherSystem.new(host.data_registry)
	var no_module_world := WorldState.create_default()
	var no_module_character := CharacterState.create_default()
	var no_module_result := gather_system.interact_with_object(
		"map_object_instance.pollution_residue_ridge_cache",
		"map_object.pollution_residue_patch",
		"gather",
		no_module_character,
		no_module_world
	)
	host._expect_equal(bool(no_module_result.get("success", false)), true, "first-hour ridge residue gather succeeds")
	host._expect_equal(no_module_character.protection, 76.0, "first-hour ridge residue consumes higher unfiltered protection")
	host._expect_text_contains(String(no_module_result.get("message", "")), "门前高压点", "first-hour ridge residue explains gate pressure")

	var module_world := WorldState.create_default()
	var module_character := CharacterState.create_default()
	module_character.equipment["suit_module"] = "equipment.filter_module_t1"
	var module_result := gather_system.interact_with_object(
		"map_object_instance.pollution_residue_ridge_cache",
		"map_object.pollution_residue_patch",
		"gather",
		module_character,
		module_world
	)
	host._expect_equal(bool(module_result.get("success", false)), true, "first-hour filtered ridge residue gather succeeds")
	host._expect_equal(int(roundf(module_character.protection * 10.0)), 844, "first-hour filter module lowers ridge pressure drain")
	host._expect_text_contains(String(module_result.get("message", "")), "过滤模块已降低消耗", "first-hour ridge residue logs filter benefit")


func _check_ruin_gate_pressure_gate() -> void:
	var map := VerticalSliceMap.new()
	map.data_registry = host.data_registry
	var gate_world := WorldState.create_default()
	gate_world.quest_state.completed_quest_ids.append("quest.defeat_elite_node")
	gate_world.quest_state.active_quest_ids = ["quest.unlock_ruin_signal"]
	gate_world.ensure_enemy("enemy_instance.polluted_skitter_gate_pressure", "enemy.polluted_skitter", "region.pollution_edge", 30.0)
	var blocked_result := map._inspect_ruin_gate(gate_world)
	host._expect_equal(bool(blocked_result.get("success", true)), false, "first-hour ruin gate blocks while gate pressure enemy is active")
	host._expect_failure_feedback(blocked_result, "门前压力未清", "first-hour ruin gate pressure failure feedback")
	gate_world.update_enemy_health("enemy_instance.polluted_skitter_gate_pressure", 0.0, true)
	var opened_result := map._inspect_ruin_gate(gate_world)
	host._expect_equal(bool(opened_result.get("success", false)), true, "first-hour ruin gate opens after gate pressure enemy is defeated")
	map.free()
