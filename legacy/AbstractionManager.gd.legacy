extends Node

signal abstraction_changed(new_level: int)
signal concept_unlocked(concept_name: String)

enum AbstractionLevel {
	CHAOS = 0,
	NUMBER = 1,
	ADDITION = 2,
	MULTIPLICATION = 3
}

var current_level: int = AbstractionLevel.CHAOS
var unlocked_concepts: Dictionary = {
	"number_1": false,
	"number_2": false,
	"number_3": false,
	"addition": false,
	"multiplication": false,
}

func unlock_concept(concept_name: String) -> void:
	if not unlocked_concepts.has(concept_name):
		return
	if unlocked_concepts[concept_name]:
		return

	unlocked_concepts[concept_name] = true
	concept_unlocked.emit(concept_name)
	_update_level()

func has_concept(concept_name: String) -> bool:
	return bool(unlocked_concepts.get(concept_name, false))

func get_level_name() -> String:
	match current_level:
		AbstractionLevel.CHAOS:
			return "Chaos"
		AbstractionLevel.NUMBER:
			return "Counting"
		AbstractionLevel.ADDITION:
			return "Addition"
		AbstractionLevel.MULTIPLICATION:
			return "Multiplication"
		_:
			return "Unknown"

func reset() -> void:
	current_level = AbstractionLevel.CHAOS
	for concept_name in unlocked_concepts.keys():
		unlocked_concepts[concept_name] = false
	abstraction_changed.emit(current_level)

func _update_level() -> void:
	var new_level: int = AbstractionLevel.CHAOS

	if unlocked_concepts["multiplication"]:
		new_level = AbstractionLevel.MULTIPLICATION
	elif unlocked_concepts["addition"]:
		new_level = AbstractionLevel.ADDITION
	elif unlocked_concepts["number_1"] or unlocked_concepts["number_2"] or unlocked_concepts["number_3"]:
		new_level = AbstractionLevel.NUMBER

	if new_level == current_level:
		return

	current_level = new_level
	abstraction_changed.emit(current_level)
