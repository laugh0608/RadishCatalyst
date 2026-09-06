extends RefCounted

## Authored mesh parts for this specimen, in meters. All surfaces receive real light.

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


static func cylinder(parent: Node3D, at: Vector3, radius: float, height: float, mat: Material) -> MeshInstance3D:
	var shape := CylinderMesh.new()
	shape.top_radius = radius
	shape.bottom_radius = radius
	shape.height = height
	shape.radial_segments = 48
	return mesh(parent, shape, at, mat)


static func sphere(parent: Node3D, at: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var shape := SphereMesh.new()
	shape.radius = 0.5
	shape.height = 1.0
	var part := mesh(parent, shape, at, mat)
	part.scale = size
	return part


static func ring(parent: Node3D, at: Vector3, inner: float, outer: float, mat: Material) -> MeshInstance3D:
	var shape := TorusMesh.new()
	shape.inner_radius = inner
	shape.outer_radius = outer
	shape.rings = 40
	shape.ring_segments = 12
	return mesh(parent, shape, at, mat)


static func collider(parent: Node3D, at: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	parent.add_child(body)
	body.position = at
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	return body


## Extrude a closed YZ profile along X. Flat top of liquid is actual geometry.
static func profile_mesh(points: PackedVector2Array, length: float) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var center := Vector2.ZERO
	for point in points:
		center += point
	center /= float(points.size())
	for index in points.size():
		var a := points[index]
		var b := points[(index + 1) % points.size()]
		var start_a := Vector3(-length / 2.0, a.x, a.y)
		var start_b := Vector3(-length / 2.0, b.x, b.y)
		var end_a := Vector3(length / 2.0, a.x, a.y)
		var end_b := Vector3(length / 2.0, b.x, b.y)
		for vertex in [start_a, end_a, end_b, start_a, end_b, start_b,
			Vector3(-length / 2.0, center.x, center.y), start_a, start_b,
			Vector3(length / 2.0, center.x, center.y), end_b, end_a]:
			surface.add_vertex(vertex)
	surface.generate_normals()
	return surface.commit()


static func liquid(parent: Node3D, length: float, mat: Material) -> MeshInstance3D:
	var profile := PackedVector2Array()
	var start_angle := acos(0.035 / 0.285)
	for index in 41:
		var angle := lerpf(start_angle, TAU - start_angle, float(index) / 40.0)
		profile.append(Vector2(cos(angle), sin(angle)) * 0.285)
	return mesh(parent, profile_mesh(profile, length), Vector3.ZERO, mat)


## Open tube with inward-facing inner walls; separate flanges provide end rims.
static func tube(parent: Node3D, length: float, mat: Material) -> MeshInstance3D:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	for inside in [false, true]:
		var radius := 0.30 if inside else 0.33
		var base := vertices.size()
		for side in 2:
			for i in 49:
				var angle := TAU * float(i) / 48.0
				var normal := Vector3(0, cos(angle), sin(angle))
				vertices.append(Vector3((float(side) - 0.5) * length, normal.y * radius, normal.z * radius))
				normals.append(-normal if inside else normal)
		for i in 48:
			var a := base + i
			var b := a + 49
			var face := [a, b, b + 1, a, b + 1, a + 1]
			if inside:
				face.reverse()
			indices.append_array(PackedInt32Array(face))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	var shape := ArrayMesh.new()
	shape.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var result := mesh(parent, shape, Vector3.ZERO, mat)
	result.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return result
