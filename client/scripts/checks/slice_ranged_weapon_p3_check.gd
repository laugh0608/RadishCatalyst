extends SceneTree

const SliceWorldScene := preload("res://scenes/slice/SliceWorld.tscn")

var failures: Array[String] = []
var assertion_count := 0
var _test_root := ""


func _init() -> void:
	call_deferred("_execute")


func _execute() -> void:
	_test_root = SliceCheckPaths.check_run("ranged-weapon-p3")
	_check_input_and_numeric_contract()
	await _check_selection_shooting_hud_and_restart()
	if failures.is_empty():
		print(
			"Slice ranged weapon P3 checks passed (%d assertions)."
			% assertion_count
		)
		_remove_tree(_test_root)
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	_remove_tree(_test_root)
	quit(1)


func _check_input_and_numeric_contract() -> void:
	_check_key_action("select_cutter", KEY_1, "cutter selection")
	_check_key_action("select_pulse_rifle", KEY_2, "rifle selection")
	_expect_equal(
		SliceCombatController.PULSE_RIFLE_DAMAGE,
		12,
		"pulse rifle deals twelve damage"
	)
	_expect_equal(
		SlicePulseProjectile.SPEED,
		720.0,
		"pulse projectile travels at 720 pixels per second"
	)
	_expect_equal(
		SlicePulseProjectile.MAX_RANGE,
		320.0,
		"pulse projectile expires at 320 pixels"
	)
	_expect_equal(
		SliceCombatController.PULSE_RIFLE_CYCLE,
		0.38,
		"pulse rifle uses the frozen 0.38 second cycle"
	)


func _check_key_action(action: String, keycode: Key, context: String) -> void:
	var events := InputMap.action_get_events(action)
	_expect_equal(events.size(), 1, "%s has one authoritative key" % context)
	if events.size() != 1:
		return
	_expect_equal(events[0] is InputEventKey, true, "%s uses a key" % context)
	if not events[0] is InputEventKey:
		return
	_expect_equal(
		(events[0] as InputEventKey).keycode,
		keycode,
		"%s keeps its frozen number key" % context
	)


