extends RefCounted
class_name RuinGateReadinessFormatter


static func format_ready_prompt(character_state: CharacterState = null) -> String:
	if character_state == null:
		return "按 E 确认：封锁遗迹入口信号，打开遗迹外圈通路。"
	if _has_polluted_slurry(character_state):
		return "封锁遗迹入口：门前压力已清；污染浆液可先回基础反应器回收基础零件，也可按 E 确认入口信号。"
	if not _has_resistance_vial(character_state):
		return "封锁遗迹入口：门前压力已清；药剂已用完，可回过滤器补药剂后再进外圈。"
	if not _has_filter_module(character_state):
		return "封锁遗迹入口：门前压力已清；基础过滤模块未装入，后续污染承压会更高。"
	return "按 E 确认：封锁遗迹入口信号；基础过滤模块和抗污染药剂已能支撑进门。"


static func format_unlock_message(character_state: CharacterState = null) -> String:
	if character_state == null:
		return "封锁遗迹入口信号已确认：遗迹外圈通路已恢复。"
	var lines: Array[String] = [
		"封锁遗迹入口信号已确认：遗迹外圈通路已恢复。",
		"门前准备记录：%s；%s；%s。"
	]
	return " ".join(lines) % [
		_format_filter_module_state(character_state),
		_format_vial_state(character_state),
		_format_slurry_state(character_state)
	]


static func _format_filter_module_state(character_state: CharacterState) -> String:
	if _has_filter_module(character_state):
		return "基础过滤模块已装配"
	return "基础过滤模块未装入，后续污染承压更高"


static func _format_vial_state(character_state: CharacterState) -> String:
	var amount := int(character_state.inventory.items.get("item.resistance_vial_t1", 0))
	if amount > 0:
		return "抗污染药剂 x%d 可继续承接外圈压力" % amount
	return "抗污染药剂已用完，可回过滤器补药剂"


static func _format_slurry_state(character_state: CharacterState) -> String:
	var amount := float(character_state.inventory.fluids.get("fluid.polluted_slurry", 0.0))
	if amount > 0.0:
		return "污染浆液 x%s 可回基础反应器回收基础零件" % _format_amount(amount)
	return "未携带污染浆液，可直接推进外圈"


static func _has_filter_module(character_state: CharacterState) -> bool:
	return String(character_state.equipment.get("suit_module", "")) == "equipment.filter_module_t1"


static func _has_resistance_vial(character_state: CharacterState) -> bool:
	return character_state.inventory.has_ref("item.resistance_vial_t1", 1)


static func _has_polluted_slurry(character_state: CharacterState) -> bool:
	return character_state.inventory.has_ref("fluid.polluted_slurry", 1.0)


static func _format_amount(amount: float) -> String:
	if is_equal_approx(amount, roundf(amount)):
		return str(int(amount))
	return "%.1f" % amount
