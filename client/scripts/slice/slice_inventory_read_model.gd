class_name SliceInventoryReadModel
extends RefCounted

## Shared categorized presentation over authoritative Inventory contents.
## Slot/category layout is runtime-only. Critical sample state is accepted as an
## explicit boolean and appended as a presentation row without entering either
## Inventory or the ordinary item catalog.


static func inventory_groups(
	inventory: Inventory,
	include_empty_known: bool = false,
	include_critical_sample: bool = false,
	visible_known_ids: Array[String] = []
) -> Array[Dictionary]:
	if inventory == null:
		return []
	var items := SliceItemCatalog.read_model(
		inventory.contents_view(), include_empty_known, visible_known_ids
	)
	var critical_sample := SliceItemCatalog.critical_sample_read_model(
		include_critical_sample
	)
	if not critical_sample.is_empty():
		items.append(critical_sample)

	var grouped := {}
	for raw_item in items:
		var item: Dictionary = raw_item.duplicate(true)
		var category := String(item["category"])
		if category != SliceItemDefinition.CATEGORY_KEY_ITEM:
			item["capacity"] = inventory.profile().item_capacity(
				String(item["item_id"])
			)
		else:
			item["capacity"] = 1
		if not grouped.has(category):
			grouped[category] = []
		(grouped[category] as Array).append(item)
	return _ordered_groups(grouped)


static func paired_inventory_groups(
	left: Inventory,
	right: Inventory,
	include_empty_known: bool = false,
	visible_known_ids: Array[String] = []
) -> Array[Dictionary]:
	if left == null or right == null:
		return []
	var grouped := {}
	for item in paired_inventory_items(
		left, right, include_empty_known, visible_known_ids
	):
		var category := String(item["category"])
		if not grouped.has(category):
			grouped[category] = []
		(grouped[category] as Array).append(item)
	return _ordered_groups(grouped)


static func paired_inventory_items(
	left: Inventory,
	right: Inventory,
	include_empty_known: bool = false,
	visible_known_ids: Array[String] = []
) -> Array[Dictionary]:
	if left == null or right == null:
		return []
	var merged_contents := left.contents_view()
	for item_id in right.item_ids():
		merged_contents[item_id] = maxi(
			int(merged_contents.get(item_id, 0)), right.count(item_id)
		)
	var left_capacities := {}
	var right_capacities := {}
	for item_id in merged_contents:
		left_capacities[item_id] = left.profile().item_capacity(item_id)
		right_capacities[item_id] = right.profile().item_capacity(item_id)
	return paired_content_items(
		left.contents_view(),
		right.contents_view(),
		left_capacities,
		right_capacities,
		include_empty_known,
		visible_known_ids
	)


## Presentation adapter for non-Inventory device buffers. Counts and capacities
## remain copies; the returned rows cannot mutate the authoritative runtime.
static func paired_content_items(
	left_contents: Dictionary,
	right_contents: Dictionary,
	left_capacities: Dictionary,
	right_capacities: Dictionary,
	include_empty_known: bool = false,
	visible_known_ids: Array[String] = []
) -> Array[Dictionary]:
	var merged_contents := left_contents.duplicate()
	for item_id in right_contents:
		merged_contents[item_id] = maxi(
			int(merged_contents.get(item_id, 0)),
			int(right_contents[item_id])
		)
	var result: Array[Dictionary] = []
	for raw_item in SliceItemCatalog.read_model(
		merged_contents, include_empty_known, visible_known_ids
	):
		var item: Dictionary = raw_item.duplicate(true)
		var item_id := String(item["item_id"])
		item["left_count"] = maxi(0, int(left_contents.get(item_id, 0)))
		item["left_capacity"] = maxi(
			0, int(left_capacities.get(item_id, item["left_count"]))
		)
		item["right_count"] = maxi(0, int(right_contents.get(item_id, 0)))
		item["right_capacity"] = maxi(
			0, int(right_capacities.get(item_id, item["right_count"]))
		)
		if item["left_count"] > 0 or item["right_count"] > 0 or include_empty_known:
			result.append(item)
	return result


static func _ordered_groups(grouped: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for category in SliceItemCatalog.CATEGORY_ORDER:
		if not grouped.has(category):
			continue
		var items: Array = grouped[category]
		if items.is_empty():
			continue
		result.append({
			"category": category,
			"title": SliceItemCatalog.category_title(category),
			"items": items,
		})
	return result
