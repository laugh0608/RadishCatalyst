extends RefCounted

const Rules := preload("res://data/factory/discovery_rules.gd")
const Items := preload("res://scripts/factory/items.gd")


## Read-only advice derived from existing facts. Never persists separate tutorial progress.
static func current(model: RefCounted) -> Dictionary:
	if model.supply_id == Rules.Energy.SUPPLY_ID: return _energy(model)
	if model.supply_id == Rules.Expansion.SUPPLY_ID: return _expansion(model)
	var d: Dictionary = model.discovery
	var produced: int = model.statistics.totals.produced.get("catalyst", 0)
	if d.passages.inner:
		return _step("complete", "工艺已经可以复用", "两段矿道已打通", "扩建新矿点；保存后继续经营。", _action("statistics", "查看生产统计", "比较实际产出与供电，寻找下一处可改善的瓶颈。"))
	if d.passages.outer:
		if model.statistics.totals.consumed.get("rich_crystal", 0) == 0 and model.bag.get("crust_solvent", 0) < 8:
			return _rich(model)
		return _passage(model, "inner")
	if d.trial_completed:
		return _passage(model, "outer")
	if produced < 2:
		return _step("first_line", "准备首批试制材料", "累计催化剂 %d / 2" % produced, "晶体 → 催化剂；样本%s。" % ("已收好" if d.sample_taken else "可稍后拾取"), _first_line(model))
	if not d.sample_taken:
		return _step("sample", "拾取矿壳样本", "首批催化剂已产出", "外矿道 (2, 2)：用 WASD 走近，再按 F 或点击拾取。", _action("location", "定位地面样本", "样本用于试制开路材料。", {"point": Rules.SAMPLE}))
	return _trial(model)


static func _step(id: String, title: String, progress: String, purpose: String, next: Dictionary) -> Dictionary:
	return {"id": id, "title": title, "progress": progress, "purpose": purpose}.merged(next)


static func _action(action: String, label: String, next := "", values := {}) -> Dictionary:
	return {"action": action, "action_label": label, "next": next}.merged(values)


static func _build(type: String, next: String) -> Dictionary:
	return _action("build", "建造" + Rules.CATALOG[type].name, next, {"tool": type})


static func _device(e: Dictionary, next: String) -> Dictionary:
	return _action("device", "查看 %s #%d" % [Rules.CATALOG[e.type].name, e.id], next, {"target_id": e.id})


static func _entities(model: RefCounted, type: String, recipe := "") -> Array:
	var result: Array = []
	for e in model.entities:
		if e.type == type and (recipe.is_empty() or e.get("recipe_id", "") == recipe):
			result.append(e)
	result.sort_custom(func(a, b): return a.id < b.id)
	return result


static func _power(model: RefCounted, e: Dictionary) -> Dictionary:
	var feedback: Dictionary = model.feedback(e)
	var power: String = feedback.get("power", "")
	if power in ["未接线", "不在供电覆盖内"]:
		if _entities(model, "power_source").is_empty():
			return _build("power_source", "先供电：设备中心需在 6 格内；节点互连 12 格。")
		return _device(e, "%s；用节点延伸现有电源，设备 6 格、节点 12 格，矿壳会阻挡。" % power)
	if power == "无启用电源":
		if _entities(model, "power_source").is_empty():
			return _build("power_source", "配电节点只传电；先建一台封装电源，为该网提供电力。")
		var network: int = model.power_state().devices[e.id].network
		for source in _entities(model, "power_source"):
			if model.grid.membership.get(source.id, -1) == network:
				return _device(source, "该网电源已关闭；选中电源后启用，恢复生产。")
		return _device(e, "该网没有电源；用节点接入现有电源覆盖。")
	if power.begins_with("供电不足"):
		return _action("statistics", "查看电力缺口", power + "；增设电源或调整同时运行的产线。")
	return {}


static func _first_line(model: RefCounted) -> Dictionary:
	var collectors := _entities(model, "collector")
	if collectors.is_empty():
		return _build("collector", "把采集器放到西侧青色矿点上。")
	var reactors := _entities(model, "reactor", "basic_catalyst")
	if reactors.is_empty():
		return _build("reactor", "基础反应器：每批 2 晶体 → 1 催化剂。")
	var reactor: Dictionary = reactors[0]
	var power := _power(model, reactor)
	if not power.is_empty():
		return power
	if reactor.processing:
		return _device(reactor, "正在加工 %.1f / 10 秒；保持供电并留出出口。" % reactor.progress)
	if not reactor.output.is_empty():
		return _device(reactor, "出料被占用；接带送仓或走近取出催化剂，才能开始下一批。")
	power = _power(model, collectors[0])
	if not power.is_empty():
		return power
	return _build("belt", "从采集器金色出口铺带，送到反应器青色入口；输出可接仓。")


