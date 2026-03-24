extends Resource
class_name CardDefinition

@export var card_id: String = ""
@export var title: String = ""
@export_multiline var description: String = ""
@export var concept: String = "counting"
@export var tags: Array[String] = []
@export var effect_id: String = "add"
@export var target_mode: String = "slot"
@export var energy_cost: int = 1
@export var primary_value: int = 0
@export var secondary_value: int = 0
@export var rarity: String = "starter"
