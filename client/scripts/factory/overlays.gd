extends RefCounted

## Dynamic selection, progress and status overlays; world geometry comes from imported assets.

static func material(color: String, metallic := 0.0, roughness := 0.6) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = Color(color)
	result.metallic = metallic
	result.roughness = roughness
	return result


static func mesh(parent: Node3D, shape: Mesh, at: Vector3, mat: Material) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.mesh = shape
	part.material_override = mat
	parent.add_child(part)
	part.position = at
	return part


static func box(parent: Node3D, at: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var shape := BoxMesh.new()
	shape.size = size
	return mesh(parent, shape, at, mat)


static func sphere(parent: Node3D, at: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var shape := SphereMesh.new()
	shape.radius = 0.5
	shape.height = 1.0
	var part := mesh(parent, shape, at, mat)
	part.scale = size
	return part
