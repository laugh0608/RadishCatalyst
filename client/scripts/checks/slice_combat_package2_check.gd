extends SceneTree

const SliceWorldScene := preload("res://scenes/slice/SliceWorld.tscn")

var failures: Array[String] = []
var assertion_count := 0
var _save_dir := ""


func _init() -> void:
	call_deferred("_execute")


func _execute() -> void:
	await _run_checks()
	if failures.is_empty():
		print(
			"Slice combat package 2 checks passed (%d assertions)."
			% assertion_count
		)
		_cleanup_save_dir()
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	_cleanup_save_dir()
	quit(1)


func _run_checks() -> void:
	_save_dir = "/private/tmp/radishcatalyst-combat-package2-%d" % (
		Time.get_ticks_usec()
	)
	var world := SliceWorldScene.instantiate() as SliceWorld
	world.save_service = SliceSaveService.new(_save_dir)
	root.add_child(world)
	await process_frame
	await physics_frame
	var controller := world.combat_controller
	var enemy := controller.field_enemy
	var player := world.player

	_expect_equal(controller.encounter_state, "locked", "new encounter is locked")
	_expect_equal(enemy.visible, false, "locked enemy is hidden")
	_expect_equal(enemy.health, 60, "enemy starts with sixty health")
	_expect_equal(
		enemy.sprite.texture.get_size(),
		Vector2(288, 256),
		"enemy uses approved four-by-four sheet"
	)
	var enemy_shadow := enemy.get_node("GroundShadow") as GroundShadow
	_expect_equal(
		absf(enemy_shadow.position.y) < 8.0,
		true,
		"sprite-sheet shadow uses one frame height at enemy feet"
	)
	var hud := world.get_node("SliceHud") as SliceHud
	var ui_font: Font = hud.goal_label.get_theme_font("font")
	_expect_equal(
		ui_font.has_char("敌".unicode_at(0)),
		true,
		"global UI font supports the enemy CJK glyph"
	)

	world.core_repaired = true
	world.core_energy = SliceWorld.CORE_CHARGE_TARGET
	world.core_charge_changed.emit(world.core_energy)
	_expect_equal(controller.encounter_state, "hostile", "charge unlocks encounter")
	_expect_equal(enemy.visible, true, "charged encounter shows enemy")
	_expect_equal(enemy.state, "alert", "enemy begins in alert")

	enemy.set_physics_process(false)
	controller.set_physics_process(false)
	player.set_physics_process(false)
	_check_direction_frames(enemy, player)
	_check_enemy_ai(enemy, player, controller)
	_check_damage_dodge_and_evacuation(enemy, player, controller)
	await _check_player_attack_drop_and_pickup(
		world, enemy, player, controller
	)
	world.free()


func _check_direction_frames(
	enemy: SliceFieldEnemy,
	player: SlicePlayer
) -> void:
	enemy.position = enemy.anchor_position
	player.position = enemy.position + Vector2(0, 80)
	enemy._set_state("telegraph")
	_expect_equal(enemy.sprite.frame, 1, "down telegraph uses row zero")
	player.position = enemy.position + Vector2(-80, 0)
	enemy._refresh_sprite()
	_expect_equal(enemy.sprite.frame, 5, "left telegraph uses row one")
	_expect_equal(enemy.sprite.flip_h, false, "left uses source orientation")
	player.position = enemy.position + Vector2(80, 0)
	enemy._refresh_sprite()
	_expect_equal(enemy.sprite.frame, 5, "right reuses side row")
	_expect_equal(enemy.sprite.flip_h, true, "right mirrors side row")
	player.position = enemy.position + Vector2(0, -80)
	enemy._refresh_sprite()
	_expect_equal(enemy.sprite.frame, 9, "up telegraph uses row two")
	enemy._set_state("alert")


func _check_enemy_ai(
	enemy: SliceFieldEnemy,
	player: SlicePlayer,
	controller: SliceCombatController
) -> void:
	enemy.position = enemy.anchor_position
	player.position = enemy.anchor_position + Vector2(180, 0)
	enemy._physics_process(0.01)
	_expect_equal(enemy.state, "chase", "alert range starts chase")
	player.position = enemy.position + Vector2(50, 0)
	enemy._physics_process(0.01)
	_expect_equal(enemy.state, "telegraph", "attack range starts telegraph")
	_expect_equal(enemy.state_text(), "蓄势", "telegraph has short HUD state")
	var health_before := controller.health
	enemy._physics_process(SliceFieldEnemy.TELEGRAPH_DURATION)
	_expect_equal(enemy.state, "recovery", "telegraph enters recovery")
	_expect_equal(
		controller.health,
		health_before - SliceFieldEnemy.ATTACK_DAMAGE,
		"in-range telegraph damages player once"
	)
	enemy._physics_process(SliceFieldEnemy.RECOVERY_DURATION)
	_expect_equal(enemy.state, "chase", "recovery returns to chase")

	enemy.position = enemy.anchor_position + Vector2(
		SliceFieldEnemy.LEASH_RANGE + 4.0, 0
	)
	player.position = enemy.anchor_position + Vector2(
		SliceFieldEnemy.LEASH_RANGE + 20.0, 0
	)
	enemy._set_state("chase")
	enemy._physics_process(0.01)
	_expect_equal(enemy.state, "return", "leash breach starts return")
	enemy.health = 20
	enemy.position = enemy.anchor_position + Vector2(2, 0)
	enemy._physics_process(0.01)
	_expect_equal(enemy.state, "alert", "home arrival restores alert")
	_expect_equal(enemy.health, 60, "home arrival restores full health")
	_expect_equal(enemy.position, enemy.anchor_position, "return snaps to anchor")


