extends RefCounted

const Rules := preload("res://data/factory/discovery_rules.gd")
const Frontier := Rules.Integrated.Frontier
const Items := preload("res://scripts/factory/items.gd")
const Logistics := preload("res://scripts/factory/logistics.gd")


## Read-only advice derived from existing facts. Never persists separate tutorial progress.
static func current(model: RefCounted) -> Dictionary:
	if Rules.Integrated.matches_supply(model.supply_id): return integrated_location(model)
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


static func integrated_location(model: RefCounted) -> Dictionary:
	if model.map_id == Frontier.MAP_ID and model.researched.has(Frontier.RESEARCH):
		return _frontier_goal(model)
	if model.completed_by_recipe.direct_refining > 0 and not model.discovery.sample_taken:
		return _action("location", "定位矿壳样本", "样本在外矿道入口。走近后按 F 拾取，样本工艺研究会保留实物。", {"point": Rules.SAMPLE})
	if model.supply_id == Rules.Integrated.SUPPLY_ID and model.core.level == 2 and model.statistics.totals.cells_activated > 0:
		var expansion := _foundation_expansion(model)
		if model.discovery.passages.inner:
			if expansion.get("goal_step") == "split_lines":
				return {}
			expansion.mission = "富集矿道已开放\n" + expansion.mission
		return expansion
	var mineral := "iron_ore" if model.completed_by_recipe.direct_refining == 0 else ""
	if model.recipe_available("cell_assembly") and not model.entities.any(func(e): return e.get("mineral", "") == "carbon_ore"):
		mineral = "carbon_ore"
	if not mineral.is_empty():
		for cell in model.ore_sites():
			if model.mineral_at(cell) == mineral:
				var label: String = Items.NAMES[mineral]
				return _action("location", "定位" + label, "已标记%s。按 WASD 移动，查看小地图上的方向。" % label,
					{"point": Vector2(cell) + Vector2.ONE})
	return {}


## Optional schema 9 route selected from the sample panel. Counts describe live inventories.
static func foundation_mine_goal(model: RefCounted) -> Dictionary:
	if model.supply_id != Rules.Integrated.SUPPLY_ID:
		return {}
	if not model.discovery.sample_taken:
		return _production_location("mine_sample", "定位矿壳样本", "拾取试制样本", "走近外矿道地面的样本，按 F 拾取。", Rules.SAMPLE)
	if not model.researched.has(model.Progression.SAMPLE):
		return _production_location("mine_research", "定位基地核心", "研究样本工艺",
			"带样本到核心研究「样本工艺」，再去反应器试制。", model.Grid.center(model.core))
	if not model.discovery.trial_completed:
		return _mine_batch(model, "solvent_trial", "矿壳试制 · 1 样本和 2 催化剂制成 1 件解壳剂")
	for id in ["outer", "inner"]:
		if not model.discovery.passages[id]:
			return _mine_passage(model, id)
	return _mine_rich_return(model)


static func _mine_passage(model: RefCounted, id: String) -> Dictionary:
	var rule: Dictionary = Rules.PASSAGES[id]
	var gate := "外矿道" if id == "outer" else "内矿道"
	var carried: int = model.bag.get("crust_solvent", 0)
	if carried >= rule.cost:
		var advice := "背包有 %d 件解壳剂。走近西侧入口按 F，在「样本与矿道」使用 %d 件。" % [carried, rule.cost]
		return _production_location("mine_" + id, "定位" + gate + "西入口", "打通" + gate, advice, Vector2(rule.x - 1, 0))
	var title := "%s · 背包 %d / %d 件解壳剂，还缺 %d 件" % [gate, carried, rule.cost, rule.cost - carried]
	var stock := _mine_stock(model, "crust_solvent")
	if not stock.is_empty():
		return _mine_pickup(model, stock, "crust_solvent", title)
	return _mine_batch(model, "crust_solvent", title)


static func _mine_stock(model: RefCounted, item: String, include_core := true) -> Dictionary:
	if include_core and model.core.items.has(item):
		return model.core
	for e in model.entities:
		if e.type != Rules.Integrated.CORE and (e.get("items", {}).has(item) or e.get("output", {}).has(item) or e.get("buffer", {}).has(item)):
			return e
	return {}