func _check_selection_shooting_hud_and_restart() -> void:
	var service := SliceSaveService.for_world(_test_root, "p3_world")
	var world := await _new_world(service, false)
	var controller := world.combat_controller
	var player := world.player
	var enemy := controller.field_enemy
	var hud := world.get_node("SliceHud") as SliceHud
	world.core_repaired = true
	world.core_energy = SliceWorld.CORE_CHARGE_TARGET
	world.core_charge_changed.emit(world.core_energy)
	enemy.set_physics_process(false)
	player.set_physics_process(false)
	controller.set_physics_process(false)

	_expect_equal(
		controller.current_weapon,
		SliceCombatController.WEAPON_CUTTER,
		"new session defaults to cutter"
	)
	_expect_equal(player.sprite.visible, true, "cutter keeps ordinary player art")
	_expect_equal(player.rifle_sprite.visible, false, "cutter hides rifle pose")
	controller._on_weapon_selection_requested(
		SliceCombatController.WEAPON_PULSE_RIFLE
	)
	_expect_equal(
		controller.current_weapon,
		SliceCombatController.WEAPON_CUTTER,
		"missing rifle cannot be selected"
	)
	_expect_contains(
		controller.notice_text,
		"未持有",
		"missing rifle gives an explicit short notice"
	)

	world.pocket.add(SliceWorld.ITEM_PULSE_RIFLE, 1)
	world.inventory_changed.emit()
	controller._on_weapon_selection_requested(
		SliceCombatController.WEAPON_PULSE_RIFLE
	)
	_expect_equal(
		controller.current_weapon,
		SliceCombatController.WEAPON_PULSE_RIFLE,
		"carried rifle can be selected without ammunition"
	)
	_expect_equal(player.sprite.visible, false, "rifle hides ordinary player art")
	_expect_equal(player.rifle_sprite.visible, true, "rifle shows approved full pose")
	player._refresh_weapon_visual(Vector2.RIGHT)
	_expect_equal(player.rifle_sprite.frame, 0, "right aim uses right rifle frame")
	player._refresh_weapon_visual(Vector2.LEFT)
	_expect_equal(player.rifle_sprite.frame, 1, "left aim uses mirrored rifle frame")
	player._refresh_weapon_visual(Vector2.UP)
	_expect_equal(player.rifle_sprite.frame, 2, "up aim uses up rifle frame")
	player._refresh_weapon_visual(Vector2.DOWN)
	_expect_equal(player.rifle_sprite.frame, 3, "down aim uses down rifle frame")

	var projectiles_before := _projectile_count(player.get_parent())
	controller._on_attack_pressed()
	_expect_equal(controller.attack_phase, "idle", "empty rifle creates no attack phase")
	_expect_equal(
		_projectile_count(player.get_parent()),
		projectiles_before,
		"empty rifle creates no projectile"
	)
	_expect_contains(
		controller.notice_text,
		"电池耗尽",
		"empty selected rifle keeps selection and explains cutter fallback"
	)

	world.pocket.add(SliceWorld.ITEM_PULSE_CELL, 8)
	world.inventory_changed.emit()
	player.position = enemy.position + Vector2(-260, 24)
	player.aim_direction = Vector2.RIGHT
	controller._on_attack_pressed()
	controller._on_attack_released()
	_expect_equal(
		controller.attack_phase,
		"rifle_recovery",
		"successful shot enters rifle recovery immediately"
	)
	_expect_equal(
		world.pocket.count(SliceWorld.ITEM_PULSE_CELL),
		7,
		"successful shot consumes one cell before travel"
	)
	var missed_projectile := _latest_projectile(player.get_parent())
	_expect_equal(missed_projectile != null, true, "successful shot creates projectile")
	if missed_projectile != null:
		missed_projectile.set_physics_process(false)
		var shot_origin := missed_projectile.position
		missed_projectile._physics_process(0.1)
		_expect_near(
			missed_projectile.position.distance_to(shot_origin),
			72.0,
			0.01,
			"projectile moves at the frozen speed"
		)
		missed_projectile._physics_process(1.0)
		_expect_equal(
			missed_projectile.distance_travelled,
			320.0,
			"missed projectile stops at maximum range"
		)
	await process_frame
	_expect_equal(enemy.health, 60, "range-expired miss deals no damage")
	_expect_equal(
		world.pocket.count(SliceWorld.ITEM_PULSE_CELL),
		7,
		"range-expired miss receives no ammunition refund"
	)
	controller._tick_attack(SliceCombatController.PULSE_RIFLE_CYCLE)

	for expected_health in [48, 36, 24, 12, 0]:
		controller._on_attack_pressed()
		controller._on_attack_released()
		var projectile := _latest_projectile(player.get_parent())
		_expect_equal(projectile != null, true, "each paid shot creates one projectile")
		if projectile == null:
			continue
		projectile.set_physics_process(false)
		var health_before_collision := enemy.health
		projectile._on_body_entered(enemy)
		projectile._on_body_entered(enemy)
		await process_frame
		_expect_equal(
			enemy.health,
			maxi(0, health_before_collision - SliceCombatController.PULSE_RIFLE_DAMAGE),
			"one projectile cannot damage the first enemy twice"
		)
		_expect_equal(
			enemy.health,
			expected_health,
			"each projectile deals exactly twelve damage"
		)
		await process_frame
		controller._tick_attack(SliceCombatController.PULSE_RIFLE_CYCLE)

	_expect_equal(enemy.state, "defeated", "five pulse hits defeat the fixed enemy")
	_expect_equal(controller.encounter_state, "dropped", "ranged defeat keeps sample flow")
	_expect_equal(
		world.pocket.count(SliceWorld.ITEM_PULSE_CELL),
		2,
		"one miss plus five hits consumes exactly six cells"
	)

	controller._on_attack_pressed()
	controller._on_attack_released()
	controller._tick_attack(SliceCombatController.PULSE_RIFLE_CYCLE)
	controller._on_attack_pressed()
	controller._on_attack_released()
	controller._tick_attack(SliceCombatController.PULSE_RIFLE_CYCLE)
	_expect_equal(world.pocket.count(SliceWorld.ITEM_PULSE_CELL), 0, "cells can deplete")
	_expect_equal(
		controller.current_weapon,
		SliceCombatController.WEAPON_PULSE_RIFLE,
		"depletion preserves rifle selection"
	)
	hud._refresh_state()
	_expect_contains(hud.combat_label.text, "当前：步枪", "HUD names current rifle")
	_expect_contains(hud.rifle_action_label.text, "电池耗尽", "HUD exposes empty state")
	_expect_equal(
		hud.rifle_action_label.modulate,
		SliceHud.AMMO_WARNING_COLOR,
		"only rifle status uses local amber warning"
	)
	_expect_equal(hud.rifle_active_line.visible, true, "HUD marks rifle as current")
	_expect_equal(hud.cutter_active_line.visible, false, "HUD does not mark both weapons")
	_expect_contains(hud.dodge_action_label.text, "闪避", "HUD retains Space dodge action")

	world.open_core_storage()
	controller._on_weapon_selection_requested(SliceCombatController.WEAPON_CUTTER)
	controller._on_attack_pressed()
	controller._physics_process(0.01)
	_expect_equal(
		controller.current_weapon,
		SliceCombatController.WEAPON_PULSE_RIFLE,
		"warehouse blocks weapon switching"
	)
	_expect_equal(controller.attack_phase, "idle", "warehouse blocks attack")
	world.close_core_storage()
	controller._physics_process(0.01)
	_expect_equal(
		controller.attack_phase,
		"idle",
		"closing blocker cannot reuse held left mouse"
	)
	world._craft_panel._open = true
	_check_blocker_preserves_rifle(world, controller, "manufacturing panel")
	world._craft_panel.close()
	world.pocket.add(SliceWorld.ITEM_FLOOR_KIT, 1)
	world.inventory_changed.emit()
	_expect_equal(
		world.begin_building_placement(SliceBuildingCatalog.FLOOR_ID),
		true,
		"floor kit opens placement blocker"
	)
	_check_blocker_preserves_rifle(world, controller, "building placement")
	world.cancel_building_placement()
	world.exit_build_mode()
	world._core_charge_panel._open = true
	_check_blocker_preserves_rifle(world, controller, "confirmation layer")
	world._core_charge_panel.close()
	world._building_action_panel._open = true
	_check_blocker_preserves_rifle(world, controller, "device panel")
	world._building_action_panel.close()
	controller._attack_held = true
	controller._requires_fresh_attack_press = false
	var pause_event := InputEventAction.new()
	pause_event.action = "ui_cancel"
	pause_event.pressed = true
	world._unhandled_input(pause_event)
	_expect_equal(
		controller._requires_fresh_attack_press,
		true,
		"opening pause synchronously requires a fresh left mouse press"
	)
	_check_blocker_preserves_rifle(world, controller, "pause menu")
	world.pause_menu.close()
	controller._on_weapon_selection_requested(SliceCombatController.WEAPON_CUTTER)
	_expect_equal(controller.current_weapon, SliceCombatController.WEAPON_CUTTER, "fresh 1 selects cutter")
	_expect_equal(hud.rifle_active_line.visible, false, "state signal refreshes HUD selection")

	controller._on_weapon_selection_requested(
		SliceCombatController.WEAPON_PULSE_RIFLE
	)
	_expect_equal(world.save_now(), true, "empty selected rifle state saves")
	var saved_data := _read_json(service.save_file_path())
	_expect_equal(
		saved_data.get("equipped_weapon_id", ""),
		SliceCombatController.WEAPON_PULSE_RIFLE,
		"save root persists the selected rifle"
	)
	_expect_equal(saved_data.has("projectiles"), false, "save root omits projectiles")
	_expect_equal(saved_data.has("attack_phase"), false, "save root omits attack phase")
	_free_world(world)

	world = await _new_world(service, true)
	controller = world.combat_controller
	_expect_equal(
		controller.current_weapon,
		SliceCombatController.WEAPON_PULSE_RIFLE,
		"reload restores the selected rifle"
	)
	_expect_equal(
		world.pocket.count(SliceWorld.ITEM_PULSE_RIFLE),
		1,
		"reload preserves rifle property"
	)
	_expect_equal(
		world.pocket.count(SliceWorld.ITEM_PULSE_CELL),
		0,
		"reload preserves consumed ammunition count"
	)
	_free_world(world)


