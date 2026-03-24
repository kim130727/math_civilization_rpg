extends Control

const BOARD_WIDTH := 6
const BOARD_HEIGHT := 6

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
}

@onready var map_screen: Control = $MapScreen
@onready var puzzle_screen: Control = $PuzzleScreen
@onready var chapter_label: Label = $MapScreen/MarginContainer/VBoxContainer/HeaderPanel/MarginContainer/HeaderVBox/ChapterLabel
@onready var progress_label: Label = $MapScreen/MarginContainer/VBoxContainer/HeaderPanel/MarginContainer/HeaderVBox/ProgressLabel
@onready var chapter_note_label: Label = $MapScreen/MarginContainer/VBoxContainer/HeaderPanel/MarginContainer/HeaderVBox/ChapterNoteLabel
@onready var level_grid: GridContainer = $MapScreen/MarginContainer/VBoxContainer/BodyHBox/LevelsPanel/MarginContainer/LevelsVBox/LevelGrid
@onready var level_status_label: Label = $MapScreen/MarginContainer/VBoxContainer/BodyHBox/LevelsPanel/MarginContainer/LevelsVBox/LevelStatusLabel
@onready var restoration_preview_label: Label = $MapScreen/MarginContainer/VBoxContainer/BodyHBox/RestorePanel/MarginContainer/RestoreVBox/PreviewLabel
@onready var restoration_status_label: Label = $MapScreen/MarginContainer/VBoxContainer/BodyHBox/RestorePanel/MarginContainer/RestoreVBox/StatusLabel
@onready var restoration_task_list: VBoxContainer = $MapScreen/MarginContainer/VBoxContainer/BodyHBox/RestorePanel/MarginContainer/RestoreVBox/TaskList
@onready var addition_teaser_label: Label = $MapScreen/MarginContainer/VBoxContainer/FooterPanel/MarginContainer/FooterLabel
@onready var puzzle_title_label: Label = $PuzzleScreen/MarginContainer/VBoxContainer/PuzzleHeader/MarginContainer/HeaderVBox/PuzzleTitle
@onready var puzzle_goal_label: Label = $PuzzleScreen/MarginContainer/VBoxContainer/PuzzleHeader/MarginContainer/HeaderVBox/PuzzleGoal
@onready var puzzle_hint_label: Label = $PuzzleScreen/MarginContainer/VBoxContainer/PuzzleHeader/MarginContainer/HeaderVBox/PuzzleHint
@onready var puzzle_stats_label: Label = $PuzzleScreen/MarginContainer/VBoxContainer/PuzzleHeader/MarginContainer/HeaderVBox/PuzzleStats
@onready var puzzle_grid: GridContainer = $PuzzleScreen/MarginContainer/VBoxContainer/PuzzlePanel/MarginContainer/PuzzleGrid
@onready var puzzle_result_label: Label = $PuzzleScreen/MarginContainer/VBoxContainer/PuzzleFooter/ResultLabel
@onready var clear_button: Button = $PuzzleScreen/MarginContainer/VBoxContainer/PuzzleFooter/ButtonRow/ClearButton
@onready var back_button: Button = $PuzzleScreen/MarginContainer/VBoxContainer/PuzzleFooter/ButtonRow/BackButton
@onready var dialogue_box: CanvasLayer = $DialogueBox

var current_chapter_id := "counting"
var current_level_id := ""
var current_level_data: Dictionary = {}

var board_values: Array = []
var tile_controls: Array[Control] = []
var tile_labels: Array[Label] = []
var selected_cell := Vector2i(-1, -1)
var moves_used := 0
var goal_progress := 0
var puzzle_finished := false
var last_result_was_invalid := false
var debug_click_count := 0

func _ready() -> void:
	randomize()
	PuzzleProgress.progress_changed.connect(_refresh_map_screen)
	PuzzleProgress.chapter_unlocked.connect(_on_chapter_unlocked)
	clear_button.pressed.connect(_on_clear_button_pressed)
	back_button.pressed.connect(_return_to_map)

	_refresh_map_screen()
	_show_map()
	_show_intro_messages()

