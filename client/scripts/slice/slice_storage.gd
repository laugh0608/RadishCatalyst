class_name SliceStorage
extends SliceBuildingInstance

## Powered field storage with one authoritative inventory. Supply mode exposes
## only the fixed right OUT endpoint; transfer mode exposes only the fixed left
## IN endpoint and periodically moves transportable contents to the repaired
## core warehouse. Manual access never depends on power.

const CAPACITY := 200
const TYPE_LIMIT := 4
const MODE_SUPPLY := "supply"
const MODE_TRANSFER := "transfer"
const TRANSFER_INTERVAL := 5.0
const TRANSFER_BATCH_SIZE := 50

var inventory := Inventory.new(SliceInventoryProfiles.category_storage())
var mode := MODE_SUPPLY
var output_item_id := ""
var transfer_cursor := 0
var transfer_progress := 0.0


func logistics_endpoints() -> Array[SliceLogisticsEndpoint]:
	var result: Array[SliceLogisticsEndpoint] = []
	if definition == null:
		return result
	var active_port_id := "output" if mode == MODE_SUPPLY else "input"
	var port := definition.logistics_port_definition(active_port_id)
	if port == null:
		return result
	result.append(SliceLogisticsEndpoint.new(
		self,
		port,
		Callable(self, "_accept_transfer_item"),
		Callable(self, "_peek_supply_output"),
		Callable(self, "_take_supply_output")
	))
	return result


func content_block_reason() -> String:
	return "" if inventory.is_empty() else "先清空储物箱"


func state_dict(allowed_keys: Array[String]) -> Dictionary:
	var result := {}
	if allowed_keys.has("inventory"):
		result["inventory"] = inventory.to_dict()
	if allowed_keys.has("mode"):
		result["mode"] = mode
	if allowed_keys.has("output_item_id"):
		result["output_item_id"] = output_item_id
	if allowed_keys.has("transfer_cursor"):
		result["transfer_cursor"] = transfer_cursor
	if allowed_keys.has("transfer_progress"):
		result["transfer_progress"] = transfer_progress
	return result


func restore_state(state: Dictionary) -> void:
	inventory = Inventory.from_dict(
		state.get("inventory", {}),
		SliceInventoryProfiles.category_storage()
	)
	mode = String(state.get("mode", MODE_SUPPLY))
	if mode != MODE_SUPPLY and mode != MODE_TRANSFER:
		mode = MODE_SUPPLY
	output_item_id = String(state.get("output_item_id", ""))
	if (
		not output_item_id.is_empty()
		and not SliceItemCatalog.is_transportable(output_item_id)
	):
		output_item_id = ""
	var transportable_count := SliceItemCatalog.transportable_ids().size()
	transfer_cursor = (
		posmod(int(state.get("transfer_cursor", 0)), transportable_count)
		if transportable_count > 0
		else 0
	)
	transfer_progress = clampf(
		float(state.get("transfer_progress", 0.0)),
		0.0,
		TRANSFER_INTERVAL - 0.000001
	)
	if mode != MODE_TRANSFER:
		transfer_progress = 0.0


func set_mode(next_mode: String) -> bool:
	if (
		(next_mode != MODE_SUPPLY and next_mode != MODE_TRANSFER)
		or next_mode == mode
	):
		return false
	if mode == MODE_TRANSFER:
		transfer_progress = 0.0
	mode = next_mode
	if mode == MODE_SUPPLY and output_item_id.is_empty():
		output_item_id = _first_present_transportable()
	return true


func toggle_mode() -> bool:
	return set_mode(
		MODE_TRANSFER if mode == MODE_SUPPLY else MODE_SUPPLY
	)


func set_output_item(next_item_id: String) -> bool:
	if (
		next_item_id == output_item_id
		or (
			not next_item_id.is_empty()
			and not SliceItemCatalog.is_transportable(next_item_id)
		)
	):
		return false
	output_item_id = next_item_id
	return true


func select_next_present_output() -> bool:
	var candidates := present_transportable_ids()
	if candidates.is_empty():
		return set_output_item("")
	var current_index := candidates.find(output_item_id)
	return set_output_item(
		candidates[(current_index + 1) % candidates.size()]
	)


