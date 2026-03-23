extends Node

signal inventory_changed

var items: Dictionary = {}

func add_item(item_id: String, amount: int = 1) -> void:
	if not AbstractionManager.has_concept("number_1"):
		return

	var current_amount: int = int(items.get(item_id, 0))
	items[item_id] = current_amount + amount
	inventory_changed.emit()

func remove_item(item_id: String, amount: int = 1) -> bool:
	var current: int = int(items.get(item_id, 0))
	if current < amount:
		return false

	current -= amount
	if current <= 0:
		items.erase(item_id)
	else:
		items[item_id] = current

	inventory_changed.emit()
	return true

func get_amount(item_id: String) -> int:
	return int(items.get(item_id, 0))

func has_item(item_id: String, amount: int = 1) -> bool:
	return get_amount(item_id) >= amount