func _refresh_map_screen() -> void:
	var chapter := PuzzleProgress.get_chapter(current_chapter_id)
	var completed_levels := PuzzleProgress.get_completed_level_count(current_chapter_id)
	var total_levels := PuzzleProgress.get_levels_for_chapter(current_chapter_id).size()
	var total_stars := PuzzleProgress.get_total_stars(current_chapter_id)
	var available_stars := PuzzleProgress.get_available_stars(current_chapter_id)
	var restoration_percent := int(round(PuzzleProgress.get_restoration_completion_ratio(current_chapter_id) * 100.0))

	chapter_label.text = "Chapter 1. %s" % chapter.get("title", "Counting Village")
	progress_label.text = "Levels %d/%d   Stars %d   Spendable %d   Restore %d%%" % [completed_levels, total_levels, total_stars, available_stars, restoration_percent]
	chapter_note_label.text = "This chapter uses a match-3 board. Match counted groups to restore the village."

	_rebuild_level_buttons()
	_rebuild_restoration_tasks()
	_refresh_restoration_preview()

	if PuzzleProgress.is_chapter_unlocked("addition"):
		addition_teaser_label.text = "Next chapter unlocked: Addition Bridge is now open."
	else:
		addition_teaser_label.text = "Next chapter preview: finish all counting levels and restoration tasks to unlock Addition Bridge."

func _rebuild_level_buttons() -> void:
	for child in level_grid.get_children():
		child.queue_free()

	var levels := PuzzleProgress.get_levels_for_chapter(current_chapter_id)
	for i in range(levels.size()):
		var level: Dictionary = levels[i]
		var button := Button.new()
		button.custom_minimum_size = Vector2(160, 96)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.text = _build_level_button_text(level)
		button.disabled = not _is_level_unlocked(i)
		button.pressed.connect(_open_level.bind(level["id"]))
		level_grid.add_child(button)

	level_status_label.text = "Swap adjacent tiles to make matches of 3 or more. Matching the target number fills the level goal."

func _rebuild_restoration_tasks() -> void:
	for child in restoration_task_list.get_children():
		child.queue_free()

	var tasks := PuzzleProgress.get_restoration_tasks_for_chapter(current_chapter_id)
	for task in tasks:
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 72)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var completed := PuzzleProgress.is_restoration_completed(task["id"])
		var affordable := PuzzleProgress.get_available_stars(current_chapter_id) >= int(task["cost"])
		button.text = _build_restoration_button_text(task, completed)
		button.disabled = completed or not affordable
		button.pressed.connect(_restore_task.bind(task["id"]))
		restoration_task_list.add_child(button)

	restoration_status_label.text = "Spend stars to restore the district. Restoration still drives chapter progression."

func _refresh_restoration_preview() -> void:
	var ratio := PuzzleProgress.get_restoration_completion_ratio(current_chapter_id)
	if ratio <= 0.0:
		restoration_preview_label.text = "[Foggy Square]\nSigns are blurred and objects are mixed together.\nNothing is easy to count yet."
	elif ratio < 0.34:
		restoration_preview_label.text = "[Ordered Plaza]\nThe village starts to separate objects into neat groups.\nPeople begin naming what they can count."
	elif ratio < 0.67:
		restoration_preview_label.text = "[Bright Street]\nLanterns hang in rhythm and market items line up in visible sets."
	elif ratio < 1.0:
		restoration_preview_label.text = "[Living Market]\nShelves, signs, and bundles become readable.\nCounting now feels natural in the world."
	else:
		restoration_preview_label.text = "[Counting Village Complete]\nThe plaza, lantern rows, and market are fully restored.\nAddition is waiting across the bridge."