static func _mine_pickup(model: RefCounted, e: Dictionary, item: String, title: String) -> Dictionary:
	var name: String = Rules.CATALOG[e.type].name
	var count: int = e.get("items", {}).get(item, 0) + e.get("output", {}).get(item, 0) + e.get("buffer", {}).get(item, 0)
	return _production_location("mine_take_" + item, "定位" + name, title,
		"%s有 %d 件%s可取。走近设备取到背包。" % [name, count, Items.NAMES[item]], model.Grid.center(e))


static func _mine_batch(model: RefCounted, recipe: String, title: String) -> Dictionary:
	var reactor := _reactor(model, recipe, false, true)
	var point: Vector2 = model.Grid.center(model.core) if reactor.is_empty() else model.Grid.center(reactor)
	var name: String = model.recipes[recipe].name
	var configured: bool = reactor.get("recipe_id", "") == recipe
	if configured and reactor.processing:
		var status := _production_power_issue(model, reactor)
		return _production_location("mine_processing", "定位反应器", title,
			"本批「%s」已投入。%s" % [name, "等待加工完成，再取出产物。" if status.is_empty() else status], point)
	for item in model.recipes[recipe].input:
		var needed: int = model.recipes[recipe].input[item] - reactor.get("input", {}).get(item, 0) - model.bag.get(item, 0)
		if needed <= 0:
			continue
		var stock := _mine_stock(model, item)
		if not stock.is_empty():
			return _mine_pickup(model, stock, item, title + " · 本批还需取 %d 件%s" % [needed, Items.NAMES[item]])
		if item == "rich_crystal":
			return _mine_rich_site(model, title)
		if item == "catalyst":
			var basic := _preferred_machine(model, "reactor", "basic_catalyst")
			return _production_location("mine_need_catalyst", "定位基地核心" if basic.is_empty() else "定位基础催化剂反应器", title,
				"本批还需 %d 件催化剂。用 2 件普通晶体制 1 件催化剂，或在收货仓取料。" % needed,
				model.Grid.center(model.core if basic.is_empty() else basic))
	if reactor.is_empty():
		var advice := "放置反应器构件并接电，选择「%s」。" % name
		if model.kits.reactor == 0:
			var cost: int = model.assembly_costs.reactor
			if model.core.items.get("construction_pack", 0) + model.bag.get("construction_pack", 0) < cost:
				var packs := _mine_stock(model, "construction_pack", false)
				if not packs.is_empty():
					return _mine_pickup(model, packs, "construction_pack", title + " · 核心装配反应器需 %d 包" % cost)
			advice = "可在核心用 %d 个构件包装配反应器，或腾空已有反应器后选择「%s」。" % [cost, name]
		return _production_location("mine_setup", "定位基地核心", title, advice, point)
	var instruction := "选「%s」，从背包放入%s。" % [name, Items.describe(model.recipes[recipe].input)]
	if configured:
		var power := _production_power_issue(model, reactor)
		instruction = "从背包补齐本批用料（%s）。" % Items.describe(model.recipes[recipe].input)
		if Items.contains(reactor.input, model.recipes[recipe].input):
			instruction = "本批用料已齐。保持供电，完成后取出产物。"
		if not power.is_empty(): instruction += power + "。"
	return _production_location("mine_recipe_" + recipe, "定位反应器", title, instruction, point)


static func _mine_rich_site(model: RefCounted, title: String) -> Dictionary:
	for e in model.entities:
		if e.get("mineral", "") == "rich_crystal":
			var power := _production_power_issue(model, e)
			return _production_location("mine_extract", "定位富集晶体采集器", title,
				"采出后取 1 件富集晶体。" + power, model.Grid.center(e))
	for cell in model.ore_sites():
		if model.mineral_at(cell) == "rich_crystal":
			return _production_location("mine_extract", "定位富集晶体矿点", title,
				"在矿点放置采集器，用配电节点接回基地电网。采出后取 1 件富集晶体。", Vector2(cell) + Vector2.ONE)
	return {}


