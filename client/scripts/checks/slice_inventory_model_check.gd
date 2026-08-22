extends SceneTree

var failures: Array[String] = []
var _assertion_count := 0


func _init() -> void:
	call_deferred("_execute")


func _execute() -> void:
	_check_item_catalog()
	_check_legacy_total_behavior()
	_check_schema_seven_roundtrip_and_views()
	_check_trusted_over_capacity_restore()
	_check_atomic_batches_and_exchange()
	_check_atomic_transfer()
	_check_future_per_item_and_type_limit()
	_check_category_profiles_and_read_models()
	if failures.is_empty():
		print(
			"Slice inventory model checks passed (%d assertions)."
			% _assertion_count
		)
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)


func _check_item_catalog() -> void:
	var expected_ids: Array[String] = [
		"crystal",
		"catalyst",
		"part",
		"weapon.pulse_rifle",
		"ammo.pulse_cell",
		"building.floor",
		"building.collector",
		"building.reactor",
		"building.power_relay",
		"building.conveyor",
		"building.storage",
	]
	var definitions := SliceItemCatalog.all()
	_expect_equal(definitions.size(), 11, "catalog keeps eleven ordinary items")
	var actual_ids: Array[String] = []
	for definition in definitions:
		actual_ids.append(definition.item_id)
		_expect_equal(
			definition.icon_path.is_empty(),
			false,
			"%s has an icon path" % definition.item_id
		)
	_expect_equal(actual_ids, expected_ids, "catalog order stays UI-compatible")
	var pulse_rifle := SliceItemCatalog.find(SliceItemCatalog.PULSE_RIFLE_ID)
	_expect_equal(
		pulse_rifle.icon_path,
		"res://assets/sprites/slice/pulse_rifle_item_icon.png",
		"pulse rifle uses its standalone item icon"
	)
	_expect_equal(
		pulse_rifle.icon_region,
		Rect2(),
		"standalone pulse rifle icon does not crop a player-pose sheet"
	)
	_expect_equal(
		SliceItemCatalog.transportable_ids(),
		["crystal", "catalyst"],
		"only current belt cargo is transportable"
	)
	_expect_equal(
		SliceItemCatalog.find("building.collector").display_name,
		"采集器套件",
		"building kit keeps its item display name"
	)
	_expect_equal(
		SliceItemCatalog.find("building.collector").short_name,
		"采集器",
		"building kit keeps its compact display name"
	)
	_expect_equal(
		SliceItemCatalog.find(SliceItemCatalog.CRITICAL_SAMPLE_PRESENTATION_ID),
		null,
		"critical sample never enters the ordinary item lookup"
	)
	_expect_equal(
		SliceItemCatalog.critical_sample_read_model(true)["category"],
		SliceItemDefinition.CATEGORY_KEY_ITEM,
		"critical sample has an independent key-item presentation"
	)


func _check_legacy_total_behavior() -> void:
	var inventory := Inventory.new(3)
	_expect_equal(inventory.capacity, 3, "legacy constructor exposes capacity")
	_expect_equal(inventory.free_space(), 3, "empty legacy space")
	_expect_equal(inventory.free_space_for("crystal"), 3, "named legacy space")
	_expect_equal(inventory.add("crystal", 2), 2, "legacy add stores full fit")
	_expect_equal(inventory.add("part", 2), 1, "legacy add stores partial fit")
	_expect_equal(inventory.total(), 3, "different items share legacy capacity")
	_expect_equal(inventory.is_full(), true, "legacy inventory reports full")
	_expect_equal(inventory.add("catalyst", 1), 0, "full legacy add is blocked")
	_expect_equal(inventory.remove("crystal", 1), 1, "remove returns actual amount")
	_expect_equal(inventory.free_space(), 1, "remove releases aggregate space")
	var named_capacities := {
		"pocket": [SliceInventoryProfiles.legacy_pocket(), 30],
		"core": [SliceInventoryProfiles.legacy_core_storage(), 120],
		"storage": [SliceInventoryProfiles.legacy_storage(), 20],
		"reactor_input": [SliceInventoryProfiles.legacy_reactor_input(), 2],
		"reactor_output": [SliceInventoryProfiles.legacy_reactor_output(), 1],
	}
	for profile_name in named_capacities:
		var expectation: Array = named_capacities[profile_name]
		_expect_equal(
			Inventory.new(expectation[0]).capacity,
			expectation[1],
			"%s legacy profile preserves capacity" % profile_name
		)
	_expect_equal(
		Inventory.new(-1).to_dict(),
		{"capacity": -1, "contents": {}},
		"legacy compatibility preserves non-positive serialized capacity"
	)


