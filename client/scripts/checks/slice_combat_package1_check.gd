extends SceneTree

const SliceWorldScene := preload("res://scenes/slice/SliceWorld.tscn")

var failures: Array[String] = []
var _assertion_count := 0
var _save_dir := ""


func _init() -> void:
	call_deferred("_execute")


func _execute() -> void:
	await _run_checks()
	if failures.is_empty():
		print(
			"Slice combat package 1 checks passed (%d assertions)."
			% _assertion_count
		)
		_cleanup_save_dir()
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	_cleanup_save_dir()
	quit(1)


func _run_checks() -> void:
	_check_input_map()
	await _check_world_charge_combat_and_hud()


func _check_input_map() -> void:
	var attack_events := InputMap.action_get_events("attack")
	_expect_equal(attack_events.size(), 1, "attack has one authoritative input")
	_expect_equal(
		attack_events[0] is InputEventMouseButton,
		true,
		"attack uses a mouse button"
	)
	_expect_equal(
		(attack_events[0] as InputEventMouseButton).button_index,
		MOUSE_BUTTON_LEFT,
		"attack uses left mouse"
	)
	var dodge_events := InputMap.action_get_events("dodge")
	_expect_equal(dodge_events.size(), 1, "dodge has one authoritative input")
	_expect_equal(
		dodge_events[0] is InputEventKey,
		true,
		"dodge uses a keyboard key"
	)
	_expect_equal(
		(dodge_events[0] as InputEventKey).keycode,
		KEY_SPACE,
		"dodge uses Space"
	)


