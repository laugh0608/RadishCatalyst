class_name SliceCombatController
extends Node2D

## Slice combat runtime. Package 1 owns player tools; package 2 adds one fixed
## enemy and evacuation. Package 3 persists the five-state encounter and owns
## the carried -> delivered sample reward without introducing a task system.

const FIELD_ENEMY_SCENE := "res://scenes/slice/SliceFieldEnemy.tscn"
const CRITICAL_SAMPLE_SCENE := "res://scenes/slice/SliceCriticalSample.tscn"
const PULSE_PROJECTILE_SCENE := "res://scenes/slice/SlicePulseProjectile.tscn"
const FIELD_ENEMY_ANCHOR := Vector2(1984, 384)
const EVACUATION_POSITION := Vector2(704, 384)
const WEAPON_CUTTER := "cutter"
const WEAPON_PULSE_RIFLE := "pulse_rifle"
const ATTACK_WINDUP := 0.12
const ATTACK_ACTIVE := 0.10
const ATTACK_RECOVERY := 0.23
const ATTACK_DAMAGE := 20
const PULSE_RIFLE_DAMAGE := 12
const PULSE_RIFLE_CYCLE := 0.38
const DODGE_DISTANCE := 96.0
const DODGE_DURATION := 0.18
const DODGE_INVULNERABLE := 0.22
const DODGE_COOLDOWN := 0.8
const HIT_EFFECT_DURATION := 0.16
const MUZZLE_EFFECT_DURATION := 0.08

signal state_changed
signal persistence_requested

var health := 100
var max_health := 100
var attack_phase := "idle"
var attack_phase_remaining := 0.0
var dodge_cooldown_remaining := 0.0
var invulnerable_remaining := 0.0
var encounter_state := "locked"
var notice_text := ""
var current_weapon := WEAPON_CUTTER
var field_enemy: SliceFieldEnemy
var critical_sample: SliceCriticalSample

var _world: Node
var _player: SlicePlayer
var _attack_held := false
var _attack_hit_enemy := false
var _requires_fresh_attack_press := false
var _hit_effect_remaining := 0.0
var _muzzle_effect_remaining := 0.0
var _notice_remaining := 0.0
var _last_state_key := ""

@onready var _attack_pivot: Node2D = $AttackPivot
@onready var _attack_effect: Sprite2D = $AttackPivot/AttackEffect
@onready var _attack_area: Area2D = $AttackPivot/AttackArea
@onready var _attack_collision: CollisionShape2D = (
	$AttackPivot/AttackArea/Collision
)
@onready var _hit_effect: Sprite2D = $HitEffect
@onready var _muzzle_effect: Sprite2D = $MuzzleEffect
@onready var _pulse_hit_effect: Sprite2D = $PulseHitEffect


func setup(world: Node, player: SlicePlayer) -> void:
	_world = world
	_player = player
	player.attack_pressed.connect(_on_attack_pressed)
	player.attack_released.connect(_on_attack_released)
	player.dodge_requested.connect(_on_dodge_requested)
	player.weapon_selection_requested.connect(_on_weapon_selection_requested)
	world.core_charge_changed.connect(_on_core_charge_changed)
	world.inventory_changed.connect(_on_inventory_changed)
	current_weapon = WEAPON_CUTTER
	player.set_weapon_visual(current_weapon)
	_spawn_field_enemy()
	_refresh_effect_transform()
	_emit_state_if_changed()


func _physics_process(delta: float) -> void:
	if _world == null or _player == null:
		return
	_refresh_effect_transform()
	dodge_cooldown_remaining = maxf(
		0.0, dodge_cooldown_remaining - delta
	)
	invulnerable_remaining = maxf(0.0, invulnerable_remaining - delta)
	_tick_hit_effect(delta)
	_tick_muzzle_effect(delta)
	_tick_notice(delta)
	if _world.is_combat_input_blocked():
		require_fresh_attack_press()
	_tick_attack(delta)
	if attack_phase == "active":
		_resolve_player_attack()
	_emit_state_if_changed()


func _on_attack_pressed() -> void:
	_requires_fresh_attack_press = false
	_attack_held = true
	if _can_start_attack():
		_begin_attack()


func _on_attack_released() -> void:
	_attack_held = false