## Prefer an existing configured recipe, otherwise an empty idle reactor.
static func _reactor(model: RefCounted, recipe: String, east := false) -> Dictionary:
	var reactors := _entities(model, "reactor")
	for e in reactors:
		if e.recipe_id == recipe:
			return e
	for e in reactors:
		if (not east or e.x >= 8) and not e.processing and e.input.is_empty() and e.output.is_empty():
			return e
	return {}


static func _trial(model: RefCounted) -> Dictionary:
	var e := _reactor(model, "solvent_trial")
	var advice: Dictionary
	var progress := "1 样本 + 2 催化剂"
	if e.is_empty():
		advice = _build("reactor", "需要空闲反应器；已有设备须取空输入、输出并完成或取消在制。")
	elif e.recipe_id != "solvent_trial":
		advice = _device(e, "走近打开取放 / 配方，选择「矿壳试制」。")
	elif e.processing:
		progress = "试制 %.1f / 10 秒" % e.progress
		advice = _power(model, e)
		if advice.is_empty():
			advice = _device(e, "材料已投入本批，保持供电等待完成。")
	else:
		advice = _power(model, e)
		if advice.is_empty():
			if not e.output.is_empty():
				advice = _device(e, "先取空输出，为试制产物留出位置。")
			else:
				advice = _trial_material(model, e)
	return _step("trial", "试制开路材料", progress, "完成后掌握解壳剂量产工艺。", advice)


static func _trial_material(model: RefCounted, e: Dictionary) -> Dictionary:
	for item in ["crust_sample", "catalyst"]:
		var needed: int = Rules.RECIPES.solvent_trial.input[item] - e.input.get(item, 0)
		if needed <= 0:
			continue
		if model.bag.get(item, 0) > 0:
			return _device(e, "输入还缺 %d %s；走近从背包放入。" % [needed, Rules.NAMES[item]])
		return _stock(model, item, "试制还缺 %d %s；" % [needed, Rules.NAMES[item]])
	return _device(e, "原料齐全；保持供电，面板内也能观察加工进度。")


static func _stock(model: RefCounted, item: String, prefix: String) -> Dictionary:
	# In-process and belt stock cannot be directly taken. Prefer a terminal warehouse.
	for type in ["storage", "reactor", "collector"]:
		for e in _entities(model, type):
			var available: int = Items.contents(e).get(item, 0) - e.get("invested", {}).get(item, 0)
			if available > 0:
				return _device(e, "%s此处可取 %d 件，走近取到背包。" % [prefix, available])
	return _action("statistics", "查看物料去向", prefix + "查看在途、在制与库存，等待生产或运输完成。")


static func _passage(model: RefCounted, id: String) -> Dictionary:
	var cost: int = Rules.PASSAGES[id].cost
	var carried: int = model.bag.get("crust_solvent", 0)
	var held: int = model.material_balance().held.get("crust_solvent", 0)
	var advice: Dictionary
	if carried >= cost:
		var point := Vector2(Rules.PASSAGES[id].x - 1, 0)
		if model.near_passage(id):
			advice = _action("discovery", "打开矿道操作", "携带量已够；在工艺面板选择对应矿道使用。")
		else:
			advice = _action("location", "定位矿道西侧", "带上解壳剂走到西侧，再从工艺面板使用。", {"point": point})
	elif held > carried:
		advice = _stock(model, "crust_solvent", "尚需携带 %d 件；" % (cost - carried))
	else:
		var e := _reactor(model, "crust_solvent")
		if e.is_empty():
			advice = _build("reactor", "新增解壳剂反应器，或取空已完成试制的设备后切换配方。")
		elif e.recipe_id != "crust_solvent":
			advice = _device(e, "取空输入和输出，选择「解壳剂」：2 催化剂 → 1 份。")
		else:
			advice = _power(model, e)
			if advice.is_empty():
				advice = _device(e, "连接催化剂供料与出料仓；" + ("加工 %.1f / 8 秒。" % e.progress if e.processing else model.feedback(e).production + "。"))
	return _step(id, "打开%s矿道" % ("外" if id == "outer" else "内"), "背包 %d / %d · 总持有 %d" % [carried, cost, held], "解壳剂开辟永久通路；尚需携带 %d。" % maxi(0, cost - carried), advice)


