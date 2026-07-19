class_name SliceCollector
extends Node2D

## Placed crystal collector: produces crystals into its own output buffer on a
## timed tick driven by SliceWorld. The buffer pauses at BUFFER_CAP until the
## player walks over and withdraws it — spatial output that belts will automate
## at arc layer L4 (docs/features/slice-item-inventory-model-v1.md).

const BUFFER_CAP := 10

## Top-left tile of the collector's 2x2 block; the stable id used for saving.
var cell: Vector2i
var buffer := 0


func has_space() -> bool:
	return buffer < BUFFER_CAP


func produce(n: int) -> void:
	buffer = mini(buffer + n, BUFFER_CAP)