func present_transportable_ids() -> Array[String]:
	var result: Array[String] = []
	for item_id in SliceItemCatalog.transportable_ids():
		if inventory.count(item_id) > 0:
			result.append(item_id)
	return result


func manual_deposit(source: Inventory, item_id: String) -> int:
	if (
		source == null
		or item_id.is_empty()
		or SliceItemCatalog.find(item_id) == null
	):
		return 0
	var was_empty := inventory.is_empty()
	var moved := source.transfer_up_to(
		inventory, item_id, source.count(item_id)
	)
	if (
		moved > 0
		and was_empty
		and output_item_id.is_empty()
		and SliceItemCatalog.is_transportable(item_id)
	):
		output_item_id = item_id
	return moved


func manual_withdraw(target: Inventory, item_id: String) -> int:
	if target == null or item_id.is_empty():
		return 0
	return inventory.transfer_up_to(
		target, item_id, inventory.count(item_id)
	)


## Advances transfer time only while at least one transportable item can move.
## A large delta is processed as discrete five-second pulses; time after a
## pulse pauses immediately if the source empties or every core item is full.
func tick_wireless_transfer(
	delta: float,
	core_repaired: bool,
	core_inventory: Inventory
) -> Dictionary:
	if (
		delta <= 0.0
		or mode != MODE_TRANSFER
		or not powered
		or not core_repaired
		or core_inventory == null
	):
		return _wireless_result(false, 0)

	var remaining_delta := delta
	var changed := false
	var moved_total := 0
	while remaining_delta > 0.0000001:
		if not _has_wireless_candidate(core_inventory):
			break
		var until_pulse := TRANSFER_INTERVAL - transfer_progress
		var advanced := minf(remaining_delta, until_pulse)
		transfer_progress += advanced
		remaining_delta -= advanced
		changed = changed or advanced > 0.0
		if transfer_progress + 0.0000001 < TRANSFER_INTERVAL:
			break
		transfer_progress = 0.0
		var moved := _transfer_wireless_pulse(core_inventory)
		moved_total += moved
		changed = changed or moved > 0
		if moved <= 0:
			break
	return _wireless_result(changed, moved_total)


func mode_display_name() -> String:
	return "存储模式" if mode == MODE_SUPPLY else "传输模式"


func type_count() -> int:
	return inventory.item_ids().size()


func _accept_transfer_item(item_id: String) -> int:
	if mode != MODE_TRANSFER or not SliceItemCatalog.is_transportable(item_id):
		return 0
	return inventory.add(item_id, 1)


func _peek_supply_output() -> String:
	if (
		mode != MODE_SUPPLY
		or not powered
		or output_item_id.is_empty()
		or inventory.count(output_item_id) <= 0
	):
		return ""
	return output_item_id


func _take_supply_output(item_id: String) -> int:
	if (
		mode != MODE_SUPPLY
		or not powered
		or item_id != output_item_id
	):
		return 0
	return inventory.remove(item_id, 1)


func _has_wireless_candidate(core_inventory: Inventory) -> bool:
	for item_id in SliceItemCatalog.transportable_ids():
		if (
			inventory.count(item_id) > 0
			and core_inventory.free_space_for(item_id) > 0
		):
			return true
	return false


func _transfer_wireless_pulse(core_inventory: Inventory) -> int:
	var ordered_ids := SliceItemCatalog.transportable_ids()
	if ordered_ids.is_empty():
		transfer_cursor = 0
		return 0
	var remaining := TRANSFER_BATCH_SIZE
	var moved_total := 0
	var start := posmod(transfer_cursor, ordered_ids.size())
	for offset in range(ordered_ids.size()):
		var index := (start + offset) % ordered_ids.size()
		var item_id := ordered_ids[index]
		var moved := inventory.transfer_up_to(
			core_inventory,
			item_id,
			mini(remaining, inventory.count(item_id))
		)
		moved_total += moved
		remaining -= moved
		transfer_cursor = (index + 1) % ordered_ids.size()
		if remaining <= 0:
			break
	return moved_total


func _first_present_transportable() -> String:
	var present := present_transportable_ids()
	return "" if present.is_empty() else present[0]


func _wireless_result(changed: bool, moved: int) -> Dictionary:
	return {
		"changed": changed,
		"moved": moved,
	}