func _open_level(level_id: String) -> void:
	current_level_id = level_id
	current_level_data = PuzzleProgress.get_level(level_id)
	if dialogue_box.has_method("hide_dialogue"):
		dialogue_box.call("hide_dialogue")
	selected_cell = Vector2i(-1, -1)
	moves_used = 0
	goal_progress = 0
	puzzle_finished = false
	last_result_was_invalid = false
	debug_click_count = 0

	_build_match3_board()
	_refresh_puzzle_header()
	_refresh_board_visuals()
	_show_puzzle()

func _build_match3_board() -> void:
	for child in puzzle_grid.get_children():
		child.queue_free()

	board_values.clear()
	tile_controls.clear()
	tile_labels.clear()
	puzzle_grid.columns = BOARD_WIDTH

	for y in range(BOARD_HEIGHT):
		var row: Array[int] = []
		board_values.append(row)
		for x in range(BOARD_WIDTH):
			var value := _roll_value_without_starting_match(x, y)
			board_values[y].append(value)

	for y in range(BOARD_HEIGHT):
		for x in range(BOARD_WIDTH):
			var panel := PanelContainer.new()
			panel.custom_minimum_size = Vector2(110, 92)
			panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

			var label := Label.new()
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			label.size_flags_vertical = Control.SIZE_EXPAND_FILL
			label.add_theme_color_override("font_color", Color("2f2a24"))

			panel.add_child(label)
			puzzle_grid.add_child(panel)
			tile_controls.append(panel)
			tile_labels.append(label)

	while _find_all_matches().size() > 0:
		_refill_board_without_progress()

	if tile_controls.is_empty():
		return

func _on_tile_pressed(cell: Vector2i) -> void:
	debug_click_count += 1

	if puzzle_finished:
		puzzle_result_label.text = "Click %d: stage already complete. Click Back to map." % debug_click_count
		return

	if selected_cell == Vector2i(-1, -1):
		selected_cell = cell
		puzzle_result_label.text = "Click %d: selected (%d, %d). Choose an adjacent tile." % [debug_click_count, cell.x, cell.y]
		_refresh_board_visuals()
		return

	if selected_cell == cell:
		selected_cell = Vector2i(-1, -1)
		puzzle_result_label.text = "Click %d: selection cleared." % debug_click_count
		_refresh_board_visuals()
		return

	if not _is_adjacent(selected_cell, cell):
		selected_cell = cell
		puzzle_result_label.text = "Click %d: not adjacent, new selection is (%d, %d)." % [debug_click_count, cell.x, cell.y]
		_refresh_board_visuals()
		return

	var should_clear_selection := _try_swap(selected_cell, cell)
	if should_clear_selection:
		selected_cell = Vector2i(-1, -1)
	_refresh_board_visuals()

func _input(event: InputEvent) -> void:
	if not puzzle_screen.visible:
		return
	if puzzle_finished and not (event is InputEventMouseButton):
		return
	if not (event is InputEventMouseButton):
		return

	var mouse_event := event as InputEventMouseButton
	if mouse_event.button_index != MOUSE_BUTTON_LEFT or not mouse_event.pressed:
		return

	var cell := _get_cell_at_global_position(mouse_event.position)
	if cell == Vector2i(-1, -1):
		return

	_on_tile_pressed(cell)

func _try_swap(cell_a: Vector2i, cell_b: Vector2i) -> bool:
	_swap_cells(cell_a, cell_b)
	var matches := _find_all_matches()
	moves_used += 1

	if matches.is_empty():
		_swap_cells(cell_a, cell_b)
		last_result_was_invalid = true
		selected_cell = cell_b
		puzzle_result_label.text = "Click %d: no match, swap canceled. Selected (%d, %d)." % [debug_click_count, cell_b.x, cell_b.y]
		_refresh_puzzle_header()
		_flash_invalid_swap(cell_a, cell_b)
		_refresh_board_visuals()
		_check_for_failure()
		return false

	last_result_was_invalid = false
	_resolve_matches(matches)
	_refresh_puzzle_header()
	_check_for_completion()
	return true