func _check_schema_seven_roundtrip_and_views() -> void:
	var inventory := Inventory.from_dict({
		"capacity": 30,
		"contents": {
			"future.item": 7,
			"crystal": 2,
			"zero.item": 0,
			"negative.item": -1,
		},
	})
	_expect_equal(
		inventory.to_dict(),
		{
			"capacity": 30,
			"contents": {"future.item": 7, "crystal": 2},
		},
		"schema-7 shape and unknown positive keys roundtrip"
	)
	_expect_equal(
		inventory.item_ids(),
		["crystal", "future.item"],
		"item IDs are deterministic"
	)
	var view := inventory.contents_view()
	view["crystal"] = 99
	_expect_equal(inventory.count("crystal"), 2, "contents view cannot mutate inventory")

	var read_model := SliceItemCatalog.read_model(
		inventory.contents_view(), true
	)
	_expect_equal(read_model.size(), 12, "read model keeps eleven known and unknown item")
	_expect_equal(
		String(read_model[0]["item_id"]),
		"crystal",
		"read model starts with catalog order"
	)
	_expect_equal(
		String(read_model[-1]["item_id"]),
		"future.item",
		"unknown item remains visible after known items"
	)

	var explicit_legacy := Inventory.from_dict(
		{
			"capacity": 999,
			"contents": {"future.item": 31, "crystal": 2},
		},
		SliceInventoryProfiles.legacy_pocket()
	)
	_expect_equal(
		explicit_legacy.to_dict(),
		{
			"capacity": 30,
			"contents": {"future.item": 31, "crystal": 2},
		},
		"explicit legacy profile corrects capacity without dropping old property"
	)


func _check_trusted_over_capacity_restore() -> void:
	var inventory := Inventory.new(2)
	inventory.add("crystal", 2)
	inventory.restore_existing("future.item", 3)
	_expect_equal(inventory.total(), 5, "trusted restore keeps all existing property")
	_expect_equal(inventory.free_space(), 0, "over-capacity inventory has no free space")
	_expect_equal(inventory.add("part", 1), 0, "normal add stays blocked over capacity")
	_expect_equal(inventory.remove("future.item", 2), 2, "over-capacity property remains removable")
	_expect_equal(inventory.total(), 3, "removal never discards remaining property")


func _check_atomic_batches_and_exchange() -> void:
	var inventory := Inventory.new(5)
	inventory.add("crystal", 1)
	_expect_equal(
		inventory.can_add_batch({"crystal": 2, "part": 2}),
		true,
		"legacy batch preflight combines all additions"
	)
	_expect_equal(
		inventory.add_batch({"crystal": 2, "part": 2}),
		true,
		"fitting batch commits"
	)
	var full_state := inventory.to_dict()
	_expect_equal(
		inventory.add_batch({"catalyst": 1}),
		false,
		"non-fitting batch rejects"
	)
	_expect_equal(inventory.to_dict(), full_state, "failed add batch makes no mutation")

	_expect_equal(
		inventory.can_exchange(
			{"crystal": 2},
			{"catalyst": 2}
		),
		true,
		"exchange reuses capacity released by removals"
	)
	_expect_equal(
		inventory.exchange({"crystal": 2}, {"catalyst": 2}),
		true,
		"valid exchange commits atomically"
	)
	var exchanged_state := inventory.to_dict()
	_expect_equal(
		inventory.exchange({"crystal": 99}, {"part": 1}),
		false,
		"exchange rejects missing removals"
	)
	_expect_equal(
		inventory.to_dict(),
		exchanged_state,
		"failed exchange makes no mutation"
	)


