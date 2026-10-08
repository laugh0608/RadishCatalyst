extends "res://scripts/factory/save/codec_v1.gd"

## Attachment fields are validated before they enter the shared inventory/batch checks.
static func validate(e: Dictionary, next_id: int, next_batch: int) -> Dictionary:
	var cursor := "output_cursor" if e.type == "splitter" else "input_cursor"
	if not fields(e, ["id", "type", "x", "z", "dir", "cargo", "progress", "entry", "batch", cursor]):
		return failure("物流附件字段无效。")
	if not integer(e.id, 1, next_id - 1) or not integer(e.x, -32, 31) or not integer(e.z, -32, 31) or not integer(e.dir, 0, 3) or not integer(e[cursor], 0, 2):
		return failure("物流附件身份、方向或轮转位置无效。")
	if not e.cargo is String or e.cargo not in ["", "crystal", "rich_crystal", "catalyst", "crust_solvent"]:
		return failure("物流附件货物无效，样本不能自动运输。")
	if not number(e.progress, 0, 1) or not integer(e.batch, 0, next_batch - 1):
		return failure("物流附件行程或批次无效。")
	if not e.entry is Array or e.entry.size() != 2 or not integer(e.entry[0], -1, 1) or not integer(e.entry[1], -1, 1):
		return failure("物流附件入口格式无效。")
	var entry := Vector2i(e.entry[0], e.entry[1])
	var allowed: Array = [2] if e.type == "splitter" else [2, 3, 1]
	var side: int = Model.DIRS.find(entry)
	if side < 0 or (side - int(e.dir) + 4) % 4 not in allowed:
		return failure("货物入口与附件方向矛盾。")
	if e.cargo.is_empty():
		if e.progress != 0 or e.batch != 0 or entry != -Model.DIRS[int(e.dir)]:
			return failure("空附件含货物行程、批次或非规范入口。")
	elif e.cargo in ["crystal", "rich_crystal"]:
		if e.batch != 0:
			return failure("原矿不能带有加工批次。")
	elif e.batch == 0:
		return failure("附件加工产物缺少批次。")
	return {"ok": true}
