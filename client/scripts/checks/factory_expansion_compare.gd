extends RefCounted

## JSON parsing can round accumulated floating energy by a few ulps. Integer
## counters and field membership remain exact; floating state tolerance is 1e-9.
static func equivalent(a: Variant, b: Variant, path := "state") -> bool:
	if a is Dictionary and b is Dictionary:
		if a.size() != b.size(): return false
		for key in a:
			if not b.has(key) or not equivalent(a[key], b[key], path + "." + str(key)): return false
		return true
	if a is Array and b is Array:
		if a.size() != b.size(): return false
		for i in a.size():
			if not equivalent(a[i], b[i], path + "[%d]" % i): return false
		return true
	if (a is int or a is float) and (b is int or b is float):
		if a == floor(a) and b == floor(b): return a == b
		if absf(a - b) <= 1e-9: return true
	if a != b: print("E1 snapshot mismatch ", path, ": ", a, " / ", b)
	return a == b
