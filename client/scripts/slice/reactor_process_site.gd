class_name ReactorProcessSite
extends Area2D

## Reactor processing interaction: the first press activates the reactor; once
## active it automatically refines crystals into catalyst on a timed tick
## (SliceWorld._tick_reactor). The prompt reflects activation plus the running /
## starved / full states (docs/features/slice-recipe-processing-v1.md).


func get_prompt(world: Node) -> String:
	if not world.reactor_active:
		return "按 E 激活反应器（每 %d 秒 %d 晶体 → %d 催化剂）" % [
			int(SliceWorld.REACTOR_PRODUCE_INTERVAL),
			SliceWorld.REACTOR_INPUT_PER_BATCH,
			SliceWorld.REACTOR_OUTPUT_PER_BATCH
		]
	if world.catalyst_count >= SliceWorld.CATALYST_CAP:
		return "反应器：催化剂已满（%d/%d），去核心充能" % [
			world.catalyst_count, SliceWorld.CATALYST_CAP
		]
	if world.crystal_count < SliceWorld.REACTOR_INPUT_PER_BATCH:
		return "反应器运转中：缺晶体暂停（需 %d 晶体）" % SliceWorld.REACTOR_INPUT_PER_BATCH
	return "反应器运转中：晶体 → 催化剂"


func try_interact(world: Node) -> void:
	world.activate_reactor()
