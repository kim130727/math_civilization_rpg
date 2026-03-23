extends CharacterBody2D

@export var speed: float = 220.0

var interact_target: Node = null

func _physics_process(_delta: float) -> void:
	var input_vector: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = input_vector * speed
	move_and_slide()
	GameState.player_position = global_position

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and interact_target and interact_target.has_method("interact"):
		interact_target.interact(self)

func set_interact_target(target: Node) -> void:
	interact_target = target