static func _rich(model: RefCounted) -> Dictionary:
	var collectors := _entities(model, "collector").filter(func(e): return e.x >= 8)
	var advice: Dictionary
	if collectors.is_empty():
		advice = _build("collector", "在新矿区 (10, -1) 放采集器，用节点穿过已开矿道供电。")
		advice.cell = Vector2i(10, -1)
	else:
		var e := _reactor(model, "rich_catalyst", true)
		if e.is_empty():
			advice = _build("reactor", "在新矿区建反应器，走近选择「富集催化剂」。")
		elif e.recipe_id != "rich_catalyst":
			advice = _device(e, "走近选择「富集催化剂」，连接新矿点出口。")
		else:
			advice = _power(model, e)
			if advice.is_empty():
				advice = _power(model, collectors[0])
			if advice.is_empty():
				advice = _device(e, "1 富集晶体 → 3 催化剂；" + model.feedback(e).production + "。")
	return _step("rich", "让新矿区反哺生产", "推荐：完成首批富集工艺", "普通线也可继续：携带 8 解壳剂开内矿道。", advice)


static func text(model: RefCounted) -> String:
	return describe(current(model))


static func describe(step: Dictionary) -> String:
	return "%s\n%s\n\n%s\n\n%s" % [step.title, step.progress, step.purpose, step.next]


static func overview(model: RefCounted) -> String:
	if model.supply_id == Rules.Energy.SUPPLY_ID:
		return _expansion_overview(model) + "\n\n能源循环：先完成第二炉，再用 3 包装配发电机。\n工业电芯：1 板 + 2 炭粉 + 1 催化剂 → 1 电芯，组装机 12 秒 / 40 kW。\n每件供能 7,200 kJ，单机最高 120 kW。基础 240 kW 先供，无缺口不烧料。\n电芯由西侧入口送入，最多存 5 件；已激活余能不能取回。\n停下部分扩建负载，保留采集、板材、炭粉、催化剂和电芯生产，可恢复燃料。"
	if model.supply_id == Rules.Expansion.SUPPLY_ID: return _expansion_overview(model)
	var d: Dictionary = model.discovery
	var basic: bool = d.trial_completed or d.passages.outer or d.passages.inner or model.statistics.totals.produced.get("catalyst", 0) >= 2
	var rich: bool = model.statistics.totals.consumed.get("rich_crystal", 0) > 0
	var steps := [
		[basic, "首条产线：晶体 → 催化剂，准备 2 件"],
		[d.sample_taken, "矿壳样本：点地面图标 / 近处按 F"],
		[d.trial_completed, "矿壳试制：1 样本 + 2 催化剂"],
		[d.passages.outer, "外矿道：背包携带 4 解壳剂，西侧使用"],
		[rich, "推荐回流：富集晶体 → 每批 3 催化剂"],
		[d.passages.inner, "内矿道：背包携带 8 解壳剂，西侧使用"],
	]
	var lines := PackedStringArray(["首程步骤 · 当前：" + current(model).title])
	for step in steps:
		lines.append(("✓ " if step[0] else "○ ") + step[1])
	return "\n".join(lines)


static func _expansion(model: RefCounted) -> Dictionary:
	if model.first_expansion_placed:
		return _step("expansion_complete", "第二台精炼炉已落位", "首次扩建完成", "可继续直接工艺；也可用混料回用做两包，决定下一次扩建或停线。", _action("discovery", "比较两种工艺", "4 铁矿 + 1 炭矿 + 1 晶体可做两包；共用粉碎机需换料，精炼炉的矿渣副口要接通。"))
	if model.assembly_counts.refinery > 0:
		return _step("place_second_refinery", "放下第二台精炼炉", "已装配 · 精炼炉库存 %d" % model.kits.refinery, "装配只增加构件库存；实际放下两台炉才完成扩建。", _build("refinery", "第二炉可专做载体，第一炉保留板材；两台均需接入范围电网。"))
	var packs: int = model.material_balance().held.get("construction_pack", 0)
	var carried: int = model.bag.get("construction_pack", 0)
	if carried >= 2:
		return _step("assemble_refinery", "装配第二台精炼炉", "背包 %d / 2 构件包" % carried, "建造栏选择精炼炉，消耗两包增加一个构件，再选择格位放置。", _build("refinery", "在底部装配栏选「精炼炉」并点「装配一批」，然后放置。"))
	if packs >= 2:
		return _step("collect_packs", "取回两包构件", "总持有 %d · 背包 %d / 2" % [packs, carried], "构件装配只使用背包材料。", _stock(model, "construction_pack", "走近取到背包；"))
	var advice: Dictionary
	if _entities(model, "collector").is_empty():
		advice = _build("collector", "铁矿在 (-28, -12)，普通晶体在 (-20, -1)；采集器需接电。")
	elif _entities(model, "refinery").is_empty():
		advice = _build("refinery", "先用直接冶炼做 4 金属板，再取空设备切直接烧结做 2 载体。")
	elif _entities(model, "assembler").is_empty():
		advice = _build("assembler", "每包需 2 金属板 + 1 多孔载体；各入口都接受这两种物料。")
	else:
		var e: Dictionary = _entities(model, "assembler")[0]
		advice = _power(model, e)
		if advice.is_empty(): advice = _device(e, "先备 4 板 + 2 载体做两包。直接工艺共需 8 铁矿、6 晶体；准入口配额可控制备料。")
	return _step("first_packs", "做出两包，制造第二台炉", "构件包持有 %d / 2" % packs, "铁矿 → 板材；晶体 → 载体；板材 + 载体 → 构件包。", advice)


