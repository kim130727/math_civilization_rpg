extends Node

signal progress_changed
signal level_completed(level_id: String, earned_stars: int)
signal restoration_completed(task_id: String)
signal chapter_unlocked(chapter_id: String)

const SAVE_PATH := "user://puzzle_progress.cfg"

const FALLBACK_CHAPTERS := [
	{"id": "counting", "title": "Counting Village", "concept_name": "number_1", "grade_id": "grade1", "unit_id": "g1_counting_intro"},
	{"id": "addition", "title": "Addition Bridge", "concept_name": "addition", "grade_id": "grade1", "unit_id": "g1_addition_intro"},
	{"id": "multiplication", "title": "Multiplication Workshop", "concept_name": "multiplication", "grade_id": "grade1", "unit_id": "g1_multiplication_intro"},
]

const FALLBACK_LEVELS := {
	"count_01": "res://data/levels/grade1_counting_01.tres",
	"count_02": "res://data/levels/grade1_counting_02.tres",
	"count_03": "res://data/levels/grade1_counting_03.tres",
	"count_04": "res://data/levels/grade1_counting_04.tres",
	"count_05": "res://data/levels/grade1_counting_05.tres",
	"count_06": "res://data/levels/grade1_counting_06.tres",
	"count_07": "res://data/levels/grade1_counting_07.tres",
	"count_08": "res://data/levels/grade1_counting_08.tres",
	"count_09": "res://data/levels/grade1_counting_09.tres",
	"count_10": "res://data/levels/grade1_counting_10.tres",
	"add_01": "res://data/levels/grade1_addition_01.tres",
	"add_02": "res://data/levels/grade1_addition_02.tres",
	"add_03": "res://data/levels/grade1_addition_03.tres",
	"add_04": "res://data/levels/grade1_addition_04.tres",
	"add_05": "res://data/levels/grade1_addition_05.tres",
	"add_06": "res://data/levels/grade1_addition_06.tres",
	"add_07": "res://data/levels/grade1_addition_07.tres",
	"add_08": "res://data/levels/grade1_addition_08.tres",
	"add_09": "res://data/levels/grade1_addition_09.tres",
	"add_10": "res://data/levels/grade1_addition_10.tres",
	"mul_01": "res://data/levels/grade1_multiplication_01.tres",
	"mul_02": "res://data/levels/grade1_multiplication_02.tres",
}

const FALLBACK_CHAPTER_LEVEL_IDS := {
	"counting": ["count_01", "count_02", "count_03", "count_04", "count_05", "count_06", "count_07", "count_08", "count_09", "count_10"],
	"addition": ["add_01", "add_02", "add_03", "add_04", "add_05", "add_06", "add_07", "add_08", "add_09", "add_10"],
	"multiplication": ["mul_01", "mul_02"],
}

const FALLBACK_RESTORATION_TASKS := [
	{"id": "count_square", "chapter_id": "counting", "title": "Restore Number Square", "description": "Organize the village plaza so objects can be counted clearly.", "cost": 3},
	{"id": "count_lanterns", "chapter_id": "counting", "title": "Hang Lantern Rows", "description": "Bring pattern and rhythm to the main street.", "cost": 6},
	{"id": "count_market", "chapter_id": "counting", "title": "Open Counting Market", "description": "Every stall now shows neat groups and price tags.", "cost": 9},
	{"id": "add_pillars", "chapter_id": "addition", "title": "Raise Bridge Pillars", "description": "Add stone supports so the bridge can carry grouped weight.", "cost": 4},
	{"id": "add_arch", "chapter_id": "addition", "title": "Complete the Main Arch", "description": "Balanced sums hold the bridge together.", "cost": 8},
	{"id": "add_caravan", "chapter_id": "addition", "title": "Open the Trade Route", "description": "The bridge now supports travelers and supplies.", "cost": 12},
	{"id": "mul_frames", "chapter_id": "multiplication", "title": "Raise Array Frames", "description": "Equal rows of beams turn the yard into a true workshop.", "cost": 5},
	{"id": "mul_crates", "chapter_id": "multiplication", "title": "Stack Repeating Crates", "description": "Supplies line up into repeatable groups.", "cost": 9},
	{"id": "mul_foundry", "chapter_id": "multiplication", "title": "Open the Array Foundry", "description": "The workshop now rebuilds structures through equal groups.", "cost": 13},
]

var CHAPTERS: Array = []
var stars_by_level: Dictionary = {}
var completed_restorations: Dictionary = {}
var unlocked_chapters: Dictionary = {"counting": true}

var _curriculum_manifest: Dictionary = {}
var _chapters_by_id: Dictionary = {}
var _chapter_level_ids: Dictionary = {}
var _level_paths: Dictionary = {}
var _restoration_tasks: Array = []
var _level_cache: Dictionary = {}