static func _mine_rich_return(model: RefCounted) -> Dictionary:
	var title := "富集晶体回流 · 1 件富集晶体制成 3 件催化剂"
	var batches: int = model.completed_by_recipe.rich_catalyst
	if batches == 0:
		return _mine_batch(model, "rich_catalyst", title)
	var awaiting_transport := 0
	for e in model.entities:
		if e.get("recipe_id", "") == "rich_catalyst" and e.output.has("catalyst"):
			if _connected_receiver(model, e, "catalyst", Rules.Integrated.CORE).is_empty():
				return _mine_pickup(model, e, "catalyst", "富集产物待回仓")
			awaiting_transport += int(e.output.catalyst)
	var advice := "富集工艺累计 %d 批，核心现有催化剂 %d 件。" % [batches, model.core.items.get("catalyst", 0)]
	if awaiting_transport > 0:
		advice += "回仓线已接到核心，反应器出口还有 %d 件待输送。" % awaiting_transport
	if model.bag.has("catalyst"):
		advice += "背包有 %d 件催化剂，可在核心库存页存入。" % model.bag.catalyst
	elif awaiting_transport == 0:
		advice += "可在核心库存页核对收货，沿反应器出口查看去向。"
	return _production_location("mine_return", "定位基地核心", "核对催化剂回仓", advice, model.Grid.center(model.core))


static func _foundation_expansion(model: RefCounted) -> Dictionary:
	var core: Vector2 = model.Grid.center(model.core)
	if not model.recipe_available("mixed_refining"):
		return _production_location("research_mixed", "定位基地核心", "研究混料冶炼",
			"在核心研究「混料冶炼」，让精炼炉联产板材和矿渣。", core)
	if model.completed_by_recipe.mixed_refining == 0:
		return _foundation_furnace(model, "mixed_refining")
	if not model.recipe_available("slag_sintering"):
		var cost: Dictionary = model.research_nodes[model.Progression.REUSE].cost
		var slag: int = model.core.items.get("mineral_slag", 0)
		var mixed := _preferred_machine(model, "refinery", "mixed_refining")
		if slag + model.bag.get("mineral_slag", 0) < cost.mineral_slag and not mixed.is_empty():
			return _production_location("collect_slag", "定位混料精炼炉", "收集副口矿渣",
				"将副口矿渣送回核心，或就地取出再存入。回用研究需要 %d 件矿渣。" % cost.mineral_slag, model.Grid.center(mixed))
		return _production_location("research_reuse", "定位基地核心", "研究矿渣回用",
			"核心现有矿渣 %d 件。存入所需的 %d 件矿渣和 %d 件晶体，在研究页提交。" % [slag, cost.mineral_slag, cost.crystal], core)
	if model.completed_by_recipe.slag_sintering == 0:
		return _foundation_furnace(model, "slag_sintering")
	return _foundation_packs(model)


static func _foundation_furnace(model: RefCounted, recipe: String) -> Dictionary:
	var name: String = model.recipes[recipe].name
	var furnace := _preferred_machine(model, "refinery", recipe)
	var label := "定位混料精炼炉" if recipe == "mixed_refining" else "定位矿渣烧结炉"
	var advice := "主口板材送回核心，副口矿渣留作回用。" if recipe == "mixed_refining" else "主口的多孔载体送回核心，用来组装构件包。"
	if furnace.is_empty():
		label = "定位精炼炉"
		furnace = _preferred_machine(model, "refinery")
		if furnace.is_empty():
			return _production_location(recipe, "定位基地核心", "建立" + name, "放置精炼炉并接电，再选择「%s」。%s" % [name, advice], model.Grid.center(model.core))
		advice = "腾空精炼炉后选「%s」，或另设一台。%s" % [name, advice]
	else:
		advice = _refinery_status(model, furnace).text + advice
	return _production_location(recipe, label, "投产" + name, advice, model.Grid.center(furnace))


