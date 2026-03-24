extends Control

@onready var map_screen: Control = $MapScreen
@onready var puzzle_screen: Control = $PuzzleScreen
@onready var chapter_label: Label = $MapScreen/MarginContainer/VBoxContainer/HeaderPanel/MarginContainer/HeaderVBox/ChapterLabel
@onready var progress_label: Label = $MapScreen/MarginContainer/VBoxContainer/HeaderPanel/MarginContainer/HeaderVBox/ProgressLabel
@onready var chapter_note_label: Label = $MapScreen/MarginContainer/VBoxContainer/HeaderPanel/MarginContainer/HeaderVBox/ChapterNoteLabel
@onready var chapter_tabs: HBoxContainer = $MapScreen/MarginContainer/VBoxContainer/HeaderPanel/MarginContainer/HeaderVBox/ChapterTabs
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
@onready var board_mount: Match3BoardController = $PuzzleScreen/MarginContainer/VBoxContainer/PuzzlePanel/MarginContainer/PuzzleGrid
@onready var puzzle_result_label: Label = $PuzzleScreen/MarginContainer/VBoxContainer/PuzzleFooter/ResultLabel
@onready var clear_button: Button = $PuzzleScreen/MarginContainer/VBoxContainer/PuzzleFooter/ButtonRow/ClearButton
@onready var back_button: Button = $PuzzleScreen/MarginContainer/VBoxContainer/PuzzleFooter/ButtonRow/BackButton
@onready var dialogue_box: CanvasLayer = $DialogueBox

var current_chapter_id := "counting"
var current_level_id := ""
var clear_timer: SceneTreeTimer

func _ready() -> void:
	PuzzleProgress.progress_changed.connect(_refresh_map_screen)
	PuzzleProgress.chapter_unlocked.connect(_on_chapter_unlocked)
	board_mount.header_changed.connect(_on_board_header_changed)
	board_mount.message_changed.connect(_on_board_message_changed)
	board_mount.level_completed.connect(_on_board_level_completed)
	board_mount.out_of_moves.connect(_on_board_out_of_moves)
	clear_button.pressed.connect(_on_clear_button_pressed)
	back_button.pressed.connect(_return_to_map)

	_refresh_map_screen()
	_show_map()
	_show_intro_messages()

func _refresh_map_screen() -> void:
	var chapter := PuzzleProgress.get_chapter(current_chapter_id)
	var grade := PuzzleProgress.get_grade(String(chapter.get("grade_id", "")))
	var completed_levels := PuzzleProgress.get_completed_level_count(current_chapter_id)
	var total_levels := PuzzleProgress.get_levels_for_chapter(current_chapter_id).size()
	var total_stars := PuzzleProgress.get_total_stars(current_chapter_id)
	var available_stars := PuzzleProgress.get_available_stars(current_chapter_id)
	var restoration_percent := int(round(PuzzleProgress.get_restoration_completion_ratio(current_chapter_id) * 100.0))

	var chapter_title := String(chapter.get("title", "Math District"))
	var grade_title := String(grade.get("title", ""))
	chapter_label.text = chapter_title if grade_title == "" else "%s - %s" % [grade_title, chapter_title]
	progress_label.text = "Levels %d/%d   Stars %d   Spendable %d   Restore %d%%" % [completed_levels, total_levels, total_stars, available_stars, restoration_percent]
	chapter_note_label.text = ChapterRuleLibrary.get_chapter_note(current_chapter_id)

	_rebuild_chapter_tabs()
	_rebuild_level_buttons()
	_rebuild_restoration_tasks()
	_refresh_restoration_preview()

	if PuzzleProgress.is_chapter_unlocked("addition"):
		addition_teaser_label.text = "Addition Bridge is unlocked. Grade 1 now expands from counting into visible sums."
	else:
		addition_teaser_label.text = "Finish the counting district to unlock the first addition district."

func _rebuild_chapter_tabs() -> void:
	for child in chapter_tabs.get_children():
		child.queue_free()

	var current_grade_id := String(PuzzleProgress.get_chapter(current_chapter_id).get("grade_id", "grade1"))
	for chapter in PuzzleProgress.get_chapters_for_grade(current_grade_id):
		var chapter_id: String = chapter["id"]
		var button := Button.new()
		button.text = chapter["title"]
		button.custom_minimum_size = Vector2(180, 42)
		button.disabled = not PuzzleProgress.is_chapter_unlocked(chapter_id) or chapter_id == current_chapter_id
		button.pressed.connect(_switch_chapter.bind(chapter_id))
		chapter_tabs.add_child(button)

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

	level_status_label.text = ChapterRuleLibrary.get_level_status_text(current_chapter_id)

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

	restoration_status_label.text = "Spend stars to restore the district. Restorations scale one district at a time."