func _check_atomic_transfer() -> void:
	var source := Inventory.new(10)
	var target := Inventory.new(3)
	source.add_batch({"crystal": 2, "catalyst": 2})
	target.add("part", 1)
	var source_before := source.to_dict()
	var target_before := target.to_dict()
	_expect_equal(
		Inventory.transfer(source, target, {"crystal": 2, "catalyst": 1}),
		false,
		"full atomic transfer rejects when target cannot fit all"
	)
	_expect_equal(source.to_dict(), source_before, "failed transfer keeps source")
	_expect_equal(target.to_dict(), target_before, "failed transfer keeps target")
	_expect_equal(
		source.transfer_to(target, {"crystal": 1, "catalyst": 1}),
		true,
		"fitting transfer commits"
	)
	_expect_equal(source.total(), 2, "successful transfer removes exact source batch")
	_expect_equal(target.total(), 3, "successful transfer adds exact target batch")

	var partial_source := Inventory.new(10)
	var partial_target := Inventory.new(3)
	partial_source.add("crystal", 5)
	partial_target.add("part", 1)
	_expect_equal(
		partial_source.transfer_up_to(partial_target, "crystal", 5),
		2,
		"best-effort single-item transfer uses only target free space"
	)
	_expect_equal(
		partial_source.count("crystal"),
		3,
		"best-effort transfer removes only the moved amount"
	)
	_expect_equal(
		partial_target.count("crystal"),
		2,
		"best-effort transfer adds the same moved amount"
	)
	_expect_equal(
		partial_source.transfer_up_to(partial_target, "crystal", 5),
		0,
		"best-effort transfer applies backpressure when the target is full"
	)


func _check_future_per_item_and_type_limit() -> void:
	var profile := SliceInventoryProfiles.per_item("future.test", 3, 2)
	var inventory := Inventory.new(profile)
	_expect_equal(inventory.capacity, 0, "per-item profile is not serialized as capacity")
	_expect_equal(inventory.add("crystal", 4), 3, "per-item add respects stack limit")
	_expect_equal(inventory.free_space_for("crystal"), 0, "full stack has no space")
	_expect_equal(inventory.add("part", 2), 2, "second item type is accepted")
	_expect_equal(inventory.free_space_for("part"), 1, "partial stack reports named space")
	_expect_equal(inventory.add("catalyst", 1), 0, "type limit blocks a third item")
	var state_before := inventory.contents_view()
	_expect_equal(
		inventory.add_batch({"part": 1, "catalyst": 1}),
		false,
		"batch cannot bypass type limit"
	)
	_expect_equal(inventory.contents_view(), state_before, "type-limit failure is atomic")
	_expect_equal(
		inventory.exchange({"crystal": 3}, {"catalyst": 3}),
		true,
		"exchange may replace a released item type"
	)
	_expect_equal(inventory.count("crystal"), 0, "replaced type is removed")
	_expect_equal(inventory.count("catalyst"), 3, "replacement type is added")
	_expect_equal(
		inventory.to_dict(),
		{
			"contents": {
				"part": 2,
				"catalyst": 3,
			},
		},
		"per-item inventory serializes only authoritative contents"
	)

	var restored_over_limit := Inventory.new(profile)
	restored_over_limit.restore_existing("crystal", 4)
	_expect_equal(
		restored_over_limit.add("crystal", 1),
		0,
		"trusted over-limit category cannot be increased further"
	)
	_expect_equal(
		restored_over_limit.add("part", 1),
		1,
		"unrelated valid category is no longer frozen by trusted excess"
	)

	var overridden := Inventory.new(
		SliceInventoryProfiles.per_item(
			"future.override", 3, 0, {"crystal": 5}
		)
	)
	_expect_equal(
		overridden.add("crystal", 6),
		5,
		"future profile supports explicit item-capacity overrides"
	)
	_expect_equal(
		SliceInventoryProfiles.category_pocket().per_item_capacity,
		200,
		"future pocket profile is staged at 200 per item"
	)
	_expect_equal(
		SliceInventoryProfiles.category_core_storage().per_item_capacity,
		99999,
		"future core profile is staged at 99999 per item"
	)
	_expect_equal(
		SliceInventoryProfiles.category_storage().type_limit,
		4,
		"future storage profile is staged at four item types"
	)
	_expect_equal(
		SliceInventoryProfiles.category_pocket().item_capacity(
			SliceItemCatalog.PULSE_RIFLE_ID
		),
		1,
		"pocket caps the unique rifle at one"
	)
	_expect_equal(
		SliceInventoryProfiles.category_pocket().item_capacity(
			SliceItemCatalog.PULSE_CELL_ID
		),
		200,
		"pocket caps pulse cells at two hundred"
	)
	_expect_equal(
		SliceInventoryProfiles.category_core_storage().item_capacity(
			SliceItemCatalog.PULSE_RIFLE_ID
		),
		1,
		"core caps the unique rifle at one"
	)
	_expect_equal(
		SliceInventoryProfiles.category_core_storage().item_capacity(
			SliceItemCatalog.PULSE_CELL_ID
		),
		200,
		"core caps pulse cells at two hundred"
	)

	var two_new_types := Inventory.new(
		SliceInventoryProfiles.per_item("future.one_type", 3, 1)
	)
	_expect_equal(
		two_new_types.can_add_batch({"crystal": 1, "part": 1}),
		false,
		"combined new types are checked as one batch"
	)
	_expect_equal(two_new_types.is_empty(), true, "failed future batch stays empty")