static func _foundation_packs(model: RefCounted) -> Dictionary:
	var core: Vector2 = model.Grid.center(model.core)
	var stock: Dictionary = model.core.items
	var cost: int = model.assembly_costs.refinery
	var packs: int = stock.get("construction_pack", 0)
	if model.kits.refinery > 0:
		var advice := "可将混料冶炼和矿渣烧结分开运行。"
		var has_mixed: bool = model.entities.any(func(e): return e.get("recipe_id") == "mixed_refining")
		var has_reuse: bool = model.entities.any(func(e): return e.get("recipe_id") == "slag_sintering")
		if has_mixed and has_reuse:
			advice = "组装机等板材时，可用新炉直炼铁矿补板。到收货仓比较构件包的入仓间隔。"
		var ready := _build("refinery", "把精炼炉放在供料线旁并接电。" + advice)
		ready.mission = "精炼炉构件可放置\n建造库存 %d 台。%s" % [model.kits.refinery, advice]
		return ready
	var receiver := _expanded_pack_receiver(model)
	if not receiver.is_empty():
		var full: bool = model.input_room(receiver, "construction_pack") == 0
		var title := "构件包收货仓已满" if full else "核对扩建后的构件包实收"
		var advice := "靠近收货仓，取出物料腾出仓位。" if full else "比较相同时间内的入仓包数。"
		var stock_text := "沿线收货仓 #%d 现存 %d 包。" % [receiver.id, receiver.items.get("construction_pack", 0)]
		return _production_location("review_pack_receipts", "定位构件包收货仓", title, advice + stock_text, model.Grid.center(receiver))
	if packs >= cost:
		var advice := "核心现有 %d 个构件包。在「装配」页用 %d 包装配一台精炼炉。" % [packs, cost]
		if model.owned_count() >= model.Progression.MAX_OWNED:
			advice = "构件总拥有量已达上限。可调整现有炉的配方，或从样本与矿道面板继续探索。"
		return _production_location("assemble_refinery", "定位基地核心", "查看扩建用构件", advice, core)
	if model.bag.get("construction_pack", 0) + packs >= cost:
		return _production_location("deposit_packs", "定位基地核心", "把构件包存入核心",
			"靠近核心存入构件包，再到「装配」页选择精炼炉。", core)
	var press := _preferred_machine(model, "assembler", "construction_assembly")
	var inventory := "核心现有板材 %d、载体 %d。" % [stock.get("metal_plate", 0), stock.get("porous_carrier", 0)]
	if press.is_empty():
		press = _preferred_machine(model, "assembler")
		var point: Vector2 = core if press.is_empty() else model.Grid.center(press)
		return _production_location("setup_packs", "定位基地核心" if press.is_empty() else "定位组装机", "准备构件包组装",
			inventory + "另设组装机或腾空现有设备，选择「构件包组装」。", point)
	var target: Vector2 = model.Grid.center(press)
	var terminal := _connected_receiver(model, press, "construction_pack", "storage")
	var stored: int = terminal.get("items", {}).get("construction_pack", 0)
	var needed: int = cost - packs - model.bag.get("construction_pack", 0)
	if stored >= needed:
		return _production_location("collect_stored_packs", "定位构件包收货仓", "把构件包送回核心",
			"收货仓现有 %d 包。取 %d 包存入核心，即可装配精炼炉。" % [stored, needed], model.Grid.center(terminal))
	if press.output.get("construction_pack", 0) > 0 and terminal.is_empty():
		return _production_location("collect_packs", "定位构件包组装机", "把新构件包送回核心",
			"从组装机取包，或沿出料带到收货仓取包。核心装配一台精炼炉需要 %d 包。" % cost, target)
	if not press.processing and not press.input.has("porous_carrier") and not stock.has("porous_carrier") and not model.bag.has("porous_carrier"):
		var split := _foundation_split_furnaces(model)
		if not split.is_empty():
			return split
		var furnace := _preferred_machine(model, "refinery", "slag_sintering")
		if not furnace.is_empty():
			return _production_location("return_carriers", "定位矿渣烧结炉", "将载体送回核心或组装机",
				"烧结累计 %d 批，核心现有载体 0 件。检查主口出料去向，或就地取货。" % model.completed_by_recipe.slag_sintering, model.Grid.center(furnace))
	var power := _production_power_issue(model, press)
	var recipe: Dictionary = model.recipes.construction_assembly.input
	var instruction := "每包用 %d 板材和 %d 载体。取料或接带供料，将构件包送回核心。" % [recipe.metal_plate, recipe.porous_carrier]
	if not power.is_empty():
		instruction = "组装机：" + power + "。"
	elif press.output.get("construction_pack", 0) > 0:
		instruction = "构件包在组装机出口等待输送。可沿出料带检查到收货仓的线路。"
	elif press.processing:
		instruction = "组装机正在做包。完成后可从组装机取包，存入核心装配。"
		if not terminal.is_empty():
			return _production_location("make_packs", "定位构件包收货仓", "等待构件包入仓",
				"组装机正在做包。收货仓现有 %d 包，再到仓 %d 包即可备齐本次装配用料。" % [stored, needed - stored], model.Grid.center(terminal))
	if stored > 0:
		instruction += "收货仓现有 %d 包，还差 %d 包。" % [stored, needed - stored]
	return _production_location("make_packs", "定位构件包组装机", "用板材和载体扩建", inventory + instruction, target)


