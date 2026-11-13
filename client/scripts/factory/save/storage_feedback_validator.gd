extends "res://scripts/factory/save/codec_v1.gd"

const Feedback := preload("res://data/factory/storage_feedback_rules.gd")


static func validate(e: Dictionary, model: RefCounted) -> Dictionary:
	var f: Variant = e.get("feedback")
	if not fields(f, ["mode", "source_id", "low_j", "high_j", "latch"]):
		return failure("储能反馈字段无效。")
	if f.mode not in ["timed", "storage"] or f.latch not in ["pending", "allow", "block"] or not integer(f.source_id):
		return failure("储能反馈模式、来源或决定无效。")
	if not integer(f.low_j, 0, Feedback.Storage.CAPACITY_J) or not integer(f.high_j, 0, Feedback.Storage.CAPACITY_J):
		return failure("储能阈值无效。")
	if not Feedback.valid_thresholds(int(f.low_j), int(f.high_j)):
		return failure("储能阈值范围、精度或顺序无效。")
	if f.mode == "timed":
		if f.source_id != 0 or f.low_j != Feedback.LOW_J or f.high_j != Feedback.HIGH_J or f.latch != "pending":
			return failure("纯节拍模式不能保有储能绑定或决定。")
	elif not model.researched.has(Feedback.RESEARCH) or e.filter_item != "industrial_cell" or (f.source_id == 0 and f.latch != "pending"):
		return failure("储能反馈缺少研究、电芯筛选或合法的来源清理状态。")
	return {"ok": true}


static func restore_references(model: RefCounted) -> Dictionary:
	for e in model.entities:
		if e.type != Feedback.Timed.TYPE:
			continue
		var f: Dictionary = e.feedback
		for key in ["source_id", "low_j", "high_j"]:
			f[key] = int(f[key])
		if f.source_id > 0 and (f.source_id >= model.next_id or model.by_id(f.source_id).get("type", "") != Feedback.Storage.TYPE):
			return failure("储能反馈引用了不存在或类型错误的来源。")
	return {"ok": true}
