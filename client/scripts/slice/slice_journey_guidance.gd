class_name SliceJourneyGuidance
extends RefCounted

## Derived first-hour objective copy. Keeping this read-only presentation logic
## outside SliceWorld leaves the world root focused on authoritative mutations.


static func build(world: SliceWorld) -> Dictionary:
	if world.is_core_charged():
		return {
			"stage": "field",
			"goal": world.combat_controller.encounter_goal_text(),
			"rule": "鼠标左键攻击｜Space 闪避｜按 HUD 目标完成外勤与交付",
		}
	if not world.core_repaired:
		return {
			"stage": "repair_core",
			"goal": "合成机械零件修复前哨核心（%d/%d）" % [
				world.pocket.count(SliceWorld.ITEM_PART),
				CoreRepairSite.REPAIR_PART_COST,
			],
			"rule": "按 B 合成 3 个机械零件，靠近受损核心按 E 修复",
		}
	if world.core_charge_available() >= world.core_charge_required():
		return {
			"stage": "charge_core",
			"goal": "基地目标 3/3：返回核心完成首次充能（可用 %d/%d）" % [
				world.core_charge_available(),
				SliceWorld.CORE_CHARGE_TARGET,
			],
			"rule": "靠近核心按 E 并确认；优先消耗核心仓库，再消耗背包",
		}
	var stored_catalyst := _storage_item_count(
		world, SliceWorld.ITEM_CATALYST
	)
	if (
		stored_catalyst + world.core_charge_available()
		>= world.core_charge_required()
	):
		return {
			"stage": "collect_catalyst",
			"goal": "基地目标 3/3：从储物箱取出产物（箱内 %d｜可用 %d/%d）" % [
				stored_catalyst,
				world.core_charge_available(),
				SliceWorld.CORE_CHARGE_TARGET,
			],
			"rule": "靠近储物箱按 E，选择催化剂后取出",
		}
	if not _has_powered_collector(world):
		return {
			"stage": "power_collector",
			"goal": "基地目标 1/3：在东侧晶体地放置通电采集器（按 B 合成）",
			"rule": "采集器只能放晶体地；中继需工业地板，6 格接力、4 格供能",
		}
	if not _has_powered_reactor(world):
		return {
			"stage": "power_reactor",
			"goal": "基地目标 2/3：铺工业地板并放置通电反应器",
			"rule": "反应器固定正面、左进右出；青色口进料，琥珀口出料",
		}
	return {
		"stage": "run_catalyst_line",
		"goal": "基地目标 3/3：接好双端物流，产出催化剂 %d/%d" % [
			world.core_charge_available() + stored_catalyst,
			SliceWorld.CORE_CHARGE_TARGET,
		],
		"rule": "采集器 → 带 → 反应器左侧 IN｜右侧 OUT → 带 → 储物箱",
	}


static func _has_powered_collector(world: SliceWorld) -> bool:
	for collector in world._collector_nodes:
		if collector.powered:
			return true
	return false


static func _has_powered_reactor(world: SliceWorld) -> bool:
	for reactor in world._reactor_nodes:
		if reactor.powered:
			return true
	return false


static func _storage_item_count(world: SliceWorld, item_id: String) -> int:
	var total := 0
	for storage in world._storage_nodes:
		total += storage.inventory.count(item_id)
	return total