static func _expanded_pack_receiver(model: RefCounted) -> Dictionary:
	if model.assembly_counts.refinery == 0 or model.statistics.totals.delivered.get("construction_pack", 0) < 2:
		return {}
	var furnaces := _entities(model, "refinery")
	if not furnaces.any(func(e): return e.recipe_id == "mixed_refining") or not furnaces.any(func(e): return e.recipe_id == "slag_sintering"):
		return {}
	# Placement IDs are ordered. Only consider capacity added beyond the starter furnace.
	for furnace in furnaces.slice(Rules.Integrated.SUPPLY.refinery):
		if furnace.recipe_id != "direct_refining" or not furnace.enabled or furnace.power_node_id == 0:
			continue
		if furnace.invested.is_empty() and furnace.input.is_empty() and furnace.output.is_empty():
			continue
		if not Logistics.ports(model, furnace, "input").any(func(p): return Logistics.input_connection(model, furnace, p).ok):
			continue
		if not _production_power_issue(model, furnace).is_empty():
			continue
		for press in _entities(model, "assembler", "construction_assembly"):
			if not _production_power_issue(model, press).is_empty():
				continue
			if _connected_receiver(model, furnace, "metal_plate", "assembler", "construction_assembly", press.id).is_empty():
				continue
			var terminal := _connected_receiver(model, press, "construction_pack", "storage")
			if not terminal.is_empty() and (model.input_room(terminal, "construction_pack") == 0 or _recent_pack_arrivals(model)):
				return terminal
	return {}


static func _recent_pack_arrivals(model: RefCounted) -> bool:
	# The HUD only needs two receipts. Avoid aggregating every material and power field on refresh.
	var buckets: Array = model.statistics.buckets
	var received := 0
	for offset in mini(300, buckets.size()):
		received += int(buckets[-1 - offset].delivered.get("construction_pack", 0))
		if received >= 2:
			return true
	return false


static func _foundation_split_furnaces(model: RefCounted) -> Dictionary:
	var mixed := _preferred_machine(model, "refinery", "mixed_refining")
	var reuse := _preferred_machine(model, "refinery", "slag_sintering")
	if not mixed.is_empty() and not reuse.is_empty():
		for furnace in [mixed, reuse]:
			var is_mixed: bool = furnace == mixed
			var name := "混料精炼炉" if is_mixed else "矿渣烧结炉"
			var advice := _split_line_issue(model, furnace)
			if not advice.is_empty():
				return _production_location("connect_" + furnace.recipe_id, "定位" + name, "接通" + name,
					advice, model.Grid.center(furnace))
		return _production_location("split_lines", "定位矿渣烧结炉", "混料与回用已分炉",
			"给两台炉持续供料；可在生产统计查看实际产出，或从样本与矿道面板继续开路。", model.Grid.center(reuse))
	# Offer a free-standing empty furnace without diverting an existing production line.
	for furnace in _entities(model, "refinery", "direct_refining"):
		if not furnace.enabled or furnace.processing or not furnace.input.is_empty() or not furnace.output.is_empty():
			continue
		if Logistics.ports(model, furnace, "input").any(func(p): return Logistics.input_connection(model, furnace, p).ok):
			continue
		if Logistics.ports(model, furnace, "output").any(func(p): return Logistics.output_connection(model, p).ok):
			continue
		var name: String = model.recipes.mixed_refining.name if mixed.is_empty() else model.recipes.slag_sintering.name
		return _production_location("configure_furnace", "定位空闲精炼炉", "配置扩建用的精炼炉",
			"这台炉尚未接线。选「%s」，接电并送入原料。" % name, model.Grid.center(furnace))
	return {}


static func _split_line_issue(model: RefCounted, furnace: Dictionary) -> String:
	var power := _production_power_issue(model, furnace)
	if not power.is_empty():
		return power + "。检查设备启停与电网连接。"
	var mixed: bool = furnace.recipe_id == "mixed_refining"
	var inputs := Logistics.ports(model, furnace, "input")
	if not inputs.any(func(p): return Logistics.input_connection(model, furnace, p).ok):
		return "进料口尚未接通。接入铁粉和炭粉，主口出板材，副口出矿渣。" if mixed else "进料口尚未接通。接入混料炉的矿渣和晶体。"
	for port in Logistics.ports(model, furnace, "output"):
		if port.index == 1 and not mixed:
			continue
		var connection := Logistics.output_connection(model, port)
		if not connection.ok:
			var outlet := "副口矿渣" if port.index == 1 else ("主口板材" if mixed else "主口载体")
			return outlet + "：" + connection.reason + "。检查出料带与下游入口。"
	if not furnace.output.is_empty():
		var status := _refinery_status(model, furnace)
		if status.needs_attention:
			return status.text
	return ""


