extends Resource
class_name RelicDefinition

@export var relic_id: String = ""
@export var title: String = ""
@export_multiline var description: String = ""
@export var trigger: String = "encounter_start"
@export var effect_id: String = "add_leftmost"
@export var primary_value: int = 1