func require_fresh_attack_press() -> void:
	_attack_held = false
	_requires_fresh_attack_press = true
	if attack_phase == "windup":
		_finish_attack()


func _on_weapon_selection_requested(weapon_id: String) -> void:
	if _world == null or _world.is_combat_input_blocked():
		return
	match weapon_id:
		WEAPON_CUTTER:
			_select_weapon(WEAPON_CUTTER)
		WEAPON_PULSE_RIFLE:
			if not has_pulse_rifle():
				_set_notice("未持有前哨脉冲步枪｜保持切割器", 1.5)
				return
			_select_weapon(WEAPON_PULSE_RIFLE)


func _on_dodge_requested() -> void:
	if (
		not _world.is_core_charged()
		or _world.is_combat_input_blocked()
		or dodge_cooldown_remaining > 0.0
		or _player.is_dodging()
	):
		return
	_attack_held = false
	_requires_fresh_attack_press = true
	var direction := _player.movement_input
	if direction == Vector2.ZERO:
		direction = _player.aim_direction
	if direction == Vector2.ZERO:
		direction = Vector2.DOWN
	_player.start_dodge(direction, DODGE_DISTANCE, DODGE_DURATION)
	dodge_cooldown_remaining = DODGE_COOLDOWN
	invulnerable_remaining = DODGE_INVULNERABLE
	_set_notice("闪避成功", 0.6)
	if attack_phase not in ["active", "rifle_recovery"]:
		_finish_attack()
	_emit_state_if_changed()


func _can_start_attack() -> bool:
	return (
		attack_phase == "idle"
		and _world != null
		and _world.is_core_charged()
		and not _world.is_combat_input_blocked()
		and not _requires_fresh_attack_press
		and not _player.is_dodging()
	)


func _begin_attack() -> void:
	if current_weapon == WEAPON_PULSE_RIFLE:
		_begin_pulse_rifle_attack()
		return
	attack_phase = "windup"
	attack_phase_remaining = ATTACK_WINDUP
	_attack_hit_enemy = false
	_attack_effect.visible = true
	_attack_effect.frame = 0
	_attack_collision.disabled = true


func _tick_attack(delta: float) -> void:
	if attack_phase == "idle":
		return
	attack_phase_remaining -= delta
	while attack_phase != "idle" and attack_phase_remaining <= 0.0:
		match attack_phase:
			"rifle_recovery":
				if _attack_held and _can_repeat_attack():
					_begin_attack()
				else:
					_finish_attack()
			"windup":
				attack_phase = "active"
				attack_phase_remaining += ATTACK_ACTIVE
				_attack_effect.frame = 1
				_attack_collision.disabled = false
			"active":
				attack_phase = "recovery"
				attack_phase_remaining += ATTACK_RECOVERY
				_attack_effect.frame = 2
				_attack_collision.disabled = true
			"recovery":
				if _attack_held and _can_repeat_attack():
					_begin_attack()
				else:
					_finish_attack()
	if (
		attack_phase == "recovery"
		and attack_phase_remaining <= ATTACK_RECOVERY * 0.45
	):
		_attack_effect.frame = 3


func _can_repeat_attack() -> bool:
	return (
		not _requires_fresh_attack_press
		and not _world.is_combat_input_blocked()
		and not _player.is_dodging()
	)


func _finish_attack() -> void:
	attack_phase = "idle"
	attack_phase_remaining = 0.0
	if _attack_effect != null:
		_attack_effect.visible = false
	if _attack_collision != null:
		_attack_collision.disabled = true


func _begin_pulse_rifle_attack() -> void:
	if not has_pulse_rifle():
		_select_weapon(WEAPON_CUTTER)
		_set_notice("步枪不在随身背包｜已切回切割器", 1.8)
		return
	if pulse_cell_count() <= 0:
		_attack_held = false
		_requires_fresh_attack_press = true
		_set_notice("电池耗尽｜按 1 使用切割器", 1.8)
		return
	var consumption := _consume_pulse_cell()
	if not bool(consumption.get("consumed", false)):
		_attack_held = false
		_requires_fresh_attack_press = true
		_set_notice("电池耗尽｜按 1 使用切割器", 1.8)
		return
	attack_phase = "rifle_recovery"
	attack_phase_remaining = PULSE_RIFLE_CYCLE
	_attack_effect.visible = false
	_attack_collision.disabled = true
	_spawn_pulse_projectile(_player.aim_direction)
	_play_muzzle_effect(_player.aim_direction)
	if not bool(consumption.get("saved", false)):
		_set_notice("射击已成立｜自动保存失败，请稍后重试", 2.4)


