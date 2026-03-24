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
		"description": "Match tiles that show groups of counted objects.",
	},
	{
		"id": "addition",
		"title": "Addition Bridge",
		"concept_name": "addition",
		"description": "Combine groups to make the required total.",
	},
]

const COUNTING_LEVELS := [
	{"id": "count_01", "title": "Level 1", "chapter_id": "counting", "goal_value": 1, "goal_count": 12, "move_limit": 12, "palette": [1, 2, 3], "hint": "Match the tiles that show one object."},
	{"id": "count_02", "title": "Level 2", "chapter_id": "counting", "goal_value": 2, "goal_count": 12, "move_limit": 12, "palette": [1, 2, 3], "hint": "Collect tiles that show two objects."},
	{"id": "count_03", "title": "Level 3", "chapter_id": "counting", "goal_value": 3, "goal_count": 12, "move_limit": 13, "palette": [1, 2, 3, 4], "hint": "Three-object groups are the target now."},
	{"id": "count_04", "title": "Level 4", "chapter_id": "counting", "goal_value": 4, "goal_count": 12, "move_limit": 13, "palette": [2, 3, 4, 5], "hint": "Look for tiles that show four objects."},
	{"id": "count_05", "title": "Level 5", "chapter_id": "counting", "goal_value": 5, "goal_count": 12, "move_limit": 14, "palette": [2, 3, 4, 5], "hint": "Five-object groups are larger, so scan carefully."},
	{"id": "count_06", "title": "Level 6", "chapter_id": "counting", "goal_value": 2, "goal_count": 15, "move_limit": 14, "palette": [1, 2, 3, 4, 5], "hint": "Collect more 2s before the move limit runs out."},
	{"id": "count_07", "title": "Level 7", "chapter_id": "counting", "goal_value": 3, "goal_count": 15, "move_limit": 14, "palette": [1, 2, 3, 4, 5], "hint": "Set up chain reactions with 3s."},
	{"id": "count_08", "title": "Level 8", "chapter_id": "counting", "goal_value": 4, "goal_count": 15, "move_limit": 15, "palette": [2, 3, 4, 5, 6], "hint": "Four-object groups now share the board with larger sets."},
	{"id": "count_09", "title": "Level 9", "chapter_id": "counting", "goal_value": 5, "goal_count": 15, "move_limit": 15, "palette": [2, 3, 4, 5, 6], "hint": "Build matches that feed more 5s onto the board."},
	{"id": "count_10", "title": "Level 10", "chapter_id": "counting", "goal_value": 6, "goal_count": 18, "move_limit": 16, "palette": [3, 4, 5, 6], "hint": "Final village test: count the biggest groups with confidence."},
]

const RESTORATION_TASKS := [
	{"id": "count_square", "chapter_id": "counting", "title": "Restore Number Square", "description": "Organize the village plaza so objects can be counted clearly.", "cost": 3},
	{"id": "count_lanterns", "chapter_id": "counting", "title": "Hang Lantern Rows", "description": "Bring pattern and rhythm to the main street.", "cost": 6},
	{"id": "count_market", "chapter_id": "counting", "title": "Open Counting Market", "description": "Every stall now shows neat groups and price tags.", "cost": 9},
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
	for level in COUNTING_LEVELS:
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
	for level in COUNTING_LEVELS:
		if level["id"] == level_id:
			return level
	return {}

func get_stars_for_level(level_id: String) -> int:
	return int(stars_by_level.get(level_id, 0))

func get_total_stars(chapter_id: String = "") -> int:
	var total := 0
	for level in COUNTING_LEVELS:
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
