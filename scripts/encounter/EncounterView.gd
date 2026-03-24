extends Control
class_name EncounterView

signal encounter_back_requested

@onready var title_label: Label = $MarginContainer/VBoxContainer/HeaderPanel/MarginContainer/HeaderVBox/TitleLabel
@onready var objective_label: Label = $MarginContainer/VBoxContainer/HeaderPanel/MarginContainer/HeaderVBox/ObjectiveLabel
@onready var turn_label: Label = $MarginContainer/VBoxContainer/HeaderPanel/MarginContainer/HeaderVBox/TurnLabel
@onready var log_label: Label = $MarginContainer/VBoxContainer/HeaderPanel/MarginContainer/HeaderVBox/LogLabel
@onready var slot_row: HBoxContainer = $MarginContainer/VBoxContainer/BodyHBox/SlotsPanel/MarginContainer/SlotsVBox/SlotRow
@onready var deck_label: Label = $MarginContainer/VBoxContainer/BodyHBox/HandPanel/MarginContainer/HandVBox/DeckLabel
@onready var hand_list: VBoxContainer = $MarginContainer/VBoxContainer/BodyHBox/HandPanel/MarginContainer/HandVBox/HandList
@onready var end_turn_button: Button = $MarginContainer/VBoxContainer/FooterRow/EndTurnButton
@onready var retreat_button: Button = $MarginContainer/VBoxContainer/FooterRow/RetreatButton

var engine: EncounterEngine
var selected_slot: int = -1

func _ready() -> void:
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	retreat_button.pressed.connect(func() -> void:
		encounter_back_requested.emit()
	)

func bind_engine(new_engine: EncounterEngine) -> void:
	if engine != null:
		if engine.state_changed.is_connected(_refresh_from_state):
			engine.state_changed.disconnect(_refresh_from_state)
		if engine.log_changed.is_connected(_on_log_changed):
			engine.log_changed.disconnect(_on_log_changed)
	engine = new_engine
	engine.state_changed.connect(_refresh_from_state)
	engine.log_changed.connect(_on_log_changed)
	_refresh_from_state(engine.get_state())

func _refresh_from_state(state: Dictionary) -> void:
	title_label.text = state.get("title", "")
	objective_label.text = state.get("objective_text", "")
	turn_label.text = "턴 %d   사용 %d   드로우 %d   버림 %d" % [
		int(state.get("turns_remaining", 0)),
		int(state.get("plays_remaining", 0)),
		int(state.get("draw_count", 0)),
		int(state.get("discard_count", 0)),
	]
	deck_label.text = "먼저 슬롯을 누른 뒤 카드를 사용하세요. 세기는 정확한 수를 맞추고, 덧셈은 모으고, 곱셈은 반복과 확장을 만듭니다."
	_render_slots(state.get("slots", []), state.get("guards", []))
	_render_hand(state.get("hand", []), int(state.get("plays_remaining", 0)), bool(state.get("encounter_over", false)))

func _render_slots(slot_values: Array, guards: Array) -> void:
	for child in slot_row.get_children():
		child.queue_free()
	for i in range(slot_values.size()):
		var button := Button.new()
		var guard_text := "보호" if i < guards.size() and bool(guards[i]) else "노출"
		button.text = "슬롯 %d\n%d\n%s" % [i + 1, int(slot_values[i]), guard_text]
		button.custom_minimum_size = Vector2(120, 120)
		if i == selected_slot:
			button.modulate = Color(1.0, 0.95, 0.7)
		button.pressed.connect(_on_slot_pressed.bind(i))
		slot_row.add_child(button)

func _render_hand(cards: Array, plays_remaining: int, encounter_over: bool) -> void:
	for child in hand_list.get_children():
		child.queue_free()
	for i in range(cards.size()):
		var card: CardDefinition = cards[i]
		var button := Button.new()
		button.text = "%s\n%s\n비용 %d" % [card.title, card.description, card.energy_cost]
		button.custom_minimum_size = Vector2(0, 74)
		button.disabled = encounter_over or plays_remaining < card.energy_cost
		button.pressed.connect(_on_card_pressed.bind(i))
		hand_list.add_child(button)

func _on_slot_pressed(slot_index: int) -> void:
	selected_slot = slot_index
	if engine != null:
		_refresh_from_state(engine.get_state())

func _on_card_pressed(hand_index: int) -> void:
	if engine == null:
		return
	engine.play_card(hand_index, selected_slot)

func _on_end_turn_pressed() -> void:
	if engine != null:
		selected_slot = -1
		engine.end_turn()

func _on_log_changed(text: String) -> void:
	log_label.text = text