func _consume_pulse_cell() -> Dictionary:
	if _world.pocket.remove(SliceWorld.ITEM_PULSE_CELL, 1) != 1:
		return {"consumed": false, "saved": false}
	_world.inventory_changed.emit()
	return {"consumed": true, "saved": _world._autosave()}


func _select_weapon(weapon_id: String) -> void:
	if current_weapon == weapon_id:
		return
	current_weapon = weapon_id
	_attack_held = false
	_requires_fresh_attack_press = true
	if attack_phase != "rifle_recovery":
		_finish_attack()
	_player.set_weapon_visual(current_weapon)
	_emit_state_if_changed()


func _spawn_pulse_projectile(direction: Vector2) -> SlicePulseProjectile:
	var projectile := (
		(load(PULSE_PROJECTILE_SCENE) as PackedScene).instantiate()
		as SlicePulseProjectile
	)
	_player.get_parent().add_child(projectile)
	var normalized_direction := (
		direction.normalized() if direction != Vector2.ZERO else Vector2.DOWN
	)
	projectile.setup(
		self,
		normalized_direction,
		_player.position + Vector2(0, -32) + normalized_direction * 34.0
	)
	return projectile


func resolve_pulse_projectile_collision(body: Node2D) -> bool:
	if body == null or body != field_enemy:
		return false
	if not field_enemy.take_damage(PULSE_RIFLE_DAMAGE):
		return false
	_play_pulse_hit_effect(field_enemy.position + Vector2(0, -24))
	if field_enemy.health > 0:
		persistence_requested.emit()
	return true


func player_actor() -> SlicePlayer:
	return _player


func has_pulse_rifle() -> bool:
	return (
		_world != null
		and _world.pocket.count(SliceWorld.ITEM_PULSE_RIFLE) > 0
	)


func pulse_cell_count() -> int:
	return (
		0
		if _world == null
		else _world.pocket.count(SliceWorld.ITEM_PULSE_CELL)
	)


func current_weapon_name() -> String:
	return "步枪" if current_weapon == WEAPON_PULSE_RIFLE else "切割器"


func pulse_rifle_status_text() -> String:
	if not has_pulse_rifle():
		return "未持有"
	if pulse_cell_count() <= 0:
		return "电池耗尽"
	return "电池 %d" % pulse_cell_count()


func _on_inventory_changed(_changed_value = null) -> void:
	if current_weapon != WEAPON_PULSE_RIFLE or has_pulse_rifle():
		_emit_state_if_changed()
		return
	_select_weapon(WEAPON_CUTTER)
	_set_notice("步枪已离开随身背包｜已切回切割器", 1.8)


func _refresh_effect_transform() -> void:
	_attack_pivot.position = _player.position + Vector2(0, -32)
	_attack_pivot.rotation = _player.aim_direction.angle()


func receive_damage(amount: int) -> bool:
	if amount <= 0 or not can_receive_damage():
		return false
	health = maxi(0, health - amount)
	_play_hit_effect(_player.position + Vector2(0, -32))
	if health <= 0:
		_evacuate_player()
	else:
		_set_notice("受到 %d 点伤害" % amount, 0.9)
	_emit_state_if_changed()
	persistence_requested.emit()
	return true


func collect_critical_sample(sample: SliceCriticalSample) -> bool:
	if encounter_state != "dropped" or sample == null or sample != critical_sample:
		return false
	encounter_state = "carried"
	critical_sample = null
	sample.queue_free()
	_set_notice("晶腺样本已回收｜任务物品不占背包", 2.4)
	_emit_state_if_changed()
	persistence_requested.emit()
	return true


func has_critical_sample() -> bool:
	return encounter_state == "carried"


func can_deliver_critical_sample() -> bool:
	return encounter_state == "carried"


func deliver_critical_sample() -> bool:
	if not can_deliver_critical_sample():
		return false
	encounter_state = "delivered"
	max_health = 120
	health = max_health
	_set_notice("核心分析完成｜抗蚀内衬已安装｜最大生命 120", 3.6)
	_emit_state_if_changed()
	persistence_requested.emit()
	return true


