extends Node

signal progress_changed
signal level_completed(level_id: String, earned_stars: int)
signal restoration_completed(task_id: String)
signal chapter_unlocked(chapter_id: String)

const CHAPTERS := [
	{
		"id": "counting",
		"title": "Counting Village",
		"concept_name": "number_1",
		"description": "Count visible groups and collect specific number tiles.",
	},
	{
		"id": "addition",
		"title": "Addition Bridge",
		"concept_name": "addition",
		"description": "Add together matched groups to build a target total.",
	},
]

const COUNTING_LEVELS := [
	{"id": "count_01", "title": "Level 1", "chapter_id": "counting", "rule": "counting", "target_value": 1, "goal_amount": 12, "move_limit": 12, "palette": [1, 2, 3], "hint": "Match the tiles that show one object."},
	{"id": "count_02", "title": "Level 2", "chapter_id": "counting", "rule": "counting", "target_value": 2, "goal_amount": 12, "move_limit": 12, "palette": [1, 2, 3], "hint": "Collect tiles that show two objects."},
	{"id": "count_03", "title": "Level 3", "chapter_id": "counting", "rule": "counting", "target_value": 3, "goal_amount": 12, "move_limit": 13, "palette": [1, 2, 3, 4], "hint": "Three-object groups are the target now."},
	{"id": "count_04", "title": "Level 4", "chapter_id": "counting", "rule": "counting", "target_value": 4, "goal_amount": 12, "move_limit": 13, "palette": [2, 3, 4, 5], "hint": "Look for tiles that show four objects."},
	{"id": "count_05", "title": "Level 5", "chapter_id": "counting", "rule": "counting", "target_value": 5, "goal_amount": 12, "move_limit": 14, "palette": [2, 3, 4, 5], "hint": "Five-object groups are larger, so scan carefully."},
]

const ADDITION_LEVELS := [
	{"id": "add_01", "title": "Level 1", "chapter_id": "addition", "rule": "addition", "goal_amount": 18, "move_limit": 10, "palette": [1, 2, 3], "hint": "Every matched tile adds its value to the bridge total."},
	{"id": "add_02", "title": "Level 2", "chapter_id": "addition", "rule": "addition", "goal_amount": 24, "move_limit": 10, "palette": [1, 2, 3, 4], "hint": "Look for larger groups to build the total faster."},
	{"id": "add_03", "title": "Level 3", "chapter_id": "addition", "rule": "addition", "goal_amount": 32, "move_limit": 11, "palette": [1, 2, 3, 4], "hint": "Chain reactions are a good way to add more at once."},
	{"id": "add_04", "title": "Level 4", "chapter_id": "addition", "rule": "addition", "goal_amount": 40, "move_limit": 11, "palette": [2, 3, 4, 5], "hint": "Higher values matter more now."},
	{"id": "add_05", "title": "Level 5", "chapter_id": "addition", "rule": "addition", "goal_amount": 48, "move_limit": 12, "palette": [2, 3, 4, 5], "hint": "Final bridge test: build the target total efficiently."},
]

const RESTORATION_TASKS := [
	{"id": "count_square", "chapter_id": "counting", "title": "Restore Number Square", "description": "Organize the village plaza so objects can be counted clearly.", "cost": 3},
	{"id": "count_lanterns", "chapter_id": "counting", "title": "Hang Lantern Rows", "description": "Bring pattern and rhythm to the main street.", "cost": 6},
	{"id": "count_market", "chapter_id": "counting", "title": "Open Counting Market", "description": "Every stall now shows neat groups and price tags.", "cost": 9},
	{"id": "add_pillars", "chapter_id": "addition", "title": "Raise Bridge Pillars", "description": "Add stone supports so the bridge can carry grouped weight.", "cost": 4},
	{"id": "add_arch", "chapter_id": "addition", "title": "Complete the Main Arch", "description": "Balanced sums hold the bridge together.", "cost": 8},
	{"id": "add_caravan", "chapter_id": "addition", "title": "Open the Trade Route", "description": "The bridge now supports travelers and supplies.", "cost": 12},
]

var stars_by_level: Dictionary = {}
var completed_restorations: Dictionary = {}
var unlocked_chapters: Dictionary = {
	"counting": true,
	"addition": false,
}

