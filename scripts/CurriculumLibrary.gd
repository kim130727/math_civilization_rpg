extends RefCounted
class_name CurriculumLibrary

const MANIFEST_PATH := "res://data/curriculum/elementary_curriculum.json"
const TEMPLATE_PATH := "res://data/curriculum/stage_templates.json"

static func load_manifest() -> Dictionary:
	return _load_json_file(MANIFEST_PATH)

static func load_templates() -> Dictionary:
	return _load_json_file(TEMPLATE_PATH)

static func _load_json_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed as Dictionary
