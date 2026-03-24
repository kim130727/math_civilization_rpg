extends Resource
class_name RunMapDefinition

@export var run_id: String = ""
@export var title: String = ""
@export_multiline var description: String = ""
@export var start_node_id: String = "origin"
@export var nodes: Array[RunNodeDefinition] = []
