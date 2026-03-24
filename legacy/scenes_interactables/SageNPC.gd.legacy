extends "res://scenes/interactables/InteractArea.gd"

func interact(_player: Node) -> void:
	if not GameState.has_flag("numbers_unlocked"):
		DialogueManager.show_text("하나, 둘, 셋을 구분할 수 있을 때 세계는 비로소 세어진다.")
		return

	if not AbstractionManager.has_concept("addition"):
		if InventoryManager.has_item("stone", 5):
			AbstractionManager.unlock_concept("addition")
			DialogueManager.show_text("합쳐짐은 새로운 질서다. 이제 문은 다섯의 합을 이해한다.")
			return
		DialogueManager.show_text("둘과 셋을 모아 다섯을 만들 수 있음을 보여다오. 돌 5개를 모아 오너라.")
		return

	if not AbstractionManager.has_concept("multiplication"):
		if InventoryManager.has_item("seed", 6):
			AbstractionManager.unlock_concept("multiplication")
			DialogueManager.show_text("반복은 생산이 되고, 생산은 문명이 된다. 곱셈의 시대가 열린다.")
			return
		DialogueManager.show_text("같은 리듬을 되풀이해 보아라. 씨앗 6개를 모으면 반복의 질서를 가르쳐 주겠다.")
		return

	DialogueManager.show_text("너는 이미 혼돈 너머의 질서를 배웠다.")
