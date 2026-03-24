extends Resource
class_name ArchetypeDefinition

@export var archetype_id: String = ""
@export var title: String = ""
@export_multiline var description: String = ""
@export_multiline var fantasy_text: String = ""
@export var starter_card_paths: Array[String] = []
@export var starter_relic_paths: Array[String] = []
@export var starter_concepts: Array[String] = ["counting"]