func _ready() -> void:
	_load_curriculum_manifest()
	_load_progress()
	_unlock_chapter_concept("counting")

func get_curriculum_manifest() -> Dictionary:
	return _curriculum_manifest

func get_unlock_requirement(chapter_id: String) -> Dictionary:
	var chapter := get_chapter(chapter_id)
	if chapter.is_empty():
		return {}
	return chapter.get("unlock", {})

func get_grade(grade_id: String) -> Dictionary:
	for grade in _curriculum_manifest.get("grades", []):
		if String(grade.get("id", "")) == grade_id:
			return grade
	return {}

func get_chapter(chapter_id: String) -> Dictionary:
	return _chapters_by_id.get(chapter_id, {})

func get_chapter_list() -> Array:
	return CHAPTERS.duplicate()

func get_chapters_for_grade(grade_id: String) -> Array:
	var results: Array = []
	for chapter in CHAPTERS:
		if String(chapter.get("grade_id", "")) == grade_id:
			results.append(chapter)
	return results

func get_levels_for_chapter(chapter_id: String) -> Array:
	var results: Array = []
	for level_id in _chapter_level_ids.get(chapter_id, []):
		var level := get_level(level_id)
		if not level.is_empty():
			results.append(level)
	return results

func get_level(level_id: String) -> Dictionary:
	var resource: Variant = get_level_resource(level_id)
	if resource == null:
		return {}
	return {
		"id": resource.level_id,
		"title": resource.title,
		"chapter_id": resource.chapter_id,
		"unit_id": resource.unit_id,
		"rule_type": resource.rule_type,
		"goal_target_value": resource.goal_target_value,
		"goal_target_amount": resource.goal_target_amount,
		"move_limit": resource.move_limit,
		"grade_id": resource.grade_id,
	}

func is_level_unlocked(chapter_id: String, index: int) -> bool:
	if index <= 0:
		return true
	var levels := get_levels_for_chapter(chapter_id)
	if index >= levels.size():
		return false
	var previous_level_id: String = String(levels[index - 1].get("id", ""))
	return get_stars_for_level(previous_level_id) > 0

func get_next_level_id(chapter_id: String, current_level_id: String) -> String:
	var levels := get_levels_for_chapter(chapter_id)
	for i in range(levels.size()):
		if String(levels[i].get("id", "")) != current_level_id:
			continue
		if i + 1 < levels.size():
			return String(levels[i + 1].get("id", ""))
		break
	return ""

func get_level_resource(level_id: String):
	if _level_cache.has(level_id):
		return _level_cache[level_id]
	if not _level_paths.has(level_id):
		return null
	var resource: Variant = load(String(_level_paths[level_id]))
	_level_cache[level_id] = resource
	return resource

func get_restoration_tasks_for_chapter(chapter_id: String) -> Array:
	var results: Array = []
	for task in _restoration_tasks:
		if String(task.get("chapter_id", "")) == chapter_id:
			results.append(task)
	return results

func get_stars_for_level(level_id: String) -> int:
	return int(stars_by_level.get(level_id, 0))

func get_total_stars(chapter_id: String = "") -> int:
	var total := 0
	for level_id in _level_paths.keys():
		if chapter_id != "":
			var level := get_level(String(level_id))
			if level.is_empty() or String(level.get("chapter_id", "")) != chapter_id:
				continue
		total += get_stars_for_level(String(level_id))
	return total

func get_spent_stars(chapter_id: String = "") -> int:
	var total := 0
	for task in _restoration_tasks:
		if chapter_id != "" and String(task.get("chapter_id", "")) != chapter_id:
			continue
		if bool(completed_restorations.get(String(task.get("id", "")), false)):
			total += int(task.get("cost", 0))
	return total

func get_available_stars(chapter_id: String = "") -> int:
	return get_total_stars(chapter_id) - get_spent_stars(chapter_id)

func get_completed_level_count(chapter_id: String) -> int:
	var count := 0
	for level in get_levels_for_chapter(chapter_id):
		if get_stars_for_level(String(level.get("id", ""))) > 0:
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
	_save_progress()
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
	var chapter_id: String = String(task.get("chapter_id", ""))
	if get_available_stars(chapter_id) < int(task.get("cost", 0)):
		return false
	completed_restorations[task_id] = true
	_save_progress()
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
		if is_restoration_completed(String(task.get("id", ""))):
			completed += 1.0
	return completed / float(tasks.size())

func _find_task(task_id: String) -> Dictionary:
	for task in _restoration_tasks:
		if String(task.get("id", "")) == task_id:
			return task
	return {}

