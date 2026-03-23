extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if body.has_method("set_interact_target"):
		body.set_interact_target(self)

func _on_body_exited(body: Node) -> void:
	if body.has_method("set_interact_target"):
		body.set_interact_target(null)
