extends RefCounted


## The view supplies the center-ray hit; authority supplies proximity and obstruction.
## A visible nearby device wins over a nearby sample, so F matches its highlight.
static func resolve(model: RefCounted, center_id: int) -> Dictionary:
	var e: Dictionary = model.by_id(center_id)
	if not e.is_empty() and model.near_entity(e):
		return {"kind": "device", "id": e.id, "ready": true}
	if not model.discovery.sample_taken and model.near_sample():
		return {"kind": "sample", "id": -1, "ready": true}
	if not e.is_empty():
		return {"kind": "device", "id": e.id, "ready": false}
	return {}
