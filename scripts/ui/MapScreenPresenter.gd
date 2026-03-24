extends RefCounted
class_name MapScreenPresenter

var chapter_label: Label
var progress_label: Label
var chapter_note_label: Label
var chapter_tabs: HBoxContainer
var level_grid: GridContainer
var level_status_label: Label
var restoration_preview_label: Label
var restoration_status_label: Label
var restoration_task_list: VBoxContainer
var footer_label: Label

func configure(refs: Dictionary) -> void:
	chapter_label = refs["chapter_label"]
	progress_label = refs["progress_label"]
	chapter_note_label = refs["chapter_note_label"]
	chapter_tabs = refs["chapter_tabs"]
	level_grid = refs["level_grid"]
	level_status_label = refs["level_status_label"]
	restoration_preview_label = refs["restoration_preview_label"]
	restoration_status_label = refs["restoration_status_label"]
	restoration_task_list = refs["restoration_task_list"]
	footer_label = refs["footer_label"]

func render(current_chapter_id: String, on_switch_chapter: Callable, on_open_level: Callable, on_restore_task: Callable) -> void:
	var chapter: Dictionary = PuzzleProgress.get_chapter(current_chapter_id)
	var grade: Dictionary = PuzzleProgress.get_grade(String(chapter.get("grade_id", "")))
	var completed_levels: int = PuzzleProgress.get_completed_level_count(current_chapter_id)
	var total_levels: int = PuzzleProgress.get_levels_for_chapter(current_chapter_id).size()
	var total_stars: int = PuzzleProgress.get_total_stars(current_chapter_id)
	var available_stars: int = PuzzleProgress.get_available_stars(current_chapter_id)
	var restoration_percent := int(round(PuzzleProgress.get_restoration_completion_ratio(current_chapter_id) * 100.0))

	var chapter_title := String(chapter.get("title", "Math District"))
	var grade_title := String(grade.get("title", ""))
	chapter_label.text = chapter_title if grade_title == "" else "%s - %s" % [grade_title, chapter_title]
	progress_label.text = "Levels %d/%d   Stars %d   Spendable %d   Restore %d%%" % [completed_levels, total_levels, total_stars, available_stars, restoration_percent]
	chapter_note_label.text = ChapterRuleLibrary.get_chapter_note(current_chapter_id)

	_rebuild_chapter_tabs(current_chapter_id, on_switch_chapter)
	_rebuild_level_buttons(current_chapter_id, on_open_level)
	_rebuild_restoration_tasks(current_chapter_id, on_restore_task)
	_refresh_restoration_preview(current_chapter_id)
	_refresh_footer(current_chapter_id)

func _rebuild_chapter_tabs(current_chapter_id: String, on_switch_chapter: Callable) -> void:
	for child in chapter_tabs.get_children():
		child.queue_free()

	var current_grade_id := String(PuzzleProgress.get_chapter(current_chapter_id).get("grade_id", "grade1"))
	for chapter in PuzzleProgress.get_chapters_for_grade(current_grade_id):
		var chapter_id: String = chapter["id"]
		var button := Button.new()
		button.text = chapter["title"]
		button.custom_minimum_size = Vector2(180, 42)
		button.disabled = not PuzzleProgress.is_chapter_unlocked(chapter_id) or chapter_id == current_chapter_id
		button.pressed.connect(on_switch_chapter.bind(chapter_id))
		chapter_tabs.add_child(button)

func _rebuild_level_buttons(current_chapter_id: String, on_open_level: Callable) -> void:
	for child in level_grid.get_children():
		child.queue_free()

	var levels: Array = PuzzleProgress.get_levels_for_chapter(current_chapter_id)
	for i in range(levels.size()):
		var level: Dictionary = levels[i]
		var button := Button.new()
		button.custom_minimum_size = Vector2(160, 96)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.text = _build_level_button_text(level)
		button.disabled = not PuzzleProgress.is_level_unlocked(current_chapter_id, i)
		button.pressed.connect(on_open_level.bind(level["id"]))
		level_grid.add_child(button)

	level_status_label.text = ChapterRuleLibrary.get_level_status_text(current_chapter_id)