static func _expansion_overview(model: RefCounted) -> String:
	var lines := PackedStringArray(["生产扩建 · " + current(model).title,
		"直接路线：两包需 8 铁矿 + 6 晶体，单炉先板材后载体。",
		"混料回用：两包需 4 铁矿 + 1 炭矿 + 1 晶体；占用炭粉并产矿渣，共用粉碎机需切换。",
		"两包可装配一台设备；封装电源不可制造。回收返构件和物料，不返包。",
		"下列为满供电单机批次，实际产线受物流、缺料和供电约束："])
	for recipe_id in Rules.Expansion.RECIPES:
		var recipe: Dictionary = Rules.Expansion.RECIPES[recipe_id]
		lines.append("%s · %s\n%s → %s · %.0f 秒 / %.0f kW" % [Rules.CATALOG[recipe.machine].name, recipe.name, Items.describe(recipe.input), Items.describe(recipe.output), recipe.seconds, recipe.kw])
	lines.append("直接冶炼 / 烧结适合起步和省操作；混料提高板材产量，矿渣烧结回用副产物、节省晶体。")
	return "\n".join(lines)


static func _energy(model: RefCounted) -> Dictionary:
	if not model.first_expansion_placed: return _expansion(model)
	if model.assembly_counts.cell_generator == 0:
		return _step("first_generator", "制造第一台电芯发电机", "背包 %d / 3 构件包" % model.bag.get("construction_pack", 0), "发电机为扩建提供额外功率；原两套封装电源保留。", _build("cell_generator", "在装配栏选电芯发电机，花 3 包制造。工业电芯需 1 板 + 2 炭粉 + 1 催化剂。"))
	var generators := _entities(model, "cell_generator")
	if generators.is_empty(): return _step("place_generator", "放下电芯发电机", "已有发电机构件", "接近原电网与能源产线，西侧入口收电芯。", _build("cell_generator", "节点互连 12 格、设备接入 6 格；空发电机也能导通原网。"))
	var g: Dictionary = generators[0]
	if model.completed_by_recipe.cell_assembly == 0:
		return _step("first_cells", "把三种原料组装成电芯", "工业电芯尚未产出", "复用基础电源启动能源线，不需预先有电芯。", _action("discovery", "查看电芯工艺", "给组装机接板材、炭粉与催化剂，选工业电芯组装，再接带至发电机。"))
	var state: Dictionary = model.power_state()
	var ledger: Dictionary = model.energy_balance()
	if ledger.activated > 0 and ledger.remaining_kj == 0 and generators.all(func(e): return e.fuel.is_empty()):
		return _step("restore_fuel", "燃料耗尽，恢复能源支线", "基础电源仍可供电", "走近停下部分扩建负载，保留电芯原料和组装；新电芯到货后恢复。", _device(g, "不丢在制；设备停机保留进度与被动物流，发电机按缺口自动接续。"))
	if state.cell_supplied_kw > 0:
		return _step("energy_working", "电芯正在支持扩建", "电芯供电 %.1f kW" % state.cell_supplied_kw, "比较实际加工与入仓速度，再决定是否继续扩建。", _action("statistics", "查看实际供能与产出", "下一目标可做 4 包：3 包制造第二发电机，1 包制造燃料分流器。"))
	return _step("energy_standby", "电芯就绪，按需求扩建", "没有实际输出时不耗电芯", "保留基础供电，增加有料工作的加工机后再观察缺口；无需为了烧料空转。", _device(g, "查看燃料、启停与同网负载；有燃料仍待机可能是基础电源已满足需求。"))
