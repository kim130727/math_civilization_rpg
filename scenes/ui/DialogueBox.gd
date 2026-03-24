extends CanvasLayer

@onready var panel: PanelContainer = $MarginContainer/PanelContainer
@onready var label: Label = $MarginContainer/PanelContainer/MarginContainer/Label

func _ready() -> void:
	panel.hide()
	DialogueManager.dialogue_requested.connect(_on_dialogue_requested)

func _on_dialogue_requested(text: String) -> void:
	label.text = text + "\n\nPress Enter to close"
	panel.show()

func hide_dialogue() -> void:
	panel.hide()

func _unhandled_input(event: InputEvent) -> void:
	if not panel.visible:
		return

	if event.is_action_pressed("ui_accept"):
		panel.hide()
	elif event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			panel.hide()
