extends "res://scripts/factory/integrated_model.gd"

const Frontier := Integrated.Frontier
var frontier_extracted := 0


func _init() -> void:
	super()
	map_id = Frontier.MAP_ID
	supply_id = Frontier.SUPPLY_ID
	discovery.passages[Frontier.PASSAGE] = false
	research_nodes = Progression.NODES.merged({Frontier.RESEARCH: Frontier.NODE})
	recipes.merge(Frontier.RECIPES)
	for id in Frontier.RECIPES:
		completed_by_recipe[id] = 0
	item_ids.append(Frontier.CAPSULE)
	admission_items.append(Frontier.CAPSULE)


func research_fact_missing(id: String) -> String:
	if id == Frontier.RESEARCH and not discovery.trial_completed:
		return "先完成一次矿壳试制"
	return super.research_fact_missing(id)


func item_known(item: String) -> bool:
	if item == Frontier.CAPSULE:
		return researched.has(Frontier.RESEARCH)
	return super.item_known(item)


func configure_output(id: int, port_id: String, item: String, enabled: bool) -> Dictionary:
	if item == Frontier.CAPSULE and not item_known(item):
		return failure("先研究开拓工具")
	return super.configure_output(id, port_id, item, enabled)


func collector_cycle(e: Dictionary) -> float:
	return Frontier.ORE_SECONDS if Vector2i(e.x, e.z) == Frontier.ORE else super.collector_cycle(e)


func _collected(e: Dictionary) -> void:
	super._collected(e)
	if Vector2i(e.x, e.z) == Frontier.ORE:
		frontier_extracted += 1


func near_passage(id: String) -> bool:
	if id != Frontier.PASSAGE:
		return super.near_passage(id)
	var position := Vector2(actor.x, actor.z)
	var mouth: Rect2i = Frontier.MOUTH
	var target := Vector2(clampf(position.x, mouth.position.x + 0.001, mouth.end.x - 0.001), mouth.position.y - 0.001)
	return position.y < mouth.position.y and position.distance_to(target) <= 2.0 and Grid.line_open(position, target, discovery.passages, map_id)


func frontier_status() -> Dictionary:
	if discovery.passages[Frontier.PASSAGE]:
		return failure("高产炭矿支路已经打通")
	if not discovery.passages.outer:
		return failure("先打通外矿道")
	if not researched.has(Frontier.RESEARCH):
		return failure("先在核心研究开拓工具")
	if not near_passage(Frontier.PASSAGE):
		return failure("请走到支路北入口两格内")
	if bag.get(Frontier.CAPSULE, 0) < Frontier.OPEN_COST:
		return failure("背包需要 %d 颗破岩胶囊" % Frontier.OPEN_COST)
	return success()


func open_passage(id: String) -> Dictionary:
	if id != Frontier.PASSAGE:
		return super.open_passage(id)
	var status := frontier_status()
	return _commit_passage(id, Frontier.CAPSULE, Frontier.OPEN_COST) if status.ok else status


func passage_consumption() -> Dictionary:
	var consumed := super.passage_consumption()
	if discovery.passages[Frontier.PASSAGE]:
		consumed[Frontier.CAPSULE] = Frontier.OPEN_COST
	return consumed