static func _frontier_step(model: RefCounted) -> String:
	if not model.discovery.passages.outer:
		return "outer"
	if not model.discovery.passages[Frontier.PASSAGE]:
		return "capsules" if model.bag.get(Frontier.CAPSULE, 0) < Frontier.OPEN_COST else "branch"
	if model.kits.get("collector", 0) == 0 and model.entity_at(Frontier.ORE).get("type") != "collector":
		return "collector"
	return "return_ore"


static func _frontier_goal(model: RefCounted) -> Dictionary:
	var step := _frontier_step(model)
	var action: Dictionary
	var mission: String
	match step:
		"outer":
			mission = "打开外矿道\n背包解壳剂 %d / %d。靠近西侧入口后按 F。" % [
				model.bag.get("crust_solvent", 0), Rules.PASSAGES.outer.cost]
			if model.near_passage("outer"):
				action = _action("discovery", "查看外矿道操作", "在样本与矿道面板用解壳剂打通外矿道。")
			else:
				action = _action("location", "定位外矿道", "沿小地图走到外矿道西侧入口。",
					{"point": Vector2(Rules.PASSAGES.outer.x - 1, 0)})
		"capsules":
			var assembler := _capsule_assembler(model)
			var at_core := assembler.is_empty()
			var advice := "回工厂，在组装机选「破岩胶囊组装」。缺解壳剂时，用反应器的「载体解壳剂」补料。"
			if at_core:
				advice = "回工厂腾空一台组装机，或在核心装配一台，再选「破岩胶囊组装」。"
			mission = "制作破岩胶囊\n背包胶囊 %d / %d。%s" % [model.bag.get(Frontier.CAPSULE, 0), Frontier.OPEN_COST, advice]
			action = _action("location", "定位基地核心" if at_core else "定位胶囊组装机", advice,
				{"point": model.Grid.center(model.core if at_core else assembler)})
		"branch":
			mission = "开拓高产炭矿\n背包胶囊 %d / %d。靠近北入口后按 F。" % [model.bag.get(Frontier.CAPSULE, 0), Frontier.OPEN_COST]
			if model.near_passage(Frontier.PASSAGE):
				action = _action("discovery", "查看炭矿支路操作", "在样本与矿道面板提交破岩胶囊。")
			else:
				action = _action("location", "定位炭矿支路入口", "沿小地图走到炭矿支路北入口。",
					{"point": Vector2(Frontier.MOUTH.get_center().x, Frontier.MOUTH.position.y - 1)})
		"collector":
			var cost: int = model.assembly_costs.collector
			var stocked: int = model.core.items.get("construction_pack", 0)
			var collector_name: String = Rules.CATALOG.collector.name
			var advice := "在核心「装配」页用 %d 个构件包装配「%s」，或回收闲置采集器。" % [cost, collector_name]
			if stocked < cost:
				advice = "装配「%s」需 %d 个构件包（核心已有 %d）。先取包存入核心，也可回收闲置采集器。" % [collector_name, cost, stocked]
			mission = "补充采集器\n" + advice
			action = _action("location", "定位基地核心", advice, {"point": model.Grid.center(model.core)})
		_:
			return _frontier_production(model)
	action.goal_step = step
	action.mission = mission
	return action