func _resolve_matches(initial_matches: Array) -> void:
	var cascade_matches: Array = initial_matches
	var total_target_collected := 0
	var cascade_count := 0

	while not cascade_matches.is_empty():
		cascade_count += 1
		total_target_collected += _collect_goal_tiles(cascade_matches)
		_clear_matches(cascade_matches)
		_collapse_board()
		_fill_empty_cells()
		cascade_matches = _find_all_matches()

	goal_progress += total_target_collected
	var target_value := int(current_level_data.get("goal_value", 1))
	puzzle_result_label.text = "Matched %d group tile(s) for value %d." % [total_target_collected, target_value]
	if cascade_count > 1:
		puzzle_result_label.text += " Cascade x%d." % cascade_count

func _collect_goal_tiles(matches: Array) -> int:
	var goal_value := int(current_level_data.get("goal_value", 1))
	var collected := 0
	for cell in matches:
		if _get_board_value(cell) == goal_value:
			collected += 1
	return collected

func _clear_matches(matches: Array) -> void:
	for cell in matches:
		_set_board_value(cell, 0)

func _collapse_board() -> void:
	for x in range(BOARD_WIDTH):
		var kept: Array[int] = []
		for y in range(BOARD_HEIGHT - 1, -1, -1):
			var value := int(board_values[y][x])
			if value != 0:
				kept.append(value)

		var write_y := BOARD_HEIGHT - 1
		for value in kept:
			board_values[write_y][x] = value
			write_y -= 1

		while write_y >= 0:
			board_values[write_y][x] = 0
			write_y -= 1

func _fill_empty_cells() -> void:
	var palette: Array = current_level_data.get("palette", [1, 2, 3])
	for y in range(BOARD_HEIGHT):
		for x in range(BOARD_WIDTH):
			if int(board_values[y][x]) == 0:
				board_values[y][x] = int(palette[randi() % palette.size()])

func _refill_board_without_progress() -> void:
	var palette: Array = current_level_data.get("palette", [1, 2, 3])
	for y in range(BOARD_HEIGHT):
		for x in range(BOARD_WIDTH):
			board_values[y][x] = int(palette[randi() % palette.size()])

func _find_all_matches() -> Array:
	if board_values.size() != BOARD_HEIGHT:
		return []
	for row in board_values:
		if row is Array and row.size() != BOARD_WIDTH:
			return []

	var matched := {}

	for y in range(BOARD_HEIGHT):
		var run_value := -1
		var run_start := 0
		var run_length := 0
		for x in range(BOARD_WIDTH):
			var value := int(board_values[y][x])
			if value != 0 and value == run_value:
				run_length += 1
			else:
				_mark_run_if_match(matched, true, y, run_start, run_length, run_value)
				run_value = value
				run_start = x
				run_length = 1
		_mark_run_if_match(matched, true, y, run_start, run_length, run_value)

	for x in range(BOARD_WIDTH):
		var run_value := -1
		var run_start := 0
		var run_length := 0
		for y in range(BOARD_HEIGHT):
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

func _refresh_puzzle_header() -> void:
	var title: String = current_level_data.get("title", "")
	var goal_value := int(current_level_data.get("goal_value", 1))
	var goal_count := int(current_level_data.get("goal_count", 0))
	var move_limit := int(current_level_data.get("move_limit", 0))
	var hint: String = current_level_data.get("hint", "")

	puzzle_title_label.text = "%s - Match 3" % title
	puzzle_goal_label.text = "Goal: collect %d tile(s) showing value %d." % [goal_count, goal_value]
	puzzle_hint_label.text = "Hint: %s" % hint
	puzzle_stats_label.text = "Collected %d/%d   Moves %d/%d" % [goal_progress, goal_count, moves_used, move_limit]
	clear_button.disabled = false

	if puzzle_finished:
		clear_button.text = "Back to map"
	else:
		clear_button.text = "Restart level"

