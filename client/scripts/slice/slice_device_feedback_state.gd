class_name SliceDeviceFeedbackState
extends RefCounted

## Pure presentation vocabulary for packages 4B-4C. Gameplay and persistence keep
## owning every source fact; these predicates only choose a readable state and
## the one-shot cue caused by a real state edge.

const CORE_DAMAGED := &"core_damaged"
const CORE_REPAIRED := &"core_repaired"
const CORE_CHARGED := &"core_charged"
const CORE_SAMPLE_INSTALLED := &"core_sample_installed"

const REACTOR_UNPOWERED := &"reactor_unpowered"
const REACTOR_IDLE := &"reactor_idle"
const REACTOR_PROCESSING := &"reactor_processing"
const REACTOR_BLOCKED := &"reactor_blocked"

const COLLECTOR_UNPOWERED := &"collector_unpowered"
const COLLECTOR_COLLECTING := &"collector_collecting"
const COLLECTOR_FULL := &"collector_full"

const STORAGE_UNPOWERED := &"storage_unpowered"
const STORAGE_SUPPLY := &"storage_supply"
const STORAGE_TRANSFER_IDLE := &"storage_transfer_idle"
const STORAGE_TRANSFER_RUNNING := &"storage_transfer_running"
const STORAGE_BLOCKED := &"storage_blocked"

const RELAY_UNPOWERED := &"relay_unpowered"
const RELAY_ONLINE := &"relay_online"

const EVENT_CORE_REPAIRED := &"core_repaired"
const EVENT_CORE_CHARGED := &"core_charged"
const EVENT_CORE_SAMPLE_INSTALLED := &"core_sample_installed"
const EVENT_REACTOR_POWER_LOST := &"reactor_power_lost"
const EVENT_REACTOR_STARTED := &"reactor_started"
const EVENT_REACTOR_BLOCKED := &"reactor_blocked"
const EVENT_DEVICE_POWER_LOST := &"device_power_lost"
const EVENT_DEVICE_RUNNING := &"device_running"
const EVENT_DEVICE_BLOCKED := &"device_blocked"


static func core_state(
	repaired: bool,
	charged: bool,
	sample_installed: bool
) -> StringName:
	if sample_installed:
		return CORE_SAMPLE_INSTALLED
	if charged:
		return CORE_CHARGED
	if repaired:
		return CORE_REPAIRED
	return CORE_DAMAGED


static func reactor_state(
	powered: bool,
	processing: bool,
	output_blocked: bool
) -> StringName:
	if not powered:
		return REACTOR_UNPOWERED
	if processing:
		return REACTOR_PROCESSING
	if output_blocked:
		return REACTOR_BLOCKED
	return REACTOR_IDLE


static func collector_state(powered: bool, buffer: int, capacity: int) -> StringName:
	if not powered:
		return COLLECTOR_UNPOWERED
	if capacity > 0 and buffer >= capacity:
		return COLLECTOR_FULL
	return COLLECTOR_COLLECTING


static func storage_state(
	powered: bool,
	transfer_mode: bool,
	has_contents: bool,
	can_transfer: bool
) -> StringName:
	if not powered:
		return STORAGE_UNPOWERED
	if not transfer_mode:
		return STORAGE_SUPPLY
	if not has_contents:
		return STORAGE_TRANSFER_IDLE
	if can_transfer:
		return STORAGE_TRANSFER_RUNNING
	return STORAGE_BLOCKED


static func relay_state(powered: bool) -> StringName:
	return RELAY_ONLINE if powered else RELAY_UNPOWERED


static func core_edge_event(
	previous: StringName,
	next: StringName
) -> StringName:
	if previous.is_empty() or previous == next:
		return &""
	match next:
		CORE_REPAIRED:
			return EVENT_CORE_REPAIRED
		CORE_CHARGED:
			return EVENT_CORE_CHARGED
		CORE_SAMPLE_INSTALLED:
			return EVENT_CORE_SAMPLE_INSTALLED
	return &""


static func reactor_edge_event(
	previous: StringName,
	next: StringName
) -> StringName:
	if previous.is_empty() or previous == next:
		return &""
	match next:
		REACTOR_UNPOWERED:
			return EVENT_REACTOR_POWER_LOST
		REACTOR_PROCESSING:
			return EVENT_REACTOR_STARTED
		REACTOR_BLOCKED:
			return EVENT_REACTOR_BLOCKED
	return &""


static func common_device_edge_event(
	previous: StringName,
	next: StringName
) -> StringName:
	if previous.is_empty() or previous == next:
		return &""
	if next in [
		COLLECTOR_UNPOWERED,
		STORAGE_UNPOWERED,
		RELAY_UNPOWERED,
	]:
		return EVENT_DEVICE_POWER_LOST
	if next in [
		COLLECTOR_COLLECTING,
		STORAGE_TRANSFER_RUNNING,
		RELAY_ONLINE,
	]:
		return EVENT_DEVICE_RUNNING
	if next in [COLLECTOR_FULL, STORAGE_BLOCKED]:
		return EVENT_DEVICE_BLOCKED
	return &""
