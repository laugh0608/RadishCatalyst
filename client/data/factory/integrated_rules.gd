extends RefCounted

const MAP_ID := "factory_integrated_yard_64_v1"
const SUPPLY_ID := "factory_integrated_starter_v1"
const CORE := "base_core"
const CORE_SHAPE := {"name": "基地核心", "w": 6, "d": 6}
const CORE_CELL := Vector2i(-11, 22)
const SPAWN := Vector2(-8, 20)
const ITEM_LIMIT := 99999
const BASE_KW := 360.0
const COOLDOWN_TICKS := 20
const MODEL_PATH := "res://assets/prototypes/base_core_outline/core-outline.glb"
const SUPPLY := {"collector": 3, "reactor": 1, "crusher": 1, "refinery": 1, "assembler": 1,
	"storage": 2, "power_junction": 12, "belt": 256, "splitter": 4, "merger": 4, "admission_gate": 4}

# Clockwise, listing the three inputs and then the output on each face.
const FACES := ["N", "E", "S", "W"]
const FACE_NAMES := ["北", "东", "南", "西"]
const NORMALS := [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
const CELLS := [
	[Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0)],
	[Vector2i(5, 1), Vector2i(5, 2), Vector2i(5, 3), Vector2i(5, 4)],
	[Vector2i(4, 5), Vector2i(3, 5), Vector2i(2, 5), Vector2i(1, 5)],
	[Vector2i(0, 4), Vector2i(0, 3), Vector2i(0, 2), Vector2i(0, 1)],
]


static func ports(origin: Vector2i, role: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for face in FACES.size():
		var normal: Vector2i = NORMALS[face]
		for index in ([3] if role == "output" else [0, 1, 2]):
			var cell: Vector2i = origin + CELLS[face][index]
			var id := "OUT_%s0" % FACES[face] if role == "output" else "IN_%s%d" % [FACES[face], index]
			var name := "%s侧出料" % FACE_NAMES[face] if role == "output" else "%s侧进料 %d" % [FACE_NAMES[face], index + 1]
			result.append({"id": id, "name": name, "index": result.size(), "x": cell.x, "z": cell.y,
				"dx": normal.x, "dz": normal.y})
	return result


static func anchor(port: Dictionary) -> Vector3:
	return Vector3(port.x - 2.5 + port.dx * 0.5, 0.31, port.z - 2.5 + port.dz * 0.5)
