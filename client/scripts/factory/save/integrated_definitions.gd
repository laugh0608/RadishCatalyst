extends RefCounted

const Model := preload("res://scripts/factory/integrated_model.gd")
const Rules := Model.Integrated
const Config := Model.DiscoveryRules
const Tech := Model.Progression
const Energy := Model.Energy
const PIN := "8d01970aec43e6f2f56893f01f124ab0e830f91a8886dbdd14761e5dc21a4f98"
static var digest := ""


static func sha256() -> String:
	if not digest.is_empty():
		return digest
	var recipes := Config.RECIPES.merged(Config.Expansion.RECIPES).merged(Energy.RECIPES).duplicate(true)
	for id in recipes:
		recipes[id].erase("name")
	var research := Tech.NODES.duplicate(true)
	for id in research:
		research[id].erase("name")
		research[id].erase("effect")
	var devices := {}
	for type in Rules.SUPPLY.keys() + [Rules.CORE, Energy.GENERATOR]:
		var spec: Dictionary = Config.CATALOG[type].duplicate()
		spec.erase("name")
		for key in ["input", "output"]:
			if spec.has(key):
				spec[key] = [spec[key].x, spec[key].y]
		devices[type] = spec
	var ports := {}
	for role in ["input", "output"]:
		ports[role] = []
		for port in Rules.ports(Vector2i.ZERO, role):
			ports[role].append([port.id, port.x, port.z, port.dx, port.dz, port.index])
	var minerals := []
	var cycles := {}
	for cell in Config.ore_sites(Rules.MAP_ID):
		var mineral := Config.mineral_at(cell, Rules.MAP_ID)
		minerals.append([cell.x, cell.y, mineral])
		cycles[mineral] = Config.Expansion.cycle(mineral)
	var map_masks := []
	for flags in [{"outer": false, "inner": false}, {"outer": true, "inner": false}, {"outer": true, "inner": true}]:
		var mask := PackedByteArray()
		for z in range(-32, 32):
			for x in range(-32, 32):
				mask.append(int(Config.open_cell(Vector2i(x, z), flags, Rules.MAP_ID)))
		var hash := HashingContext.new()
		hash.start(HashingContext.HASH_SHA256)
		hash.update(mask)
		map_masks.append(hash.finish().hex_encode())
	var definition := {"recipes": recipes, "research": research, "tier_ii": [Tech.II_REQUIRES, Tech.II_COST],
		"devices": devices, "supply": Rules.SUPPLY, "assembly": Config.Expansion.ASSEMBLY_COST.merged({Energy.GENERATOR: 3}),
		"belt_assembly_yield": Config.Expansion.yield_for("belt"), "max_owned": Tech.MAX_OWNED,
		"core": [[Rules.CORE_CELL.x, Rules.CORE_CELL.y], Rules.ITEM_LIMIT, Rules.COOLDOWN_TICKS, ports],
		"map": [Rules.MAP_ID, map_masks, minerals, cycles, [Rules.SPAWN.x, Rules.SPAWN.y], [Config.SAMPLE.x, Config.SAMPLE.y], Config.PASSAGES],
		"processor_ports": Config.Expansion.PORTS, "step": Model.STEP,
		"power": [Rules.BASE_KW, Config.NODE_RANGE, Config.CONSUMER_RANGE, Config.POWER, Energy.STANDBY_KW,
			Energy.GENERATOR_KW, Energy.FUEL_CAPACITY, Energy.CELL_KJ, Rules.BURN_TICKS]}
	digest = JSON.stringify(definition, "", true, true).sha256_text()
	return digest
