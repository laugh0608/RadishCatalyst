extends RefCounted

# 会话单调时钟；只把活动区间交给模型，不持久化系统时间戳。
var last_usec := 0
var running := false
var active_usec := 0
var pending_usec := 0


func start(now_usec: int, active: bool) -> void:
	last_usec = now_usec
	running = active
	active_usec = 0
	pending_usec = 0


func sample(now_usec: int, active: bool) -> void:
	assert(now_usec >= last_usec, "Monotonic clock moved backwards")
	if running:
		var elapsed := now_usec - last_usec
		active_usec += elapsed
		pending_usec += elapsed
	last_usec = now_usec
	running = active


func consume() -> float:
	var seconds := pending_usec / 1000000.0
	pending_usec = 0
	return seconds
