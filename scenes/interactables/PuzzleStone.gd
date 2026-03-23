extends "res://scenes/interactables/InteractArea.gd"

@export var order_number: int = 1

static var current_sequence: int = 1

func interact(_player: Node) -> void:
	if order_number != current_sequence:
		DialogueManager.show_text("질서가 무너졌다. 다시 처음부터 세어야 한다.")
		current_sequence = 1
		return

	DialogueManager.show_text("%d" % order_number)
	current_sequence += 1

	if current_sequence > 3:
		AbstractionManager.unlock_concept("number_1")
		AbstractionManager.unlock_concept("number_2")
		AbstractionManager.unlock_concept("number_3")
		DialogueManager.show_text("수의 질서가 태어났다.")
		GameState.set_flag("numbers_unlocked")
		current_sequence = 1