static func _frontier_production(model: RefCounted) -> Dictionary:
	var mine: Dictionary = model.entity_at(Frontier.ORE)
	var ore_point := Vector2(Frontier.ORE) + Vector2.ONE
	var mined := "高产点累计采出 %d 件。" % model.frontier_extracted
	if mine.get("type") != "collector":
		return _production_location("return_ore", "定位高产炭矿", "架设高产采集器",
			"覆盖矿点，接电后把炭矿送回粉碎机。", ore_point)
	var crusher := _connected_receiver(model, mine, "carbon_ore", "crusher", "carbon_crushing")
	if crusher.is_empty():
		return _production_location("return_ore", "定位高产炭矿", "接回高产炭矿",
			mined + "炭矿还没有通往炭矿粉碎机的线路。检查传送带、汇合器和物品准入口。", ore_point)
	var mine_power := _production_power_issue(model, mine)
	if not mine_power.is_empty():
		return _production_location("return_ore", "定位高产炭矿", "启动高产采集器",
			"回流线已接到粉碎机。采集器：" + mine_power + "。", ore_point)
	var crusher_power := _production_power_issue(model, crusher)
	var receiving: bool = crusher.input.has("carbon_ore") or crusher.invested.has("carbon_ore") or crusher.output.has("carbon_powder")
	var mixed := _preferred_machine(model, "refinery", "mixed_refining")
	if not crusher_power.is_empty() or model.frontier_extracted == 0 or (not receiving and model.completed_by_recipe.mixed_refining == 0):
		var advice := "回流线已接通。粉碎机等炭矿到达，可沿带查看货物。" if crusher_power.is_empty() else "回流线已接通。粉碎机：" + crusher_power + "。"
		return _production_location("crushing", "定位炭矿粉碎机", "查看炭矿回流", mined + advice, model.Grid.center(crusher))
	if mixed.is_empty():
		var furnace := _preferred_machine(model, "refinery")
		if model.recipe_available("mixed_refining") and not furnace.is_empty():
			return _production_location("mixed_setup", "定位精炼炉", "建立混料冶炼",
				"粉碎机已收到炭矿。选「混料冶炼」，给炉子送铁粉和炭粉，电芯线继续补料。", model.Grid.center(furnace))
		var advice := "装配并放置精炼炉，再选择「混料冶炼」。" if model.recipe_available("mixed_refining") else "到核心研究「混料冶炼」，再给精炼炉接铁粉和炭粉。"
		return _production_location("mixed_setup", "定位基地核心", "建立混料冶炼", advice, model.Grid.center(model.core))
	var batches: int = model.completed_by_recipe.mixed_refining
	if batches == 0:
		return _production_location("mixed", "定位混料精炼炉", "投产混料冶炼", _refinery_status(model, mixed).text, model.Grid.center(mixed))
	var reuse := _preferred_machine(model, "refinery", "slag_sintering")
	if reuse.is_empty():
		var expansion := "混料累计 %d 批。%s\n用板材做构件包扩建；矿渣留给「矿渣回用」。" % [batches, _refinery_status(model, mixed).text]
		if model.kits.get("refinery", 0) > 0:
			return _production_location("expansion", "定位混料精炼炉", "扩建矿渣烧结线",
				"已有精炼炉构件。放置、接电后选择「矿渣烧结」。\n" + expansion, model.Grid.center(mixed))
		if model.core.items.get("construction_pack", 0) >= model.assembly_costs.refinery:
			return _production_location("expansion", "定位基地核心", "装配扩建用的精炼炉",
				"在核心用 %d 个构件包装配精炼炉。\n%s" % [model.assembly_costs.refinery, expansion], model.Grid.center(model.core))
		return _production_location("expansion", "定位混料精炼炉", "用混料产出扩建", expansion, model.Grid.center(mixed))
	var connected := not _connected_receiver(model, reuse, "porous_carrier", Rules.Integrated.CORE).is_empty()
	var reuse_status := _refinery_status(model, reuse)
	if not connected:
		return _production_location("reuse", "定位矿渣烧结炉", "把载体送回核心",
			reuse_status.text + "\n沿主出口检查回仓线和物品准入口。", model.Grid.center(reuse))
	var reused: int = model.completed_by_recipe.slag_sintering
	var stock: int = model.core.items.get("porous_carrier", 0)
	if reused == 0 or reuse_status.needs_attention:
		var detail: String = reuse_status.text + "\n载体回仓线已接通。"
		if reused > 0:
			detail += "累计烧结 %d 批，核心现有载体 %d 件。" % [reused, stock]
		return _production_location("reuse", "定位矿渣烧结炉", "运行矿渣烧结线", detail, model.Grid.center(reuse))
	return _production_location("reuse_result", "定位基地核心", "查看矿渣回用成果",
		"矿渣烧结累计 %d 批，载体回仓线已接通。核心现有载体 %d 件。" % [reused, stock],
		model.Grid.center(model.core))


static func _production_location(step: String, label: String, title: String, advice: String, point: Vector2) -> Dictionary:
	return _action("location", label, advice.get_slice("\n", 0), {"point": point, "goal_step": step, "mission": title + "\n" + advice})


