extends "res://scenes/interactables/InteractArea.gd"

@export var required_item_id: String = "stone"
@export var required_amount: int = 5

var opened: bool = false

func interact(_player: Node) -> void:
	if opened:
		DialogueManager.show_text("문은 이미 열려 있다.")
		return

	if not AbstractionManager.has_concept("addition"):
		DialogueManager.show_text("이 문은 합의 질서를 요구한다.")
		return

	if not InventoryManager.has_item(required_item_id, required_amount):
		DialogueManager.show_text("%s %d개가 필요하다." % [required_item_id, required_amount])
		return

	InventoryManager.remove_item(required_item_id, required_amount)
	opened = true
	DialogueManager.show_text("문이 열렸다. 북쪽 길이 드러난다.")
	hide()
	monitoring = false
	set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)