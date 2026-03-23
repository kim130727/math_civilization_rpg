extends "res://scenes/interactables/InteractArea.gd"

@export var item_id: String = "stone"
@export var quantity: int = 1
@export var display_name: String = "돌"

var collected: bool = false

func interact(_player: Node) -> void:
	if collected:
		return

	if not AbstractionManager.has_concept("number_1"):
		DialogueManager.show_text("아직은 셀 수 없는 덩어리처럼 보인다.")
		return

	InventoryManager.add_item(item_id, quantity)
	collected = true
	DialogueManager.show_text("%s %d개를 얻었다." % [display_name, quantity])
	queue_free()