func _refresh_board_visuals() -> void:
	if tile_controls.size() != BOARD_WIDTH * BOARD_HEIGHT:
		return
	if board_values.size() != BOARD_HEIGHT:
		return

	var matches := _find_all_matches()
	for y in range(BOARD_HEIGHT):
		for x in range(BOARD_WIDTH):
			var cell := Vector2i(x, y)
			var tile := tile_controls[_cell_to_index(cell)]
			var label := tile_labels[_cell_to_index(cell)]
			var value := _get_board_value(cell)
			var style_color := _get_tile_color(value)

			if cell == selected_cell:
				style_color = TILE_SELECTED
			elif _contains_cell(matches, cell):
				style_color = TILE_MATCHED
			elif last_result_was_invalid:
				style_color = _get_tile_color(value)

			label.text = _format_group_text(value)
			tile.add_theme_stylebox_override("panel", _make_tile_style(style_color))

func _flash_invalid_swap(cell_a: Vector2i, cell_b: Vector2i) -> void:
	if tile_controls.size() != BOARD_WIDTH * BOARD_HEIGHT:
		return

	for cell in [cell_a, cell_b]:
		var tile := tile_controls[_cell_to_index(cell)]
		tile.add_theme_stylebox_override("panel", _make_tile_style(TILE_INVALID))

func _check_for_completion() -> void:
	var goal_count := int(current_level_data.get("goal_count", 0))
	if goal_progress >= goal_count:
		puzzle_finished = true
		var stars := _calculate_stars()
		PuzzleProgress.complete_level(current_level_id, stars)
		puzzle_result_label.text = "Stage clear. You earned %d star(s)." % stars
		_refresh_puzzle_header()
		return

	_check_for_failure()

func _check_for_failure() -> void:
	var move_limit := int(current_level_data.get("move_limit", 0))
	if puzzle_finished:
		return
	if moves_used < move_limit:
		return

	puzzle_result_label.text = "Out of moves. Restart the level or return to the map."
	_refresh_puzzle_header()

func _calculate_stars() -> int:
	var move_limit := int(current_level_data.get("move_limit", 0))
	var remaining := move_limit - moves_used
	if remaining >= 5:
		return 3
	if remaining >= 2:
		return 2
	return 1

func _on_clear_button_pressed() -> void:
	if puzzle_finished:
		_return_to_map()
	else:
		_open_level(current_level_id)

func _return_to_map() -> void:
	_show_map()
	_refresh_map_screen()

func _restore_task(task_id: String) -> void:
	var task := {}
	for item in PuzzleProgress.get_restoration_tasks_for_chapter(current_chapter_id):
		if item["id"] == task_id:
			task = item
			break

	if task.is_empty():
		return

	if PuzzleProgress.complete_restoration(task_id):
		DialogueManager.show_text("%s\n\n%s" % [task["title"], task["description"]])
	else:
		DialogueManager.show_text("You need more stars. Clear more puzzle stages first.")

func _build_level_button_text(level: Dictionary) -> String:
	var level_id: String = level["id"]
	var best_stars := PuzzleProgress.get_stars_for_level(level_id)
	var star_text := "Not cleared"
	if best_stars > 0:
		star_text = "Best %d star(s)" % best_stars
	return "%s\nCollect %d of %d\n%s" % [level["title"], int(level["goal_count"]), int(level["goal_value"]), star_text]

func _build_restoration_button_text(task: Dictionary, completed: bool) -> String:
	if completed:
		return "%s\nRestored" % task["title"]
	return "%s\nCost %d star(s)" % [task["title"], int(task["cost"])]

func _is_level_unlocked(index: int) -> bool:
	if index == 0:
		return true
	var levels := PuzzleProgress.get_levels_for_chapter(current_chapter_id)
	var previous_level_id: String = levels[index - 1]["id"]
	return PuzzleProgress.get_stars_for_level(previous_level_id) > 0

