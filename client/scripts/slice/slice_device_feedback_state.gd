class_name SliceDeviceFeedbackState
extends RefCounted

## Pure presentation vocabulary for package 4B. Gameplay and persistence keep
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

const EVENT_CORE_REPAIRED := &"core_repaired"
const EVENT_CORE_CHARGED := &"core_charged"
const EVENT_CORE_SAMPLE_INSTALLED := &"core_sample_installed"
const EVENT_REACTOR_POWER_LOST := &"reactor_power_lost"
const EVENT_REACTOR_STARTED := &"reactor_started"
const EVENT_REACTOR_BLOCKED := &"reactor_blocked"


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
