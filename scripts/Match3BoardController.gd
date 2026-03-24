extends Control
class_name Match3BoardController

signal header_changed(title: String, goal_text: String, hint_text: String, stats_text: String)
signal message_changed(text: String)
signal level_completed(stars: int)
signal out_of_moves

const TILE_SIZE := Vector2(110, 92)
const TILE_GAP := Vector2(12, 12)
const BOARD_PADDING := Vector2(8, 8)
const ANIM_SPEED_SCALE := 0.75

const TILE_BASE := Color("f3ead8")
const TILE_SELECTED := Color("ffe08a")
const TILE_MATCHED := Color("b7e4c7")
const TILE_INVALID := Color("f6c1c1")

const VALUE_COLORS := {
	1: Color("ffd6a5"),
	2: Color("fdffb6"),
	3: Color("caffbf"),
	4: Color("9bf6ff"),
	5: Color("a0c4ff"),
	6: Color("ffc6ff"),
	7: Color("ffdab9"),
	8: Color("d0f4de"),
	9: Color("e4c1f9"),
}

var level_data: MathLevelData
var board_values: Array = []
var board_tiles: Array = []
var selected_cell := Vector2i(-1, -1)
var moves_used := 0
var goal_progress := 0
var puzzle_finished := false
var is_animating := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

func play_level(new_level_data: MathLevelData) -> void:
	level_data = new_level_data
	selected_cell = Vector2i(-1, -1)
	moves_used = 0
	goal_progress = 0
	puzzle_finished = false
	is_animating = false
	_build_board()
	_refresh_header()
	_refresh_board_visuals()
	message_changed.emit("Swap adjacent tiles to make a match.")

func _input(event: InputEvent) -> void:
	if level_data == null or not visible:
		return
	if not (event is InputEventMouseButton):
		return
	if is_animating:
		return

	var mouse_event := event as InputEventMouseButton
	if mouse_event.button_index != MOUSE_BUTTON_LEFT or not mouse_event.pressed:
		return

	var cell := _get_cell_at_global_position(mouse_event.position)
	if cell == Vector2i(-1, -1):
		return

	_on_tile_pressed(cell)

func _build_board() -> void:
	for child in get_children():
		child.queue_free()

	board_values.clear()
	board_tiles.clear()
	custom_minimum_size = Vector2(
		BOARD_PADDING.x * 2.0 + level_data.board_width * TILE_SIZE.x + (level_data.board_width - 1) * TILE_GAP.x,
		BOARD_PADDING.y * 2.0 + level_data.board_height * TILE_SIZE.y + (level_data.board_height - 1) * TILE_GAP.y
	)

	for y in range(level_data.board_height):
		board_values.append([])
		board_tiles.append([])
		for x in range(level_data.board_width):
			var value := _roll_value_without_starting_match(x, y)
			board_values[y].append(value)
			var tile := _create_tile_node(value)
			tile.position = _get_cell_position(Vector2i(x, y))
			add_child(tile)
			board_tiles[y].append(tile)

	while _find_all_matches().size() > 0:
		_rebuild_board_values()

func _rebuild_board_values() -> void:
	for y in range(level_data.board_height):
		for x in range(level_data.board_width):
			var value := _roll_palette_value()
			board_values[y][x] = value
			_set_tile_value(board_tiles[y][x], value)

func _create_tile_node(value: int) -> PanelContainer:
	var tile := PanelContainer.new()
	tile.custom_minimum_size = TILE_SIZE
	tile.size = TILE_SIZE
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	label.add_theme_color_override("font_color", Color("2f2a24"))
	tile.add_child(label)

	_set_tile_value(tile, value)
	return tile

func _set_tile_value(tile: Control, value: int) -> void:
	var label := tile.get_child(0) as Label
	label.text = _format_group_text(value)
	tile.add_theme_stylebox_override("panel", _make_tile_style(_get_tile_color(value)))