func _refresh_restoration_preview() -> void:
	var ratio := PuzzleProgress.get_restoration_completion_ratio(current_chapter_id)
	if current_chapter_id == "addition":
		if ratio <= 0.0:
			restoration_preview_label.text = "[Broken Bridge]\nStone blocks sit in separated piles.\nThe world is asking for sums."
		elif ratio < 0.67:
			restoration_preview_label.text = "[Rising Span]\nSupport pillars align and the bridge starts forming a full arc."
		else:
			restoration_preview_label.text = "[Open Crossing]\nThe bridge now supports travelers and grouped supplies."
		return

	if ratio <= 0.0:
		restoration_preview_label.text = "[Foggy Square]\nSigns are blurred and objects are mixed together.\nNothing is easy to count yet."
	elif ratio < 0.67:
		restoration_preview_label.text = "[Ordered Plaza]\nThe village starts to separate objects into neat groups."
	else:
		restoration_preview_label.text = "[Counting Village Complete]\nThe plaza, lantern rows, and market are fully restored."

func _open_level(level_id: String) -> void:
	current_level_id = level_id
	if dialogue_box.has_method("hide_dialogue"):
		dialogue_box.call("hide_dialogue")
	board_mount.play_level(PuzzleProgress.get_level_resource(level_id))
	clear_button.text = "Restart level"
	_show_puzzle()

func _on_board_header_changed(title: String, goal_text: String, hint_text: String, stats_text: String) -> void:
	puzzle_title_label.text = title
	puzzle_goal_label.text = goal_text
	puzzle_hint_label.text = hint_text
	puzzle_stats_label.text = stats_text

func _on_board_message_changed(text: String) -> void:
	puzzle_result_label.text = text

func _on_board_level_completed(stars: int) -> void:
	PuzzleProgress.complete_level(current_level_id, stars)
	clear_button.text = "Back to map"
	_go_to_next_level_after_clear()

func _on_board_out_of_moves() -> void:
	clear_button.text = "Restart level"

func _on_clear_button_pressed() -> void:
	if clear_timer != null:
		clear_timer = null
	var level := PuzzleProgress.get_level(current_level_id)
	if level.is_empty():
		_return_to_map()
		return
	if PuzzleProgress.get_stars_for_level(current_level_id) > 0 and puzzle_result_label.text.begins_with("Stage clear"):
		_return_to_map()
	else:
		_open_level(current_level_id)

func _go_to_next_level_after_clear() -> void:
	var levels := PuzzleProgress.get_levels_for_chapter(current_chapter_id)
	for i in range(levels.size()):
		if levels[i]["id"] != current_level_id:
			continue
		clear_timer = get_tree().create_timer(0.45)
		if i + 1 < levels.size():
			clear_timer.timeout.connect(_open_level.bind(levels[i + 1]["id"]), CONNECT_ONE_SHOT)
		else:
			clear_timer.timeout.connect(_return_to_map, CONNECT_ONE_SHOT)
		return

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
		DialogueManager.show_text("You need more stars. Clear more stages first.")

func _build_level_button_text(level: Dictionary) -> String:
	var level_id: String = level["id"]
	var best_stars := PuzzleProgress.get_stars_for_level(level_id)
	var star_text := "Not cleared"
	if best_stars > 0:
		star_text = "Best %d star(s)" % best_stars
	if level.get("rule_type", "counting_collect") == "addition_total":
		return "%s\nReach total %d\n%s" % [level["title"], int(level["goal_target_amount"]), star_text]
	return "%s\nCollect %d of %d\n%s" % [level["title"], int(level["goal_target_amount"]), int(level["goal_target_value"]), star_text]

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

func _switch_chapter(chapter_id: String) -> void:
	if not PuzzleProgress.is_chapter_unlocked(chapter_id):
		return
	current_chapter_id = chapter_id
	_refresh_map_screen()

func _show_map() -> void:
	map_screen.show()
	puzzle_screen.hide()

func _show_puzzle() -> void:
	map_screen.hide()
	puzzle_screen.show()

func _show_intro_messages() -> void:
	DialogueManager.show_text("Welcome to Math Civilization Puzzle.\n\nGrade 1 starts with counting, then grows into visible addition.")

func _on_chapter_unlocked(chapter_id: String) -> void:
	if chapter_id == "addition":
		DialogueManager.show_text("New unit unlocked.\n\nAddition Bridge is now available.")