static func _preferred_machine(model: RefCounted, type: String, recipe := "") -> Dictionary:
	var options := _entities(model, type, recipe)
	for option in options:
		if option.enabled and option.power_node_id != 0:
			return option
	return options[0] if not options.is_empty() else {}


static func _production_power_issue(model: RefCounted, entity: Dictionary) -> String:
	var status: Dictionary = model.feedback(entity)
	if not entity.enabled or entity.power_node_id == 0 or (status.kind == "waiting" and status.label == status.power):
		return status.power
	return ""


static func _refinery_status(model: RefCounted, furnace: Dictionary) -> Dictionary:
	var power := _production_power_issue(model, furnace)
	if not power.is_empty():
		return {"text": "精炼炉：" + power + "。", "needs_attention": true}
	if furnace.processing:
		return {"text": "精炼炉正在加工。", "needs_attention": false}
	if not furnace.output.is_empty():
		var waits := PackedStringArray()
		for port in Logistics.ports(model, furnace, "output"):
			var item: String = model._output_item_at(furnace, port)
			if item.is_empty():
				continue
			var status := Logistics.output_status(model, furnace, port, item)
			if status.ok:
				continue
			var next: Dictionary = Logistics.output_connection(model, port).get("target", {})
			# An occupied belt can still be carrying the preceding unit out of the way.
			if next.get("type") in ["belt", "merger", "splitter"] and not next.cargo.is_empty() and Logistics.feedback(model, next).kind != "blocked":
				continue
			waits.append(Items.NAMES[item] + "：" + status.reason)
		if waits.is_empty():
			return {"text": "等待出料。", "needs_attention": false}
		return {"text": "出料受阻 · " + "；".join(waits) + "。", "needs_attention": true}
	var missing := PackedStringArray()
	for item in model.recipes[furnace.recipe_id].input:
		if furnace.input.get(item, 0) < model.recipes[furnace.recipe_id].input[item]:
			missing.append(Items.NAMES[item])
	if missing.is_empty():
		return {"text": "原料齐全，等待开批。", "needs_attention": false}
	return {"text": "精炼炉缺" + "、".join(missing) + "。", "needs_attention": true}


static func _connected_receiver(model: RefCounted, source: Dictionary, item: String, receiver: String, recipe := "", receiver_id := -1) -> Dictionary:
	var pending: Array[Dictionary] = [source]
	var visited := {int(source.id): true}
	var first_match := {}
	var i := 0
	while i < pending.size():
		var entity := pending[i]
		i += 1
		for output in Logistics.ports(model, entity, "output"):
			if entity.type == "refinery" and output.index != 0:
				continue
			var connection := Logistics.output_connection(model, output)
			if not connection.ok:
				continue
			var target: Dictionary = connection.target
			if visited.has(target.id):
				continue
			visited[target.id] = true
			if target.type == receiver and (recipe.is_empty() or target.recipe_id == recipe) and (receiver_id == -1 or target.id == receiver_id):
				if receiver in [Rules.Integrated.CORE, "storage"] or (target.enabled and target.power_node_id != 0):
					return target
				if first_match.is_empty():
					first_match = target
			elif Logistics.transport(target):
				# A full slot can drain along the route. A closed or mismatched gate cannot accept new cargo.
				if target.type != "admission_gate" or Logistics.Admission.receive_reason(target.merged({"cargo": ""}, true), item).is_empty():
					pending.append(target)
	return first_match


static func _capsule_assembler(model: RefCounted) -> Dictionary:
	var idle := {}
	for entity in model.entities:
		if entity.type != "assembler":
			continue
		if entity.recipe_id == "boring_capsule_assembly":
			return entity
		if idle.is_empty() and not entity.processing and entity.input.is_empty() and entity.output.is_empty():
			idle = entity
	return idle


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
static func _reactor(model: RefCounted, recipe: String, east := false, preserve_feed := false) -> Dictionary:
	var reactors := _entities(model, "reactor")
	for e in reactors:
		if e.recipe_id == recipe:
			return e
	for e in reactors:
		if (not east or e.x >= 8) and not e.processing and e.input.is_empty() and e.output.is_empty():
			if preserve_feed and Logistics.input_connection(model, e, Logistics.ports(model, e, "input")[0]).ok:
				continue
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