func _check_world_charge_combat_and_hud() -> void:
	_save_dir = SliceCheckPaths.check_run("combat-package1")
	var world := SliceWorldScene.instantiate() as SliceWorld
	world.save_service = SliceSaveService.new(_save_dir)
	root.add_child(world)
	await process_frame
	await physics_frame

	var repair_site := world._map.get_node(
		"World/OutpostCoreDamaged/RepairSite"
	) as CoreRepairSite
	var controller := world.combat_controller
	var player := world.player
	var hud := world.get_node("SliceHud") as SliceHud

	_expect_equal(world.is_core_charged(), false, "new world is not charged")
	_expect_equal(
		controller.attack_status_text(),
		"工具锁定",
		"combat stays locked before first charge"
	)
	world.core_repaired = true
	_expect_equal(world.core_charge_required(), 2, "first charge requires two")
	_expect_equal(world.can_charge_core(), false, "insufficient catalyst blocks")
	_expect_equal(
		repair_site.get_prompt(world).contains("0/2"),
		true,
		"core prompt explains missing catalyst"
	)
	world.core_storage.add(SliceWorld.ITEM_CATALYST, 1)
	world.pocket.add(SliceWorld.ITEM_CATALYST, 1)
	_expect_equal(world.core_charge_available(), 2, "inventories combine")
	_expect_equal(world.can_charge_core(), true, "combined stock enables charge")
	_expect_equal(
		repair_site.get_prompt(world).contains("按 E 首次充能"),
		true,
		"core offers explicit first charge"
	)
	_expect_equal(
		world.open_core_charge_confirmation(),
		true,
		"first charge opens confirmation"
	)
	_expect_equal(
		world.is_combat_input_blocked(),
		true,
		"charge confirmation blocks combat input"
	)
	_expect_equal(
		world._core_charge_panel.source_text().contains(
			"核心仓库 1 → 随身背包 1"
		),
		true,
		"charge modal exposes the authoritative deduction order and sources"
	)
	_expect_equal(
		world._core_charge_panel.confirm_text(),
		"确认充能 · 消耗 2 份",
		"charge modal keeps the real cost on the single primary action"
	)
	_expect_equal(
		world._core_charge_panel.cancel_text(),
		"Esc 取消",
		"charge modal keeps cancellation neutral and keyboard-explicit"
	)
	world.close_core_charge_confirmation()
	_expect_equal(world.confirm_core_charge(), true, "confirmed charge succeeds")
	_expect_equal(world.core_energy, 2, "charge reaches fixed threshold")
	_expect_equal(
		world.core_storage.count(SliceWorld.ITEM_CATALYST),
		0,
		"charge consumes core storage first"
	)
	_expect_equal(
		world.pocket.count(SliceWorld.ITEM_CATALYST),
		0,
		"charge consumes remaining catalyst from backpack"
	)
	_expect_equal(world.charge_core(), false, "repeat charge is rejected")
	_expect_equal(
		repair_site.get_prompt(world).contains("管理核心仓库"),
		true,
		"charged core returns to warehouse interaction"
	)

	hud._refresh_state()
	_expect_equal(
		hud.goal_label.text.contains("前往东侧晶体区"),
		true,
		"HUD advances to field investigation"
	)
	_expect_equal(
		hud.health_label.text,
		"生命 100/100",
		"HUD exposes compact health"
	)
	_expect_equal(
		hud.combat_label.text.contains("核心：已充能"),
		true,
		"HUD exposes charged combat state"
	)

	player._update_animation(true, Vector2.LEFT)
	_expect_equal(player.sprite.animation, &"walk", "left aim selects side walk")
	_expect_equal(player.sprite.flip_h, false, "left aim uses source orientation")
	player._update_animation(true, Vector2.RIGHT)
	_expect_equal(player.sprite.animation, &"walk", "right aim selects side walk")
	_expect_equal(player.sprite.flip_h, true, "right aim mirrors source")
	player._update_animation(true, Vector2.UP)
	_expect_equal(player.sprite.animation, &"walk_up", "up aim selects up walk")
	player._update_animation(true, Vector2.DOWN)
	_expect_equal(
		player.sprite.animation, &"walk_down", "down aim selects down walk"
	)
	player.facing = Vector2.LEFT
	player.movement_input = Vector2.LEFT
	player.aim_direction = Vector2.RIGHT
	player._update_animation(true, player.aim_direction)
	_expect_equal(
		player.facing,
		Vector2.LEFT,
		"right aim does not overwrite left movement facing"
	)
	_expect_equal(
		player.sprite.flip_h,
		true,
		"right aim controls art while movement points left"
	)
	player.movement_input = Vector2.UP
	player.aim_direction = Vector2.RIGHT
	player._update_animation(true, player.aim_direction)
	_expect_equal(
		player.sprite.animation,
		&"walk",
		"orthogonal up movement keeps right-facing art"
	)

	var attack_effect := controller.get_node(
		"AttackPivot/AttackEffect"
	) as Sprite2D
	var attack_collision := controller.get_node(
		"AttackPivot/AttackArea/Collision"
	) as CollisionShape2D
	_expect_equal(
		attack_effect.texture.get_size(),
		Vector2(384, 64),
		"attack uses approved four-frame sheet"
	)
	controller._on_attack_pressed()
	_expect_equal(controller.attack_phase, "windup", "press starts immediately")
	controller._tick_attack(SliceCombatController.ATTACK_WINDUP)
	_expect_equal(controller.attack_phase, "active", "windup enters active")
	_expect_equal(attack_collision.disabled, false, "active enables hit shape")
	controller._tick_attack(SliceCombatController.ATTACK_ACTIVE)
	_expect_equal(controller.attack_phase, "recovery", "active enters recovery")
	_expect_equal(attack_collision.disabled, true, "recovery disables hit shape")
	controller._tick_attack(SliceCombatController.ATTACK_RECOVERY)
	_expect_equal(controller.attack_phase, "windup", "hold repeats after recovery")
	controller._on_attack_released()
	controller._tick_attack(1.0)
	_expect_equal(controller.attack_phase, "idle", "release stops next attack")

	_expect_equal(world.open_core_storage(), true, "charged core storage opens")
	controller._on_attack_pressed()
	controller._physics_process(0.01)
	_expect_equal(controller.attack_phase, "idle", "foreground UI blocks attack")
	world.close_core_storage()
	controller._physics_process(0.01)
	_expect_equal(
		controller.attack_phase,
		"idle",
		"closing UI does not reuse a held attack"
	)
	controller._on_attack_pressed()
	_expect_equal(
		controller.attack_phase,
		"windup",
		"fresh press after UI starts attack"
	)
	controller._on_attack_released()
	controller._tick_attack(1.0)

	player.movement_input = Vector2.LEFT
	controller._on_attack_pressed()
	controller._on_dodge_requested()
	_expect_equal(player.is_dodging(), true, "Space starts short dodge")
	_expect_equal(controller.can_receive_damage(), false, "dodge grants invulnerability")
	_expect_equal(controller.dodge_ready(), false, "dodge starts cooldown")
	_expect_equal(
		controller._requires_fresh_attack_press,
		true,
		"dodge interrupts held repeat"
	)
	controller._physics_process(SliceCombatController.DODGE_INVULNERABLE)
	_expect_equal(
		controller.can_receive_damage(),
		true,
		"invulnerability ends at fixed duration"
	)
	controller._physics_process(SliceCombatController.DODGE_COOLDOWN)
	_expect_equal(controller.dodge_ready(), true, "dodge cooldown recovers")
	world.free()


func _expect_equal(actual, expected, context: String) -> void:
	_assertion_count += 1
	if actual == expected:
		return
	failures.append(
		"%s: expected %s, got %s" % [context, str(expected), str(actual)]
	)


func _cleanup_save_dir() -> void:
	if _save_dir.is_empty():
		return
	for filename in [
		"slice_world.json",
		"slice_world.bak.json",
		"slice_world.tmp.json",
	]:
		var path := _save_dir.path_join(filename)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	if DirAccess.dir_exists_absolute(_save_dir):
		DirAccess.remove_absolute(_save_dir)