func _ready() -> void:
	_unlock_chapter_concept("counting")

func get_chapter(chapter_id: String) -> Dictionary:
	for chapter in CHAPTERS:
		if chapter["id"] == chapter_id:
			return chapter
	return {}

func get_levels_for_chapter(chapter_id: String) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for level in _all_levels():
		if level["chapter_id"] == chapter_id:
			results.append(level)
	return results

func get_restoration_tasks_for_chapter(chapter_id: String) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for task in RESTORATION_TASKS:
		if task["chapter_id"] == chapter_id:
			results.append(task)
	return results

func get_level(level_id: String) -> Dictionary:
	for level in _all_levels():
		if level["id"] == level_id:
			return level
	return {}

func get_stars_for_level(level_id: String) -> int:
	return int(stars_by_level.get(level_id, 0))

func get_total_stars(chapter_id: String = "") -> int:
	var total := 0
	for level in _all_levels():
		if chapter_id != "" and level["chapter_id"] != chapter_id:
			continue
		total += get_stars_for_level(level["id"])
	return total

func get_spent_stars(chapter_id: String = "") -> int:
	var total := 0
	for task in RESTORATION_TASKS:
		if chapter_id != "" and task["chapter_id"] != chapter_id:
			continue
		if bool(completed_restorations.get(task["id"], false)):
			total += int(task["cost"])
	return total

func get_available_stars(chapter_id: String = "") -> int:
	return get_total_stars(chapter_id) - get_spent_stars(chapter_id)

func get_completed_level_count(chapter_id: String) -> int:
	var count := 0
	for level in get_levels_for_chapter(chapter_id):
		if get_stars_for_level(level["id"]) > 0:
			count += 1
	return count

func complete_level(level_id: String, earned_stars: int) -> bool:
	var level := get_level(level_id)
	if level.is_empty():
		return false

	earned_stars = clampi(earned_stars, 1, 3)
	var previous_stars := get_stars_for_level(level_id)
	if earned_stars <= previous_stars:
		return false

	stars_by_level[level_id] = earned_stars
	level_completed.emit(level_id, earned_stars)
	progress_changed.emit()
	_check_unlocks()
	return true

func is_restoration_completed(task_id: String) -> bool:
	return bool(completed_restorations.get(task_id, false))

func complete_restoration(task_id: String) -> bool:
	if is_restoration_completed(task_id):
		return false

	var task := _find_task(task_id)
	if task.is_empty():
		return false

	var chapter_id: String = task["chapter_id"]
	if get_available_stars(chapter_id) < int(task["cost"]):
		return false

	completed_restorations[task_id] = true
	restoration_completed.emit(task_id)
	progress_changed.emit()
	_check_unlocks()
	return true

func is_chapter_unlocked(chapter_id: String) -> bool:
	return bool(unlocked_chapters.get(chapter_id, false))

func get_restoration_completion_ratio(chapter_id: String) -> float:
	var tasks := get_restoration_tasks_for_chapter(chapter_id)
	if tasks.is_empty():
		return 0.0

	var completed := 0.0
	for task in tasks:
		if is_restoration_completed(task["id"]):
			completed += 1.0
	return completed / float(tasks.size())

func _find_task(task_id: String) -> Dictionary:
	for task in RESTORATION_TASKS:
		if task["id"] == task_id:
			return task
	return {}

func _check_unlocks() -> void:
	var counting_clear := get_completed_level_count("counting") == get_levels_for_chapter("counting").size()
	var restoration_clear := get_restoration_completion_ratio("counting") >= 1.0
	if counting_clear and restoration_clear and not is_chapter_unlocked("addition"):
		unlocked_chapters["addition"] = true
		_unlock_chapter_concept("addition")
		chapter_unlocked.emit("addition")
		progress_changed.emit()

func _unlock_chapter_concept(chapter_id: String) -> void:
	var chapter := get_chapter(chapter_id)
	if chapter.is_empty():
		return
	var concept_name: String = chapter.get("concept_name", "")
	if concept_name != "":
		AbstractionManager.unlock_concept(concept_name)

func _all_levels() -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	results.append_array(COUNTING_LEVELS)
	results.append_array(ADDITION_LEVELS)
	return results
