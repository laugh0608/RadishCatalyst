extends SceneTree

const COLUMNS := 2
const CELL_SIZE := Vector2i(640, 392)
const PADDING := 16
const LABEL_HEIGHT := 40
const DIGIT_SCALE := 5
const DIGITS := {
	"0": ["111", "101", "101", "101", "111"],
	"1": ["010", "110", "010", "010", "111"],
	"2": ["111", "001", "111", "100", "111"],
	"3": ["111", "001", "111", "001", "111"],
	"4": ["101", "101", "111", "001", "001"],
	"5": ["111", "100", "111", "001", "111"],
	"6": ["111", "100", "111", "101", "111"],
	"7": ["111", "001", "010", "010", "010"],
	"8": ["111", "101", "111", "101", "111"],
	"9": ["111", "101", "111", "001", "111"],
}


func _init() -> void:
	var arguments := OS.get_cmdline_user_args()
	if arguments.size() < 3:
		push_error("用法：<output.png> <input-1.png> <input-2.png> [更多图片...]")
		quit(2)
		return

	var output_path := ProjectSettings.globalize_path(arguments[0])
	var input_paths := arguments.slice(1)
	var images: Array[Image] = []
	for input_path in input_paths:
		var image := Image.new()
		var error := image.load(ProjectSettings.globalize_path(input_path))
		if error != OK:
			push_error("无法读取截图：%s（error %s）" % [input_path, error])
			quit(1)
			return
		image.convert(Image.FORMAT_RGBA8)
		images.append(image)

	var rows := int(ceil(float(images.size()) / float(COLUMNS)))
	var canvas := Image.create_empty(CELL_SIZE.x * COLUMNS, CELL_SIZE.y * rows, false, Image.FORMAT_RGBA8)
	canvas.fill(Color("171b22"))

	for index in images.size():
		_draw_cell(canvas, images[index], index)
		print("%02d -> %s" % [index + 1, input_paths[index]])

	var output_dir := output_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(output_dir):
		var mkdir_error := DirAccess.make_dir_recursive_absolute(output_dir)
		if mkdir_error != OK:
			push_error("无法创建输出目录：%s（error %s）" % [output_dir, mkdir_error])
			quit(1)
			return

	var save_error := canvas.save_png(output_path)
	if save_error != OK:
		push_error("无法保存联系表：%s（error %s）" % [output_path, save_error])
		quit(1)
		return

	print("Contact sheet saved: %s" % output_path)
	quit(0)


func _draw_cell(canvas: Image, source: Image, index: int) -> void:
	var column: int = index % COLUMNS
	var row: int = index / COLUMNS
	var cell_origin := Vector2i(column * CELL_SIZE.x, row * CELL_SIZE.y)
	var label_rect := Rect2i(cell_origin, Vector2i(CELL_SIZE.x, LABEL_HEIGHT))
	canvas.fill_rect(label_rect, Color("242b35"))
	_draw_number(canvas, index + 1, cell_origin + Vector2i(PADDING, 7))

	var available_size := Vector2i(
		CELL_SIZE.x - PADDING * 2,
		CELL_SIZE.y - LABEL_HEIGHT - PADDING * 2
	)
	var scale_factor: float = minf(
		float(available_size.x) / float(source.get_width()),
		float(available_size.y) / float(source.get_height())
	)
	var target_size := Vector2i(
		maxi(1, int(round(source.get_width() * scale_factor))),
		maxi(1, int(round(source.get_height() * scale_factor)))
	)
	var resized: Image = source.duplicate()
	resized.resize(target_size.x, target_size.y, Image.INTERPOLATE_LANCZOS)
	var image_origin := cell_origin + Vector2i(
		(CELL_SIZE.x - target_size.x) / 2,
		LABEL_HEIGHT + PADDING + (available_size.y - target_size.y) / 2
	)
	canvas.blit_rect(resized, Rect2i(Vector2i.ZERO, target_size), image_origin)


func _draw_number(canvas: Image, number: int, origin: Vector2i) -> void:
	var cursor_x := origin.x
	for character_index in str(number).length():
		var character := str(number).substr(character_index, 1)
		var pattern: Array = DIGITS[character]
		for pattern_row in pattern.size():
			for pattern_column in pattern[pattern_row].length():
				if pattern[pattern_row].substr(pattern_column, 1) != "1":
					continue
				canvas.fill_rect(
					Rect2i(
						Vector2i(cursor_x + pattern_column * DIGIT_SCALE, origin.y + pattern_row * DIGIT_SCALE),
						Vector2i(DIGIT_SCALE, DIGIT_SCALE)
					),
					Color.WHITE
				)
		cursor_x += 4 * DIGIT_SCALE