func _check_unlocks() -> void:
	for chapter in CHAPTERS:
		var chapter_id: String = String(chapter.get("id", ""))
		if chapter_id == "" or is_chapter_unlocked(chapter_id):
			continue
		if _meets_unlock_rule(get_unlock_requirement(chapter_id)):
			unlocked_chapters[chapter_id] = true
			_unlock_chapter_concept(chapter_id)
			_save_progress()
			chapter_unlocked.emit(chapter_id)
			progress_changed.emit()

func _meets_unlock_rule(unlock: Dictionary) -> bool:
	var required_chapter_id: String = String(unlock.get("chapter_id", ""))
	if required_chapter_id == "":
		return false
	var require_level_clear: bool = bool(unlock.get("complete_levels", false))
	var require_restoration_clear: bool = bool(unlock.get("complete_restoration", false))
	var level_clear_met: bool = not require_level_clear or get_completed_level_count(required_chapter_id) == get_levels_for_chapter(required_chapter_id).size()
	var restoration_met: bool = not require_restoration_clear or get_restoration_completion_ratio(required_chapter_id) >= 1.0
	return level_clear_met and restoration_met

func _unlock_chapter_concept(chapter_id: String) -> void:
	var chapter := get_chapter(chapter_id)
	if chapter.is_empty():
		return
	var concept_name: String = String(chapter.get("concept_name", ""))
	if concept_name != "":
		AbstractionManager.unlock_concept(concept_name)

func _load_curriculum_manifest() -> void:
	_curriculum_manifest = CurriculumLibrary.load_manifest()
	if _curriculum_manifest.is_empty():
		_load_fallback_data()
		return

	CHAPTERS.clear()
	_chapters_by_id.clear()
	_chapter_level_ids.clear()
	_level_paths.clear()
	_restoration_tasks.clear()

	for grade in _curriculum_manifest.get("grades", []):
		for chapter in grade.get("chapters", []):
			var chapter_record := {
				"id": String(chapter.get("id", "")),
				"title": String(chapter.get("title", "")),
				"grade_id": String(grade.get("id", "")),
				"grade_title": String(grade.get("title", "")),
				"theme": String(chapter.get("theme", "")),
				"concept_name": String(chapter.get("concept_name", "")),
				"unit_id": String(chapter.get("entry_unit_id", "")),
				"unlock": chapter.get("unlock", {}),
			}
			if chapter_record["id"] == "":
				continue
			CHAPTERS.append(chapter_record)
			_chapters_by_id[chapter_record["id"]] = chapter_record
			unlocked_chapters[chapter_record["id"]] = bool(chapter.get("starts_unlocked", false))

			var level_ids: Array = []
			for level in chapter.get("levels", []):
				var level_id := String(level.get("id", ""))
				var path := String(level.get("resource_path", ""))
				if level_id == "" or path == "":
					continue
				level_ids.append(level_id)
				_level_paths[level_id] = path
			_chapter_level_ids[chapter_record["id"]] = level_ids

			for task in chapter.get("restoration_tasks", []):
				_restoration_tasks.append(task)

	if CHAPTERS.is_empty():
		_load_fallback_data()

func _load_fallback_data() -> void:
	CHAPTERS = FALLBACK_CHAPTERS.duplicate(true)
	_chapters_by_id.clear()
	for chapter in CHAPTERS:
		_chapters_by_id[String(chapter.get("id", ""))] = chapter
		unlocked_chapters[String(chapter.get("id", ""))] = String(chapter.get("id", "")) == "counting"
	_chapter_level_ids = FALLBACK_CHAPTER_LEVEL_IDS.duplicate(true)
	_level_paths = FALLBACK_LEVELS.duplicate(true)
	_restoration_tasks = FALLBACK_RESTORATION_TASKS.duplicate(true)

func _save_progress() -> void:
	var save := ConfigFile.new()
	save.set_value("progress", "stars_by_level", stars_by_level)
	save.set_value("progress", "completed_restorations", completed_restorations)
	save.set_value("progress", "unlocked_chapters", unlocked_chapters)
	save.save(SAVE_PATH)

func _load_progress() -> void:
	var save := ConfigFile.new()
	var result := save.load(SAVE_PATH)
	if result != OK:
		return
	stars_by_level = save.get_value("progress", "stars_by_level", {})
	completed_restorations = save.get_value("progress", "completed_restorations", {})
	var saved_unlocks = save.get_value("progress", "unlocked_chapters", {})
	if saved_unlocks is Dictionary:
		for chapter_id in saved_unlocks.keys():
			unlocked_chapters[String(chapter_id)] = bool(saved_unlocks[chapter_id])
	unlocked_chapters["counting"] = true
