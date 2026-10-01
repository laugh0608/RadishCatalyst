extends RefCounted

const Rules := preload("res://data/factory/discovery_rules.gd")


static func count(items: Dictionary) -> int:
	var result := 0
	for amount in items.values():
		result += int(amount)
	return result


static func add(items: Dictionary, item: String, amount: int) -> void:
	var next := int(items.get(item, 0)) + amount
	assert(next >= 0)
	if next == 0:
		items.erase(item)
	else:
		items[item] = next


static func merge(target: Dictionary, source: Dictionary, sign_value := 1) -> void:
	for item in source:
		add(target, item, int(source[item]) * sign_value)


static func contains(items: Dictionary, needed: Dictionary) -> bool:
	for item in needed:
		if items.get(item, 0) < needed[item]:
			return false
	return true


static func describe(items: Dictionary) -> String:
	var parts := PackedStringArray()
	for item in Rules.ITEMS:
		if items.get(item, 0) > 0:
			parts.append("%s ×%d" % [Rules.NAMES[item], items[item]])
	return "、".join(parts) if not parts.is_empty() else "空"


static func contents(e: Dictionary) -> Dictionary:
	var result := {}
	match e.type:
		"collector": merge(result, e.buffer)
		"reactor":
			for key in ["input", "output", "invested"]:
				merge(result, e[key])
		"storage": merge(result, e.items)
		"belt":
			if not e.cargo.is_empty():
				result[e.cargo] = 1
	return result