func durable_state() -> Dictionary:
	var enemy_health := 0
	if encounter_state in ["locked", "hostile"] and field_enemy != null:
		enemy_health = field_enemy.health
	return {
		"player_health": health,
		"field_encounter": {
			"state": encounter_state,
			"enemy_health": enemy_health,
		},
	}


func restore_durable_state(
	saved_health: int,
	field_encounter: Dictionary
) -> void:
	current_weapon = WEAPON_CUTTER
	_attack_held = false
	_requires_fresh_attack_press = true
	_finish_attack()
	_player.set_weapon_visual(current_weapon)
	encounter_state = String(field_encounter.get("state", "locked"))
	max_health = 120 if encounter_state == "delivered" else 100
	health = clampi(saved_health, 1, max_health)
	var enemy_health := int(
		field_encounter.get("enemy_health", SliceFieldEnemy.MAX_HEALTH)
	)
	field_enemy.restore_durable_state(encounter_state, enemy_health)
	if encounter_state == "dropped":
		_spawn_critical_sample()
	elif critical_sample != null:
		critical_sample.queue_free()
		critical_sample = null
	notice_text = ""
	_notice_remaining = 0.0
	_emit_state_if_changed()


func enemy_hud_visible() -> bool:
	return field_enemy != null and field_enemy.is_hud_visible()


func encounter_goal_text() -> String:
	match encounter_state:
		"hostile":
			return (
				"目标：击败裂晶爬兽"
				if enemy_hud_visible()
				else "目标：前往东侧晶体区调查活动迹象"
			)
		"dropped":
			return "目标：拾取裂晶爬兽掉落的晶腺样本"
		"carried":
			return "目标：返回核心交付晶腺样本"
		"delivered":
			return "抗蚀内衬已安装｜最大生命 120"
		_:
			return "目标：完成核心首次充能"


func _spawn_field_enemy() -> void:
	var enemy_scene := load(FIELD_ENEMY_SCENE) as PackedScene
	field_enemy = enemy_scene.instantiate() as SliceFieldEnemy
	_player.get_parent().add_child(field_enemy)
	field_enemy.attack_landed.connect(_on_enemy_attack_landed)
	field_enemy.defeated.connect(_on_enemy_defeated)
	field_enemy.state_changed.connect(_emit_state_if_changed)
	field_enemy.setup(
		_player,
		FIELD_ENEMY_ANCHOR,
		_world.is_core_charged()
	)
	if _world.is_core_charged():
		encounter_state = "hostile"


func _spawn_critical_sample() -> void:
	if critical_sample != null:
		return
	var sample_scene := load(CRITICAL_SAMPLE_SCENE) as PackedScene
	critical_sample = sample_scene.instantiate() as SliceCriticalSample
	critical_sample.combat_controller = self
	_player.get_parent().add_child(critical_sample)
	critical_sample.position = FIELD_ENEMY_ANCHOR + Vector2(22, 2)


func _resolve_player_attack() -> void:
	if _attack_hit_enemy or field_enemy == null:
		return
	for body in _attack_area.get_overlapping_bodies():
		if body != field_enemy:
			continue
		_attack_hit_enemy = true
		if field_enemy.take_damage(ATTACK_DAMAGE):
			_play_hit_effect(field_enemy.position + Vector2(0, -24))
			if field_enemy.health > 0:
				persistence_requested.emit()
		return


func _on_core_charge_changed(_energy: int) -> void:
	if not _world.is_core_charged() or encounter_state != "locked":
		return
	encounter_state = "hostile"
	field_enemy.set_encounter_enabled(true)
	_emit_state_if_changed()


func _on_enemy_attack_landed(damage: int) -> void:
	receive_damage(damage)


func _on_enemy_defeated() -> void:
	if encounter_state != "hostile":
		return
	encounter_state = "dropped"
	_spawn_critical_sample()
	_set_notice("裂晶爬兽败亡｜晶腺样本已掉落", 2.0)
	_emit_state_if_changed()
	persistence_requested.emit()