func _check_category_profiles_and_read_models() -> void:
	var pocket := Inventory.new(SliceInventoryProfiles.category_pocket())
	_expect_equal(pocket.add("crystal", 201), 200, "pocket caps each ordinary item at 200")
	_expect_equal(pocket.add("part", 200), 200, "pocket accepts a second full category")
	_expect_equal(pocket.total(), 400, "pocket has no aggregate total cap")
	_expect_equal(
		pocket.to_dict(),
		{"contents": {"crystal": 200, "part": 200}},
		"category pocket omits legacy capacity"
	)

	var core := Inventory.new(SliceInventoryProfiles.category_core_storage())
	_expect_equal(core.add("crystal", 100000), 99999, "core caps one category at 99999")
	_expect_equal(core.add("part", 99999), 99999, "core has no aggregate total cap")

	var storage := Inventory.new(SliceInventoryProfiles.category_storage())
	for item_id in ["crystal", "catalyst", "part", "building.floor"]:
		_expect_equal(storage.add(item_id, 1), 1, "storage accepts %s as one of four types" % item_id)
	_expect_equal(
		storage.add("building.collector", 1),
		0,
		"storage rejects a fifth new type"
	)
	_expect_equal(
		storage.add("crystal", 199),
		199,
		"full-type storage can still top up an existing type"
	)
	storage.remove("building.floor", 1)
	_expect_equal(storage.add("building.collector", 1), 1, "released type slot accepts replacement")

	var grandfathered := Inventory.new(SliceInventoryProfiles.category_storage())
	for item_id in [
		"crystal", "catalyst", "part", "building.floor", "building.collector"
	]:
		grandfathered.restore_existing(item_id, 1)
	_expect_equal(
		grandfathered.add("crystal", 199),
		199,
		"five-type legacy storage can replenish an existing category"
	)
	_expect_equal(
		grandfathered.add("building.reactor", 1),
		0,
		"five-type legacy storage cannot introduce a new category"
	)
	_expect_equal(
		grandfathered.remove("part", 1),
		1,
		"five-type legacy storage always permits property recovery"
	)

	var craft_fit := Inventory.new(SliceInventoryProfiles.category_pocket())
	craft_fit.restore_existing(SliceBuildingCatalog.FLOOR_ID, 196)
	craft_fit.add("crystal", 1)
	var floor_recipe := SliceRecipes.find("floor")
	_expect_equal(
		SliceRecipes.craft_block_reason(floor_recipe, craft_fit),
		"",
		"four-kit recipe accepts an exact per-item fit"
	)
	_expect_equal(
		craft_fit.exchange(floor_recipe["cost"], {floor_recipe["output"]: 4}),
		true,
		"exact per-item recipe commits as one exchange"
	)
	_expect_equal(craft_fit.count("crystal"), 0, "successful exchange consumes its material")
	_expect_equal(craft_fit.count(SliceBuildingCatalog.FLOOR_ID), 200, "successful exchange reaches the item cap")

	var craft_blocked := Inventory.new(SliceInventoryProfiles.category_pocket())
	craft_blocked.restore_existing(SliceBuildingCatalog.FLOOR_ID, 197)
	craft_blocked.add("crystal", 1)
	var blocked_before := craft_blocked.to_dict()
	_expect_equal(
		SliceRecipes.craft_block_reason(floor_recipe, craft_blocked),
		"工业地板套件还需 1 容量",
		"per-item recipe blocker names the full output category"
	)
	_expect_equal(
		craft_blocked.exchange(floor_recipe["cost"], {floor_recipe["output"]: 4}),
		false,
		"over-cap recipe rejects the whole exchange"
	)
	_expect_equal(craft_blocked.to_dict(), blocked_before, "failed recipe exchange changes nothing")

	var reactor_input := Inventory.new(
		SliceInventoryProfiles.device_reactor_input()
	)
	_expect_equal(reactor_input.add("crystal", 3), 2, "reactor input keeps crystal 2 cap")
	_expect_equal(reactor_input.add("catalyst", 1), 0, "reactor input rejects non-crystal")
	_expect_equal(
		reactor_input.to_dict(),
		{"contents": {"crystal": 2}},
		"schema-8 reactor input is a per-item contents payload"
	)
	var reactor_output := Inventory.new(
		SliceInventoryProfiles.device_reactor_output()
	)
	_expect_equal(reactor_output.add("catalyst", 2), 1, "reactor output keeps catalyst 1 cap")
	_expect_equal(reactor_output.add("crystal", 1), 0, "reactor output rejects non-catalyst")

	var restored := Inventory.from_dict(
		{
			"capacity": 30,
			"contents": {"future.item": 7, "crystal": 2},
		},
		SliceInventoryProfiles.category_pocket()
	)
	_expect_equal(
		restored.to_dict(),
		{"contents": {"future.item": 7, "crystal": 2}},
		"explicit category profile reads a schema-7 inventory shape"
	)
	var groups := SliceInventoryReadModel.inventory_groups(
		restored,
		true,
		true,
		SliceItemCatalog.visible_ids(false)
	)
	_expect_equal(groups.size(), 5, "pocket read model exposes four categories plus compatibility")
	_expect_equal(groups[0]["title"], "原料", "raw material group is first")
	_expect_equal(groups[1]["title"], "加工品", "processed group is second")
	_expect_equal(groups[2]["title"], "建筑套件", "building kit group is third")
	_expect_equal(groups[3]["title"], "关键物品", "key-item view is separate from inventory")
	_expect_equal(groups[4]["title"], "兼容物品", "unknown old IDs remain visible")
	_expect_equal(
		_find_group_item(groups, SliceItemCatalog.CRITICAL_SAMPLE_PRESENTATION_ID)["count"],
		1,
		"carried critical sample is presented once"
	)
	_expect_equal(
		restored.count(SliceItemCatalog.CRITICAL_SAMPLE_PRESENTATION_ID),
		0,
		"critical sample presentation never mutates inventory"
	)
	var unknown := _find_group_item(groups, "future.item")
	_expect_equal(unknown["count"], 7, "unknown old ID keeps its count")
	_expect_equal(unknown["capacity"], 200, "unknown old ID follows pocket stack cap")

	var charged_groups := SliceInventoryReadModel.inventory_groups(
		restored,
		true,
		false,
		SliceItemCatalog.visible_ids(true)
	)
	_expect_equal(charged_groups.size(), 6, "charged inventory exposes six ordinary categories")
	_expect_equal(charged_groups[2]["title"], "装备", "equipment follows processed items")
	_expect_equal(charged_groups[3]["title"], "外勤补给", "field supply follows equipment")
	_expect_equal(
		_find_group_item(charged_groups, SliceItemCatalog.PULSE_RIFLE_ID)["capacity"],
		1,
		"charged rifle slot presents its unique pocket cap"
	)
	_expect_equal(
		_find_group_item(charged_groups, SliceItemCatalog.PULSE_CELL_ID)["capacity"],
		200,
		"charged pulse-cell slot presents its pocket cap"
	)


func _find_group_item(groups: Array[Dictionary], item_id: String) -> Dictionary:
	for group in groups:
		for item in group["items"]:
			if String(item["item_id"]) == item_id:
				return item
	return {}


func _expect_equal(actual, expected, context: String) -> void:
	_assertion_count += 1
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [context, expected, actual])
