extends Node

signal progression_changed
signal concept_unlocked(concept_id: String)

const SAVE_PATH := "user://meta_progression.cfg"

var unlocked_concepts: Dictionary = {
	"counting": true,
	"addition": false,
	"multiplication": false,
}
var discovered_cards: Dictionary = {}
var discovered_relics: Dictionary = {}
var completed_runs: int = 0
var best_depth: int = 0

func _ready() -> void:
	_load_progress()

func is_concept_unlocked(concept_id: String) -> bool:
	return bool(unlocked_concepts.get(concept_id, false))

func unlock_concept(concept_id: String) -> void:
	if is_concept_unlocked(concept_id):
		return
	unlocked_concepts[concept_id] = true
	_save_progress()
	concept_unlocked.emit(concept_id)
	progression_changed.emit()

func register_card(card_id: String) -> void:
	if card_id == "":
		return
	if discovered_cards.has(card_id):
		return
	discovered_cards[card_id] = true
	_save_progress()
	progression_changed.emit()

func register_relic(relic_id: String) -> void:
	if relic_id == "":
		return
	if discovered_relics.has(relic_id):
		return
	discovered_relics[relic_id] = true
	_save_progress()
	progression_changed.emit()

func record_run_completion(depth: int) -> void:
	completed_runs += 1
	best_depth = max(best_depth, depth)
	_save_progress()
	progression_changed.emit()

func _save_progress() -> void:
	var save := ConfigFile.new()
	save.set_value("meta", "unlocked_concepts", unlocked_concepts)
	save.set_value("meta", "discovered_cards", discovered_cards)
	save.set_value("meta", "discovered_relics", discovered_relics)
	save.set_value("meta", "completed_runs", completed_runs)
	save.set_value("meta", "best_depth", best_depth)
	save.save(SAVE_PATH)

func _load_progress() -> void:
	var save := ConfigFile.new()
	if save.load(SAVE_PATH) != OK:
		return
	var saved_concepts: Variant = save.get_value("meta", "unlocked_concepts", {})
	if saved_concepts is Dictionary:
		for key in saved_concepts.keys():
			unlocked_concepts[String(key)] = bool(saved_concepts[key])
	unlocked_concepts["counting"] = true
	discovered_cards = save.get_value("meta", "discovered_cards", {})
	discovered_relics = save.get_value("meta", "discovered_relics", {})
	completed_runs = int(save.get_value("meta", "completed_runs", 0))
	best_depth = int(save.get_value("meta", "best_depth", 0))