func _evacuate_player() -> void:
	health = maxi(1, max_health / 2)
	_player.position = EVACUATION_POSITION
	_player.velocity = Vector2.ZERO
	_player.cancel_dodge()
	_attack_held = false
	_requires_fresh_attack_press = true
	_finish_attack()
	invulnerable_remaining = 0.0
	dodge_cooldown_remaining = 0.0
	if encounter_state == "hostile" and field_enemy != null:
		field_enemy.reset_after_evacuation()
	_set_notice(
		"生命归零：已撤回核心｜库存与充能保留｜敌人恢复",
		3.6
	)


func _play_hit_effect(world_position: Vector2) -> void:
	_pulse_hit_effect.visible = false
	_hit_effect.position = world_position
	_hit_effect.frame = 0
	_hit_effect.visible = true
	_hit_effect_remaining = HIT_EFFECT_DURATION


func _play_muzzle_effect(direction: Vector2) -> void:
	var normalized_direction := (
		direction.normalized() if direction != Vector2.ZERO else Vector2.DOWN
	)
	_muzzle_effect.position = (
		_player.position + Vector2(0, -32) + normalized_direction * 30.0
	)
	_muzzle_effect.frame = _direction_frame(normalized_direction)
	_muzzle_effect.visible = true
	_muzzle_effect_remaining = MUZZLE_EFFECT_DURATION


func _tick_muzzle_effect(delta: float) -> void:
	if _muzzle_effect_remaining <= 0.0:
		return
	_muzzle_effect_remaining = maxf(0.0, _muzzle_effect_remaining - delta)
	if _muzzle_effect_remaining <= 0.0:
		_muzzle_effect.visible = false


func _play_pulse_hit_effect(world_position: Vector2) -> void:
	_hit_effect.visible = false
	_pulse_hit_effect.position = world_position
	_pulse_hit_effect.frame = 0
	_pulse_hit_effect.visible = true
	_hit_effect_remaining = HIT_EFFECT_DURATION


func _tick_hit_effect(delta: float) -> void:
	if _hit_effect_remaining <= 0.0:
		return
	_hit_effect_remaining = maxf(0.0, _hit_effect_remaining - delta)
	if _hit_effect_remaining <= 0.0:
		_hit_effect.visible = false
		_pulse_hit_effect.visible = false
		return
	var progress := 1.0 - _hit_effect_remaining / HIT_EFFECT_DURATION
	var effect_frame := mini(3, int(floor(progress * 4.0)))
	_hit_effect.frame = effect_frame
	_pulse_hit_effect.frame = effect_frame


func _direction_frame(direction: Vector2) -> int:
	if direction.y < 0.0 and -direction.y >= absf(direction.x):
		return 2
	if absf(direction.x) >= absf(direction.y):
		return 0 if direction.x > 0.0 else 1
	return 3


func _set_notice(message: String, duration: float) -> void:
	notice_text = message
	_notice_remaining = duration
	_emit_state_if_changed()


func _tick_notice(delta: float) -> void:
	if _notice_remaining <= 0.0:
		return
	_notice_remaining = maxf(0.0, _notice_remaining - delta)
	if _notice_remaining <= 0.0:
		notice_text = ""


func can_receive_damage() -> bool:
	return invulnerable_remaining <= 0.0


func dodge_ready() -> bool:
	return dodge_cooldown_remaining <= 0.0


func dodge_status_text() -> String:
	if not _world.is_core_charged():
		return "未解锁"
	if dodge_ready():
		return "就绪"
	return "%.1fs" % dodge_cooldown_remaining


func attack_status_text() -> String:
	if not _world.is_core_charged():
		return "工具锁定"
	if attack_phase == "rifle_recovery":
		return "步枪冷却"
	match attack_phase:
		"windup":
			return "预备"
		"active":
			return "切割"
		"recovery":
			return "恢复"
		_:
			return "%s就绪" % current_weapon_name()


func _emit_state_if_changed() -> void:
	var state_key := "%d/%d|%s|%s|%d|%.2f|%.2f|%s" % [
		health,
		max_health,
		current_weapon,
		attack_phase,
		pulse_cell_count(),
		dodge_cooldown_remaining,
		invulnerable_remaining,
		"%s|%s|%s|%s" % [
			_player.is_dodging(),
			encounter_state,
			notice_text,
			field_enemy.state if field_enemy != null else "missing",
		],
	]
	if state_key == _last_state_key:
		return
	_last_state_key = state_key
	state_changed.emit()