func _rebuild_restoration_tasks(current_chapter_id: String, on_restore_task: Callable) -> void:
	for child in restoration_task_list.get_children():
		child.queue_free()

	var tasks: Array = PuzzleProgress.get_restoration_tasks_for_chapter(current_chapter_id)
	for task in tasks:
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 72)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var completed: bool = PuzzleProgress.is_restoration_completed(task["id"])
		var affordable: bool = PuzzleProgress.get_available_stars(current_chapter_id) >= int(task["cost"])
		button.text = _build_restoration_button_text(task, completed)
		button.disabled = completed or not affordable
		button.pressed.connect(on_restore_task.bind(task["id"]))
		restoration_task_list.add_child(button)

	restoration_status_label.text = "Spend stars to restore the district. Restoration completes a chapter and opens the next concept."

func _refresh_restoration_preview(current_chapter_id: String) -> void:
	var ratio := PuzzleProgress.get_restoration_completion_ratio(current_chapter_id)
	match current_chapter_id:
		"addition":
			if ratio <= 0.0:
				restoration_preview_label.text = "[Broken Bridge]\nStone blocks sit in separated piles.\nThe world is asking for visible sums."
			elif ratio < 0.67:
				restoration_preview_label.text = "[Rising Span]\nSupport pillars align and the bridge starts forming a full arc."
			else:
				restoration_preview_label.text = "[Open Crossing]\nThe bridge now supports travelers and grouped supplies."
		"multiplication":
			if ratio <= 0.0:
				restoration_preview_label.text = "[Empty Workshop]\nRows of beams wait to be arranged into equal groups."
			elif ratio < 0.67:
				restoration_preview_label.text = "[Working Yard]\nFrames and crates line up in repeatable rows."
			else:
				restoration_preview_label.text = "[Array Foundry]\nThe workshop now builds structures in stable repeated patterns."
		_:
			if ratio <= 0.0:
				restoration_preview_label.text = "[Foggy Square]\nSigns are blurred and objects are mixed together.\nNothing is easy to count yet."
			elif ratio < 0.67:
				restoration_preview_label.text = "[Ordered Plaza]\nThe village starts to separate objects into neat groups."
			else:
				restoration_preview_label.text = "[Counting Village Complete]\nThe plaza, lantern rows, and market are fully restored."

func _refresh_footer(current_chapter_id: String) -> void:
	if PuzzleProgress.is_chapter_unlocked("multiplication"):
		footer_label.text = "Multiplication Workshop is unlocked. Repeated groups now rebuild the world."
	elif PuzzleProgress.is_chapter_unlocked("addition"):
		footer_label.text = "Addition Bridge is unlocked. Grade 1 now expands from counting into visible sums."
	else:
		footer_label.text = "Finish the counting district to unlock the first addition district."

func _build_level_button_text(level: Dictionary) -> String:
	var level_id: String = level["id"]
	var best_stars := PuzzleProgress.get_stars_for_level(level_id)
	var star_text := "Not cleared"
	if best_stars > 0:
		star_text = "Best %d star(s)" % best_stars

	match String(level.get("rule_type", "counting_collect")):
		"addition_total":
			return "%s\nReach total %d\n%s" % [level["title"], int(level["goal_target_amount"]), star_text]
		"multiplication_total":
			return "%s\nBuild product %d\n%s" % [level["title"], int(level["goal_target_amount"]), star_text]
		_:
			return "%s\nCollect %d of %d\n%s" % [level["title"], int(level["goal_target_amount"]), int(level["goal_target_value"]), star_text]

func _build_restoration_button_text(task: Dictionary, completed: bool) -> String:
	if completed:
		return "%s\nRestored" % task["title"]
	return "%s\nCost %d star(s)" % [task["title"], int(task["cost"])]
