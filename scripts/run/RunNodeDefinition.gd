extends Resource
class_name RunNodeDefinition

@export var node_id: String = ""
@export var title: String = ""
@export var node_type: String = "encounter"
@export var encounter_path: String = ""
@export var reward_hint: String = ""
@export_multiline var note: String = ""
@export var concept_focus: String = "counting"
@export var graph_position: Vector2 = Vector2.ZERO
@export var connections: Array[String] = []
