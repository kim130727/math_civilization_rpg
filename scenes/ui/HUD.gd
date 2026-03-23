extends CanvasLayer

@onready var stage_label: Label = $MarginContainer/VBoxContainer/StageLabel
@onready var inventory_label: Label = $MarginContainer/VBoxContainer/InventoryLabel
@onready var objective_label: Label = $MarginContainer/VBoxContainer/ObjectiveLabel

func _ready() -> void:
	AbstractionManager.abstraction_changed.connect(_refresh_ui)
	InventoryManager.inventory_changed.connect(_refresh_ui)
	_refresh_ui()

func _refresh_ui(_value = null) -> void:
	stage_label.text = "문명 단계: %s" % AbstractionManager.get_level_name()

	if AbstractionManager.current_level == AbstractionManager.AbstractionLevel.CHAOS:
		inventory_label.text = "소지품: 아직 셀 수 없음"
		objective_label.text = "목표: 순서의 돌을 1 → 2 → 3으로 활성화"
		return

	var item_texts: Array[String] = []
	for item_id in InventoryManager.items.keys():
		item_texts.append("%s x%d" % [item_id, InventoryManager.items[item_id]])
	inventory_label.text = "소지품: %s" % (", ".join(item_texts) if not item_texts.is_empty() else "없음")

	if not AbstractionManager.has_concept("addition"):
		objective_label.text = "목표: 돌 5개를 모아 현자에게 가져가기"
	elif not AbstractionManager.has_concept("multiplication"):
		objective_label.text = "목표: 씨앗 6개를 모아 현자에게 가져가기"
	else:
		objective_label.text = "목표: 북쪽 문을 열고 다음 지역으로 나아가기"
