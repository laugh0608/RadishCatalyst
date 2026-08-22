class_name SliceInventoryProfiles
extends RefCounted

## Named constructors keep container rules out of Inventory and out of saves.


static func legacy_total(
	capacity: int,
	profile_id: String = ""
) -> SliceInventoryProfile:
	var resolved_id := profile_id
	if resolved_id.is_empty():
		resolved_id = "legacy.total.%d" % capacity
	return SliceInventoryProfile.new(
		resolved_id,
		SliceInventoryProfile.MODE_LEGACY_TOTAL,
		capacity
	)


static func legacy_pocket() -> SliceInventoryProfile:
	return legacy_total(30, "legacy.pocket")


static func legacy_core_storage() -> SliceInventoryProfile:
	return legacy_total(120, "legacy.core_storage")


static func legacy_storage() -> SliceInventoryProfile:
	return legacy_total(20, "legacy.storage")


static func legacy_reactor_input() -> SliceInventoryProfile:
	return legacy_total(2, "legacy.reactor_input")


static func legacy_reactor_output() -> SliceInventoryProfile:
	return legacy_total(1, "legacy.reactor_output")


static func per_item(
	profile_id: String,
	item_capacity: int,
	type_limit: int = 0,
	item_capacity_overrides: Dictionary = {},
	allowed_item_ids: Array[String] = []
) -> SliceInventoryProfile:
	return SliceInventoryProfile.new(
		profile_id,
		SliceInventoryProfile.MODE_PER_ITEM,
		0,
		item_capacity,
		type_limit,
		item_capacity_overrides,
		allowed_item_ids
	)


static func category_pocket() -> SliceInventoryProfile:
	return per_item(
		"category.pocket",
		200,
		0,
		{SliceItemCatalog.PULSE_RIFLE_ID: 1}
	)


static func category_core_storage() -> SliceInventoryProfile:
	return per_item(
		"category.core_storage",
		99999,
		0,
		{
			SliceItemCatalog.PULSE_RIFLE_ID: 1,
			SliceItemCatalog.PULSE_CELL_ID: 200,
		}
	)


static func category_storage() -> SliceInventoryProfile:
	return per_item("category.storage", 200, 4)


static func device_reactor_input() -> SliceInventoryProfile:
	return per_item(
		"device.reactor_input",
		0,
		1,
		{SliceItemCatalog.CRYSTAL_ID: 2},
		[SliceItemCatalog.CRYSTAL_ID]
	)


static func device_reactor_output() -> SliceInventoryProfile:
	return per_item(
		"device.reactor_output",
		0,
		1,
		{SliceItemCatalog.CATALYST_ID: 1},
		[SliceItemCatalog.CATALYST_ID]
	)