func _check_blocker_preserves_rifle(
	world: SliceWorld,
	controller: SliceCombatController,
	context: String
) -> void:
	_expect_equal(world.is_combat_input_blocked(), true, "%s is a blocker" % context)
	controller._on_weapon_selection_requested(SliceCombatController.WEAPON_CUTTER)
	controller._on_attack_pressed()
	controller._physics_process(0.0)
	controller._on_attack_released()
	_expect_equal(
		controller.current_weapon,
		SliceCombatController.WEAPON_PULSE_RIFLE,
		"%s blocks weapon switching" % context
	)
	_expect_equal(controller.attack_phase, "idle", "%s blocks attack" % context)


func _new_world(service: SliceSaveService, load_existing: bool) -> SliceWorld:
	var world := SliceWorldScene.instantiate() as SliceWorld
	world.save_service = service
	world.startup_load = load_existing
	root.add_child(world)
	await process_frame
	await physics_frame
	return world


func _free_world(world: SliceWorld) -> void:
	if world == null:
		return
	world.free()


func _projectile_count(parent: Node) -> int:
	var count := 0
	for child in parent.get_children():
		if child is SlicePulseProjectile and not child.is_queued_for_deletion():
			count += 1
	return count


func _latest_projectile(parent: Node) -> SlicePulseProjectile:
	var result: SlicePulseProjectile
	for child in parent.get_children():
		if child is SlicePulseProjectile and not child.is_queued_for_deletion():
			result = child as SlicePulseProjectile
	return result


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


func _expect_equal(actual, expected, context: String) -> void:
	assertion_count += 1
	if actual == expected:
		return
	failures.append("%s: expected %s, got %s" % [context, str(expected), str(actual)])


func _expect_contains(actual: String, expected: String, context: String) -> void:
	assertion_count += 1
	if actual.contains(expected):
		return
	failures.append("%s: expected %s in %s" % [context, expected, actual])


func _expect_near(
	actual: float,
	expected: float,
	tolerance: float,
	context: String
) -> void:
	assertion_count += 1
	if absf(actual - expected) <= tolerance:
		return
	failures.append("%s: expected %.3f, got %.3f" % [context, expected, actual])


func _remove_tree(path: String) -> void:
	if path.is_empty() or not DirAccess.dir_exists_absolute(path):
		return
	var dir := DirAccess.open(path)
	if dir == null:
		return
	for filename in dir.get_files():
		dir.remove(filename)
	for child in dir.get_directories():
		_remove_tree(path.path_join(child))
	DirAccess.remove_absolute(path)