func _check_damage_dodge_and_evacuation(
	enemy: SliceFieldEnemy,
	player: SlicePlayer,
	controller: SliceCombatController
) -> void:
	controller.health = 100
	player.position = enemy.anchor_position + Vector2(40, 0)
	player.movement_input = Vector2.RIGHT
	controller._on_dodge_requested()
	_expect_equal(player.is_dodging(), true, "dodge is active")
	enemy.position = enemy.anchor_position
	enemy._set_state("telegraph")
	enemy._state_remaining = SliceFieldEnemy.TELEGRAPH_DURATION
	enemy._physics_process(SliceFieldEnemy.TELEGRAPH_DURATION)
	_expect_equal(controller.health, 100, "invulnerability rejects enemy hit")
	controller._physics_process(SliceCombatController.DODGE_INVULNERABLE)
	_expect_equal(controller.can_receive_damage(), true, "invulnerability expires")

	controller.health = 20
	enemy.health = 20
	enemy.position = enemy.anchor_position + Vector2(100, 0)
	enemy._set_state("chase")
	_expect_equal(
		controller.receive_damage(20),
		true,
		"lethal enemy damage is accepted"
	)
	_expect_equal(controller.health, 50, "evacuation restores half health")
	_expect_equal(
		player.position,
		SliceCombatController.EVACUATION_POSITION,
		"evacuation returns beside core"
	)
	_expect_equal(enemy.position, enemy.anchor_position, "evacuation resets enemy")
	_expect_equal(enemy.health, 60, "evacuation heals live enemy")
	_expect_equal(controller.encounter_state, "hostile", "evacuation keeps encounter")
	_expect_equal(
		controller.notice_text.contains("库存与充能保留"),
		true,
		"evacuation explains retained progress"
	)


func _check_player_attack_drop_and_pickup(
	world: SliceWorld,
	enemy: SliceFieldEnemy,
	player: SlicePlayer,
	controller: SliceCombatController
) -> void:
	enemy.position = enemy.anchor_position
	enemy.reset_after_evacuation()
	player.position = enemy.position + Vector2(-48, 25)
	player.aim_direction = Vector2.RIGHT
	player.cancel_dodge()
	controller.invulnerable_remaining = 0.0
	controller._on_attack_released()
	controller._refresh_effect_transform()
	for expected_health in [40, 20, 0]:
		controller._on_attack_pressed()
		controller._tick_attack(SliceCombatController.ATTACK_WINDUP)
		await physics_frame
		await physics_frame
		controller._physics_process(0.0)
		_expect_equal(
			enemy.health,
			expected_health,
			"active strike deals exactly twenty"
		)
		controller._physics_process(0.01)
		_expect_equal(
			enemy.health,
			expected_health,
			"one strike cannot hit the enemy twice"
		)
		controller._on_attack_released()
		controller._tick_attack(1.0)
		await physics_frame
		if expected_health > 0:
			enemy._physics_process(SliceFieldEnemy.HIT_DURATION)

	_expect_equal(enemy.state, "defeated", "third strike defeats enemy")
	_expect_equal(enemy.sprite.frame, 12, "defeat uses dedicated frame")
	_expect_equal(controller.encounter_state, "dropped", "defeat drops sample state")
	_expect_equal(controller.critical_sample != null, true, "sample spawns once")
	var sample: SliceCriticalSample = controller.critical_sample
	if sample == null:
		return
	_expect_equal(
		(sample.get_node("Sprite") as Sprite2D).texture.get_size(),
		Vector2(31, 30),
		"sample uses approved compact sprite"
	)
	enemy.defeated.emit()
	_expect_equal(
		_count_samples(player.get_parent()),
		1,
		"repeated defeat signal cannot duplicate sample"
	)

	world.pocket.add(
		SliceWorld.ITEM_CRYSTAL,
		world.pocket.free_space()
	)
	var pocket_before := world.pocket.to_dict()
	_expect_equal(
		controller.collect_critical_sample(sample),
		true,
		"dropped sample becomes carried"
	)
	await process_frame
	_expect_equal(controller.encounter_state, "carried", "sample state is carried")
	_expect_equal(controller.has_critical_sample(), true, "task sample is held")
	_expect_equal(
		world.pocket.to_dict(),
		pocket_before,
		"task sample bypasses full ordinary backpack"
	)
	_expect_equal(
		controller.collect_critical_sample(null),
		false,
		"carried sample cannot be collected twice"
	)
	_expect_equal(
		controller.encounter_goal_text(),
		"晶腺样本已回收（任务物品）",
		"HUD ends package two at carried state"
	)


func _count_samples(world_node: Node) -> int:
	var count := 0
	for child in world_node.get_children():
		if child is SliceCriticalSample:
			count += 1
	return count


func _expect_equal(actual, expected, context: String) -> void:
	assertion_count += 1
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
