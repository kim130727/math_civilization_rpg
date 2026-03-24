extends Resource
class_name EncounterDefinition

@export var encounter_id: String = ""
@export var title: String = ""
@export_multiline var objective_text: String = ""
@export_multiline var flavor_text: String = ""
@export var concept_focus: String = "counting"
@export var concept_unlock: String = ""
@export var slot_count: int = 3
@export var starting_values: Array[int] = []
@export var objective_type: String = "exact_targets"
@export var objective_target_values: Array[int] = []
@export var objective_target_total: int = 0
@export var turn_limit: int = 4
@export var plays_per_turn: int = 3
@export var hand_size: int = 5
@export var entropy_pattern: String = "none"
@export var entropy_value: int = 1
@export var reward_type: String = "card_draft"
@export var reward_card_paths: Array[String] = []
@export var reward_relic_paths: Array[String] = []