func _on_tile_pressed(cell: Vector2i) -> void:
	if puzzle_finished:
		message_changed.emit("Stage already complete.")
		return

	if selected_cell == Vector2i(-1, -1):
		selected_cell = cell
		message_changed.emit("Selected (%d, %d). Choose an adjacent tile." % [cell.x, cell.y])
		_refresh_board_visuals()
		return

	if selected_cell == cell:
		selected_cell = Vector2i(-1, -1)
		message_changed.emit("Selection cleared.")
		_refresh_board_visuals()
		return

	if not _is_adjacent(selected_cell, cell):
		selected_cell = cell
		message_changed.emit("Only adjacent tiles can swap. New tile selected.")
		_refresh_board_visuals()
		return

	var should_clear_selection := await _try_swap(selected_cell, cell)
	if should_clear_selection:
		selected_cell = Vector2i(-1, -1)
	_refresh_board_visuals()

func _try_swap(cell_a: Vector2i, cell_b: Vector2i) -> bool:
	is_animating = true
	var tile_a: Control = board_tiles[cell_a.y][cell_a.x]
	var tile_b: Control = board_tiles[cell_b.y][cell_b.x]
	var value_a := int(board_values[cell_a.y][cell_a.x])
	var value_b := int(board_values[cell_b.y][cell_b.x])

	board_tiles[cell_a.y][cell_a.x] = tile_b
	board_tiles[cell_b.y][cell_b.x] = tile_a
	board_values[cell_a.y][cell_a.x] = value_b
	board_values[cell_b.y][cell_b.x] = value_a

	await _animate_tiles_parallel([
		{"tile": tile_a, "cell": cell_b},
		{"tile": tile_b, "cell": cell_a},
	], _anim(0.18))

	var matches := _find_all_matches()
	moves_used += 1

	if matches.is_empty():
		board_tiles[cell_a.y][cell_a.x] = tile_a
		board_tiles[cell_b.y][cell_b.x] = tile_b
		board_values[cell_a.y][cell_a.x] = value_a
		board_values[cell_b.y][cell_b.x] = value_b
		_set_tile_style(tile_a, TILE_INVALID)
		_set_tile_style(tile_b, TILE_INVALID)
		message_changed.emit("No match. The tiles move back.")
		_refresh_header()
		await _wait(_anim(0.08))
		await _animate_tiles_parallel([
			{"tile": tile_a, "cell": cell_a},
			{"tile": tile_b, "cell": cell_b},
		], _anim(0.18))
		_refresh_board_visuals()
		_check_for_failure()
		is_animating = false
		return false

	await _resolve_matches(matches)
	_refresh_header()
	_check_for_completion()
	is_animating = false
	return true

func _resolve_matches(initial_matches: Array) -> void:
	var cascade_matches: Array = initial_matches
	var total_progress_gained := 0
	var cascade_count := 0

	while not cascade_matches.is_empty():
		cascade_count += 1
		total_progress_gained += ChapterRuleLibrary.collect_progress(level_data, cascade_matches, board_values)
		await _animate_match_clear(cascade_matches)
		await _collapse_board_with_animation()
		await _fill_empty_cells_with_animation()
		cascade_matches = _find_all_matches()

	goal_progress += total_progress_gained
	var message := ChapterRuleLibrary.get_progress_message(level_data, total_progress_gained)
	if cascade_count > 1:
		message += " Cascade x%d." % cascade_count
	message_changed.emit(message)

func _animate_match_clear(matches: Array) -> void:
	for cell in matches:
		var tile: Control = board_tiles[cell.y][cell.x]
		if tile != null:
			_set_tile_style(tile, TILE_MATCHED)

	await _wait(_anim(0.12))

	var tween := create_tween()
	for cell in matches:
		var tile: Control = board_tiles[cell.y][cell.x]
		if tile == null:
			continue
		tween.parallel().tween_property(tile, "scale", Vector2(0.2, 0.2), _anim(0.14))
		tween.parallel().tween_property(tile, "modulate:a", 0.0, _anim(0.14))
	await tween.finished

	for cell in matches:
		var tile: Control = board_tiles[cell.y][cell.x]
		if tile != null:
			tile.queue_free()
		board_tiles[cell.y][cell.x] = null
		board_values[cell.y][cell.x] = 0

