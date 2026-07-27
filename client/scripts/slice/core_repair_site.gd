class_name CoreRepairSite
extends Area2D

## Damaged outpost core interaction. After repair it prioritizes carried sample
## delivery, then first-field-charge confirmation, then central storage.

const REPAIR_PART_COST := 3

var repaired_texture: Texture2D = preload("res://assets/sprites/slice/outpost_core_repaired.png")


func get_prompt(world: Node) -> String:
	if world.core_repaired:
		if world.can_deliver_critical_sample():
			return "按 E 交付晶腺样本（安装抗蚀内衬）"
		if not world.is_core_charged():
			var available: int = world.core_charge_available()
			if world.can_charge_core():
				return "按 E 首次充能（催化剂 %d/%d）" % [
					available, SliceWorld.CORE_CHARGE_TARGET
				]
			return "首次充能需要 %d 催化剂（核心仓库 + 背包：%d/%d）" % [
				SliceWorld.CORE_CHARGE_TARGET,
				available,
				SliceWorld.CORE_CHARGE_TARGET,
			]
		return "按 E 管理核心仓库（直供在线｜%d/%d）" % [
			world.core_storage.total(), SliceWorld.CORE_STORAGE_CAPACITY
		]
	var parts: int = world.pocket.count(SliceWorld.ITEM_PART)
	if parts >= REPAIR_PART_COST:
		return "按 E 修复前哨核心（消耗 %d 机械零件）" % REPAIR_PART_COST
	return "修复前哨核心需要 %d 机械零件（背包 %d，按 B 合成）" % [REPAIR_PART_COST, parts]


func try_interact(world: Node) -> void:
	if world.core_repaired:
		if world.deliver_critical_sample():
			return
		if not world.is_core_charged():
			world.open_core_charge_confirmation()
			return
		world.open_core_storage()
		return
	if not world.spend_pocket_item(SliceWorld.ITEM_PART, REPAIR_PART_COST):
		return
	(get_parent() as Sprite2D).texture = repaired_texture
	world.mark_core_repaired()