func _format_group_text(value: int) -> String:
	var icons: Array[String] = []
	for _i in range(value):
		icons.append("o")
	return "%s\n\n%d" % [" ".join(icons), value]

func _get_tile_color(value: int) -> Color:
	return VALUE_COLORS.get(value, TILE_BASE)

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

func _roll_value_without_starting_match(x: int, y: int) -> int:
	var palette: Array = current_level_data.get("palette", [1, 2, 3])
	if palette.is_empty():
		palette = [1, 2, 3]
	var candidate := int(palette[randi() % palette.size()])
	var guard := 0
	while guard < 12 and _would_create_match_at(x, y, candidate):
		candidate = int(palette[randi() % palette.size()])
		guard += 1
	return candidate

func _would_create_match_at(x: int, y: int, value: int) -> bool:
	if x >= 2:
		if int(board_values[y][x - 1]) == value and int(board_values[y][x - 2]) == value:
			return true
	if y >= 2:
		if int(board_values[y - 1][x]) == value and int(board_values[y - 2][x]) == value:
			return true
	return false

func _is_adjacent(cell_a: Vector2i, cell_b: Vector2i) -> bool:
	return abs(cell_a.x - cell_b.x) + abs(cell_a.y - cell_b.y) == 1

func _swap_cells(cell_a: Vector2i, cell_b: Vector2i) -> void:
	var value_a := _get_board_value(cell_a)
	var value_b := _get_board_value(cell_b)
	_set_board_value(cell_a, value_b)
	_set_board_value(cell_b, value_a)

func _get_board_value(cell: Vector2i) -> int:
	if cell.y < 0 or cell.y >= board_values.size():
		return 0
	if cell.x < 0 or cell.y < 0:
		return 0
	var row = board_values[cell.y]
	if not (row is Array):
		return 0
	if cell.x >= row.size():
		return 0
	return int(board_values[cell.y][cell.x])

func _set_board_value(cell: Vector2i, value: int) -> void:
	if cell.y < 0 or cell.y >= board_values.size():
		return
	var row = board_values[cell.y]
	if not (row is Array):
		return
	if cell.x < 0 or cell.x >= row.size():
		return
	board_values[cell.y][cell.x] = value

func _cell_to_index(cell: Vector2i) -> int:
	return cell.y * BOARD_WIDTH + cell.x

func _get_cell_at_global_position(mouse_global_position: Vector2) -> Vector2i:
	for index in range(tile_controls.size()):
		var tile := tile_controls[index]
		var rect := Rect2(tile.global_position, tile.size)
		if rect.has_point(mouse_global_position):
			return Vector2i(index % BOARD_WIDTH, index / BOARD_WIDTH)
	return Vector2i(-1, -1)


func _cell_to_string(cell: Vector2i) -> String:
	return "%d,%d" % [cell.x, cell.y]

func _string_to_cell(key: String) -> Vector2i:
	var parts := key.split(",")
	if parts.size() < 2:
		return Vector2i.ZERO
	return Vector2i(int(parts[0]), int(parts[1]))

func _contains_cell(cells: Array, target: Vector2i) -> bool:
	for cell in cells:
		if cell == target:
			return true
	return false

func _show_map() -> void:
	map_screen.show()
	puzzle_screen.hide()

func _show_puzzle() -> void:
	map_screen.hide()
	puzzle_screen.show()

func _show_intro_messages() -> void:
	DialogueManager.show_text("Welcome to Counting Village.\n\nThe meta loop stays the same, but the puzzle core is now a match-3 board.")

func _on_chapter_unlocked(chapter_id: String) -> void:
	if chapter_id == "addition":
		DialogueManager.show_text("New chapter unlocked.\n\nAddition Bridge is ready for the next puzzle set.")