func _collapse_board_with_animation() -> void:
	var moved: Array = []

	for x in range(level_data.board_width):
		var values_in_column: Array = []
		var tiles_in_column: Array = []
		for y in range(level_data.board_height - 1, -1, -1):
			var tile: Control = board_tiles[y][x]
			if tile != null:
				values_in_column.append(int(board_values[y][x]))
				tiles_in_column.append(tile)

		for y in range(level_data.board_height):
			board_tiles[y][x] = null
			board_values[y][x] = 0

		var write_y := level_data.board_height - 1
		for i in range(values_in_column.size()):
			var tile: Control = tiles_in_column[i]
			board_tiles[write_y][x] = tile
			board_values[write_y][x] = int(values_in_column[i])
			moved.append({"tile": tile, "cell": Vector2i(x, write_y)})
			write_y -= 1

	var tween := create_tween()
	for item in moved:
		tween.parallel().tween_property(item["tile"], "position", _get_cell_position(item["cell"]), _anim(0.18)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tween.finished

func _fill_empty_cells_with_animation() -> void:
	var spawned: Array = []

	for x in range(level_data.board_width):
		var empty_count := 0
		for y in range(level_data.board_height):
			if board_tiles[y][x] == null:
				empty_count += 1

		var spawn_index := 0
		for y in range(level_data.board_height):
			if board_tiles[y][x] != null:
				continue
			var value := _roll_palette_value()
			var tile := _create_tile_node(value)
			var start_y := -empty_count + spawn_index
			tile.position = _get_cell_position(Vector2i(x, start_y))
			add_child(tile)
			board_tiles[y][x] = tile
			board_values[y][x] = value
			spawned.append({"tile": tile, "cell": Vector2i(x, y)})
			spawn_index += 1

	var tween := create_tween()
	for item in spawned:
		tween.parallel().tween_property(item["tile"], "position", _get_cell_position(item["cell"]), _anim(0.22)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tween.finished

func _find_all_matches() -> Array:
	var matched := {}

	for y in range(level_data.board_height):
		var run_value := -1
		var run_start := 0
		var run_length := 0
		for x in range(level_data.board_width):
			var value := int(board_values[y][x])
			if value != 0 and value == run_value:
				run_length += 1
			else:
				_mark_run_if_match(matched, true, y, run_start, run_length, run_value)
				run_value = value
				run_start = x
				run_length = 1
		_mark_run_if_match(matched, true, y, run_start, run_length, run_value)

	for x in range(level_data.board_width):
		var run_value := -1
		var run_start := 0
		var run_length := 0
		for y in range(level_data.board_height):
			var value := int(board_values[y][x])
			if value != 0 and value == run_value:
				run_length += 1
			else:
				_mark_run_if_match(matched, false, x, run_start, run_length, run_value)
				run_value = value
				run_start = y
				run_length = 1
		_mark_run_if_match(matched, false, x, run_start, run_length, run_value)

	var results: Array = []
	for key in matched.keys():
		results.append(_string_to_cell(key))
	return results

func _mark_run_if_match(matched: Dictionary, horizontal: bool, fixed: int, start: int, length: int, value: int) -> void:
	if value == 0 or length < 3:
		return
	for offset in range(length):
		var cell := Vector2i(start + offset, fixed) if horizontal else Vector2i(fixed, start + offset)
		matched[_cell_to_string(cell)] = true

func _refresh_header() -> void:
	var title := "%s - Match 3" % level_data.title
	var goal_text := ChapterRuleLibrary.get_goal_label(level_data)
	var hint_text := "Hint: %s" % level_data.hint
	var stats_text := "Progress %d/%d   Moves %d/%d" % [goal_progress, level_data.goal_target_amount, moves_used, level_data.move_limit]
	header_changed.emit(title, goal_text, hint_text, stats_text)

func _refresh_board_visuals() -> void:
	var matches := _find_all_matches()
	for y in range(level_data.board_height):
		for x in range(level_data.board_width):
			var tile: Control = board_tiles[y][x]
			if tile == null:
				continue
			var cell := Vector2i(x, y)
			var value := int(board_values[y][x])
			_set_tile_value(tile, value)
			var style_color := _get_tile_color(value)
			if cell == selected_cell:
				style_color = TILE_SELECTED
			elif _contains_cell(matches, cell):
				style_color = TILE_MATCHED
			_set_tile_style(tile, style_color)

func _check_for_completion() -> void:
	if goal_progress < level_data.goal_target_amount:
		_check_for_failure()
		return
	puzzle_finished = true
	var stars := _calculate_stars()
	message_changed.emit("Stage clear. You earned %d star(s)." % stars)
	_refresh_header()
	level_completed.emit(stars)

func _check_for_failure() -> void:
	if moves_used < level_data.move_limit:
		return
	message_changed.emit("Out of moves. Restart the level or return to the map.")
	_refresh_header()
	out_of_moves.emit()

func _calculate_stars() -> int:
	var remaining := level_data.move_limit - moves_used
	var thresholds := level_data.star_thresholds
	if thresholds.size() >= 1 and remaining >= int(thresholds[0]):
		return 3
	if thresholds.size() >= 2 and remaining >= int(thresholds[1]):
		return 2
	return 1

func _roll_palette_value() -> int:
	if level_data.palette.is_empty():
		return 1
	return int(level_data.palette[randi() % level_data.palette.size()])

func _roll_value_without_starting_match(x: int, y: int) -> int:
	var candidate := _roll_palette_value()
	var guard := 0
	while guard < 12 and _would_create_match_at(x, y, candidate):
		candidate = _roll_palette_value()
		guard += 1
	return candidate

func _would_create_match_at(x: int, y: int, value: int) -> bool:
	if x >= 2 and int(board_values[y][x - 1]) == value and int(board_values[y][x - 2]) == value:
		return true
	if y >= 2 and int(board_values[y - 1][x]) == value and int(board_values[y - 2][x]) == value:
		return true
	return false

func _is_adjacent(cell_a: Vector2i, cell_b: Vector2i) -> bool:
	return abs(cell_a.x - cell_b.x) + abs(cell_a.y - cell_b.y) == 1

func _get_cell_position(cell: Vector2i) -> Vector2:
	return Vector2(
		BOARD_PADDING.x + cell.x * (TILE_SIZE.x + TILE_GAP.x),
		BOARD_PADDING.y + cell.y * (TILE_SIZE.y + TILE_GAP.y)
	)

func _animate_tiles_parallel(items: Array, duration: float) -> void:
	var tween := create_tween()
	for item in items:
		tween.parallel().tween_property(item["tile"], "position", _get_cell_position(item["cell"]), duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tween.finished

func _get_cell_at_global_position(mouse_global_position: Vector2) -> Vector2i:
	for y in range(level_data.board_height):
		for x in range(level_data.board_width):
			var tile: Control = board_tiles[y][x]
			if tile == null:
				continue
			var rect := Rect2(tile.global_position, TILE_SIZE)
			if rect.has_point(mouse_global_position):
				return Vector2i(x, y)
	return Vector2i(-1, -1)

func _format_group_text(value: int) -> String:
	var icons: Array[String] = []
	for _i in range(value):
		icons.append("o")
	return "%s\n\n%d" % [" ".join(icons), value]

func _get_tile_color(value: int) -> Color:
	return VALUE_COLORS.get(value, TILE_BASE)

func _set_tile_style(tile: Control, color: Color) -> void:
	tile.add_theme_stylebox_override("panel", _make_tile_style(color))

func _make_tile_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color("8e7d6b")
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_right = 16
	style.corner_radius_bottom_left = 16
	style.content_margin_left = 10
	style.content_margin_top = 10
	style.content_margin_right = 10
	style.content_margin_bottom = 10
	return style

func _cell_to_string(cell: Vector2i) -> String:
	return "%d,%d" % [cell.x, cell.y]

func _string_to_cell(key: String) -> Vector2i:
	var parts := key.split(",")
	return Vector2i(int(parts[0]), int(parts[1]))

func _contains_cell(cells: Array, target: Vector2i) -> bool:
	for cell in cells:
		if cell == target:
			return true
	return false

func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

func _anim(seconds: float) -> float:
	return seconds * ANIM_SPEED_SCALE
