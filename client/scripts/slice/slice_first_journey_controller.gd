class_name SliceFirstJourneyController
extends Node

## Owns the two durable tutorial acknowledgements and coarse exploration map.
## Gameplay state remains authoritative for every actual journey transition.

signal changed

const PART_RECIPE_ID := "part"
const CRYSTALS_PER_PART := 3
const REQUIRED_PARTS := CoreRepairSite.REPAIR_PART_COST
const EXPLORATION_SAVE_DELAY := 6.0

var state := SliceExplorationState.new()
var _world: SliceWorld
var _player: SlicePlayer
var _exploration_dirty := false
var _save_elapsed := 0.0


func setup(world: SliceWorld, player: SlicePlayer) -> void:
	_world = world
	_player = player
	state.configure_new_game()
	set_process(true)


func restore(flags: Dictionary, explored_map_bits: String) -> void:
	state.restore(flags, explored_map_bits)
	state.reveal_at(_player.position, 1)
	_exploration_dirty = false
	_save_elapsed = 0.0
	changed.emit()


func mark_terminal_opened() -> void:
	if not state.mark_terminal_opened():
		return
	changed.emit()
	_save_milestone()


func mark_recipe_inspected(recipe_id: String) -> void:
	if recipe_id != PART_RECIPE_ID:
		return
	state.mark_terminal_opened()
	if not state.mark_part_recipe_inspected():
		return
	changed.emit()
	_save_milestone()


func guidance() -> Dictionary:
	if _world.core_repaired:
		return SliceJourneyGuidance.build(_world)
	var part_count := _world.pocket.count(SliceWorld.ITEM_PART)
	var crystal_count := _world.pocket.count(SliceWorld.ITEM_CRYSTAL)
	var remaining_crystals := (
		REQUIRED_PARTS - part_count
	) * CRYSTALS_PER_PART
	if not state.terminal_opened and part_count == 0 and crystal_count == 0:
		return {
			"stage": "open_terminal",
			"goal": "按 B 打开随身终端",
			"rule": "制造与背包共用同一终端；先查看机械零件配方",
		}
	if not state.part_recipe_inspected and part_count == 0:
		return {
			"stage": "inspect_part_recipe",
			"goal": "选择机械零件，查看制造配方",
			"rule": "机械零件需要 3 晶体；修复核心共需 3 个零件",
		}
	if part_count < REQUIRED_PARTS and crystal_count < remaining_crystals:
		return {
			"stage": "find_crystals",
			"goal": "前往东侧晶体信号区，采集晶体（%d/%d）" % [
				crystal_count, remaining_crystals,
			],
			"rule": "沿小地图信号向东探索；靠近晶体簇按 E 采集",
		}
	if part_count < REQUIRED_PARTS:
		return {
			"stage": "craft_parts",
			"goal": "按 B 制造机械零件（%d/%d）" % [
				part_count, REQUIRED_PARTS,
			],
			"rule": "机械零件配方已标记；每个消耗 3 晶体",
		}
	return {
		"stage": "repair_core",
		"goal": "返回前哨核心，按 E 完成修复",
		"rule": "小地图已标记核心；修复将消耗 3 个机械零件",
	}


func durable_data() -> Dictionary:
	return {
		"first_journey_flags": state.flags_data(),
		"explored_map_bits": state.encoded_bits(),
	}


static func default_durable_data() -> Dictionary:
	return {
		"first_journey_flags": {
			"terminal_opened": false,
			"part_recipe_inspected": false,
		},
		"explored_map_bits": SliceExplorationState.default_bits_for_position(
			SliceExplorationState.START_SPAWN
		),
	}


func mark_saved() -> void:
	_exploration_dirty = false
	_save_elapsed = 0.0


func _process(delta: float) -> void:
	if _world == null or _player == null:
		return
	if state.reveal_at(_player.position, 1):
		_exploration_dirty = true
		changed.emit()
	if not _exploration_dirty:
		return
	_save_elapsed += delta
	if _save_elapsed >= EXPLORATION_SAVE_DELAY:
		_world._autosave()


func _save_milestone() -> void:
	_exploration_dirty = true
	_save_elapsed = 0.0
	_world._autosave()
