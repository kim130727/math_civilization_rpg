extends CanvasLayer

@onready var panel: PanelContainer = $MarginContainer/PanelContainer
@onready var label: Label = $MarginContainer/PanelContainer/MarginContainer/Label

func _ready() -> void:
	panel.hide()
	DialogueManager.dialogue_requested.connect(_on_dialogue_requested)

func _on_dialogue_requested(text: String) -> void:
	label.text = text + "\n\n[Enter]로 닫기"
	panel.show()

func _unhandled_input(event: InputEvent) -> void:
	if panel.visible and event.is_action_pressed("ui_accept"):
		panel.hide()
