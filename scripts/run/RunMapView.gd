extends Control
class_name RunMapView

signal node_selected(node_id: String)

@onready var run_title_label: Label = $MarginContainer/VBoxContainer/HeaderPanel/MarginContainer/HeaderVBox/RunTitleLabel
@onready var run_summary_label: Label = $MarginContainer/VBoxContainer/HeaderPanel/MarginContainer/HeaderVBox/RunSummaryLabel
@onready var deck_summary_label: Label = $MarginContainer/VBoxContainer/InfoPanel/MarginContainer/InfoVBox/DeckSummaryLabel
@onready var relic_summary_label: Label = $MarginContainer/VBoxContainer/InfoPanel/MarginContainer/InfoVBox/RelicSummaryLabel
@onready var node_canvas: Control = $MarginContainer/VBoxContainer/MapPanel/MarginContainer/NodeCanvas
@onready var node_note_label: Label = $MarginContainer/VBoxContainer/InfoPanel/MarginContainer/InfoVBox/NodeNoteLabel

var run_state: RunState

func render(new_run_state: RunState) -> void:
	run_state = new_run_state
	run_title_label.text = "%s: %s" % [run_state.archetype.title, run_state.run_map.title]
	run_summary_label.text = run_state.run_map.description
	deck_summary_label.text = "덱 %d장: %s" % [run_state.deck_cards.size(), _build_card_summary()]
	relic_summary_label.text = "유물: %s" % _build_relic_summary()
	node_note_label.text = "다음 추상 노드를 선택하세요."
	_render_nodes()

func _render_nodes() -> void:
	for child in node_canvas.get_children():
		child.queue_free()

	for node in run_state.run_map.nodes:
		var button := Button.new()
		button.text = node.title
		button.custom_minimum_size = Vector2(170, 54)
		button.position = node.graph_position
		button.disabled = not _is_node_selectable(node)
		if bool(run_state.cleared_nodes.get(node.node_id, false)):
			button.text = "%s\n완료" % node.title
		button.pressed.connect(_on_node_pressed.bind(node.node_id))
		node_canvas.add_child(button)

func _on_node_pressed(node_id: String) -> void:
	var node := run_state.get_node(node_id)
	if node == null:
		return
	node_note_label.text = "%s\n%s\n보상: %s" % [node.title, node.note, node.reward_hint]
	node_selected.emit(node_id)

func _is_node_selectable(node: RunNodeDefinition) -> bool:
	if node.node_type == "start":
		return false
	if bool(run_state.cleared_nodes.get(node.node_id, false)):
		return false
	return bool(run_state.unlocked_nodes.get(node.node_id, false))

func _build_card_summary() -> String:
	var counts: Dictionary = {}
	for card in run_state.deck_cards:
		counts[card.title] = int(counts.get(card.title, 0)) + 1
	var parts: Array[String] = []
	for title in counts.keys():
		parts.append("%s x%d" % [title, counts[title]])
	return ", ".join(parts)

func _build_relic_summary() -> String:
	if run_state.relics.is_empty():
		return "없음"
	var titles: Array[String] = []
	for relic in run_state.relics:
		titles.append(relic.title)
	return ", ".join(titles)

