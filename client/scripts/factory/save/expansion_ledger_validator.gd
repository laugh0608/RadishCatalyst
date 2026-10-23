extends "res://scripts/factory/save/codec_v1.gd"

const Expansion := preload("res://data/factory/expansion_rules.gd")
const Stats := preload("res://scripts/factory/save/statistics_validator.gd")


static func counts(value: Variant, keys: Array, limit := MAX_NUMBER) -> bool:
	if not fields(value, keys): return false
	for key in keys:
		if not integer(value[key], 0, limit): return false
	return true


static func add_scaled(target: Dictionary, values: Dictionary, factor: int) -> bool:
	for item in values:
		if factor > (MAX_NUMBER - int(target.get(item, 0))) / int(values[item]): return false
		target[item] = target.get(item, 0) + int(values[item]) * factor
	return true


static func validate(model: RefCounted, saved_stats: Dictionary) -> Dictionary:
	var produced: Dictionary = model.extracted_by_item.duplicate()
	var consumed := {}
	var completed := 0
	var generated := 0
	for amount in model.extracted_by_item.values():
		if generated > MAX_NUMBER - amount: return failure("采集累计溢出。")
		generated += amount
	for recipe_id in model.recipes:
		var n: int = model.completed_by_recipe[recipe_id]
		if completed > MAX_NUMBER - n: return failure("完成累计溢出。")
		completed += n
		if not add_scaled(produced, model.recipes[recipe_id].output, n) or not add_scaled(consumed, model.recipes[recipe_id].input, n): return failure("配方累计溢出。")
	for type in model.assembly_counts:
		if not add_scaled(consumed, {"construction_pack": model.assembly_costs[type]}, model.assembly_counts[type]): return failure("装配消费溢出。")
	if not add_scaled(consumed, model.extra_consumption(), 1): return failure("能源消费溢出。")
	for passage in model.discovery.passages:
		if model.discovery.passages[passage] and not add_scaled(consumed, {"crust_solvent": model.DiscoveryRules.PASSAGES[passage].cost}, 1): return failure("开路消费溢出。")
	if completed != model.completed or generated != model.generated or model.completed_by_recipe.solvent_trial != int(model.discovery.trial_completed): return failure("生产账与累计计数或唯一试制矛盾。")
	if model.extracted_by_item.rich_crystal > 0 and not model.discovery.passages.outer: return failure("富矿提取早于开路。")
	if not model.discovery.trial_completed and (model.completed_by_recipe.crust_solvent > 0 or model.completed_by_recipe.rich_catalyst > 0): return failure("生产早于配方解锁。")
	var balance: Dictionary = model.material_balance()
	if not balance.balanced: return failure("逐物料生产账与全世界持有量不守恒。")
	var totals: Dictionary = saved_stats.totals
	for item in model.item_ids:
		if totals.produced.get(item, 0) != produced.get(item, 0) or totals.consumed.get(item, 0) != consumed.get(item, 0) or totals.acquired.get(item, 0) != (int(model.discovery.sample_taken) if item == "crust_sample" else 0): return failure("统计产消与生产、装配或发现事实不一致。")
		if item == "crust_sample" and totals.delivered.get(item, 0) != 0: return failure("样本不能自动入仓。")
		if item not in model.extracted_by_item and totals.delivered.get(item, 0) > produced.get(item, 0): return failure("入仓超过已生产数量。")
	if totals.delivered.get("catalyst", 0) != model.delivered: return failure("累计入仓计数不一致。")
	return batches(model)


static func batches(model: RefCounted) -> Dictionary:
	if not model.batch_recipes is Dictionary or model.batch_recipes.size() > model.entities.size(): return failure("活批来源表无效或超出引用上界。")
	for key in model.batch_recipes:
		if not key is String or not key.is_valid_int() or str(key.to_int()) != key or not integer(key.to_int(), 1, model.next_batch - 1) or not model.recipes.has(model.batch_recipes[key]): return failure("活批来源键或配方无效。")
	var active := {}
	var output := {}
	var completed_live := {}
	for e in model.entities:
		if e.get("processing", false):
			var key := str(e.active_batch)
			if active.has(key) or model.batch_recipes.get(key) != e.recipe_id: return failure("重复在制或在制来源不符。")
			active[key] = true
		var batch: int = e.get("output_batch", e.get("batch", 0))
		if batch == 0: continue
		var key := str(batch)
		if not model.batch_recipes.has(key): return failure("出料缺少活批来源。")
		var recipe_id: String = model.batch_recipes[key]
		if e.has("recipe_id") and e.recipe_id != recipe_id: return failure("输出来源与机器配方不符。")
		if not output.has(key):
			output[key] = {}
			completed_live[recipe_id] = completed_live.get(recipe_id, 0) + 1
		var held: Dictionary = e.output if e.has("output") else {e.cargo: 1}
		if not add_scaled(output[key], held, 1): return failure("活批产物累计溢出。")
	for key in model.batch_recipes:
		if active.has(key) == output.has(key): return failure("活批没有引用或同时在制与出料。")
		if output.has(key):
			var limits: Dictionary = model.recipes[model.batch_recipes[key]].output
			for item in output[key]:
				if output[key][item] > limits.get(item, 0): return failure("同批产出向量超额或混入非法产物。")
	for recipe_id in completed_live:
		if completed_live[recipe_id] > model.completed_by_recipe[recipe_id]: return failure("活批数量超过配方完成数。")
	return {"ok": true}
