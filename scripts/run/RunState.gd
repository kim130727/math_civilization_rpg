extends RefCounted
class_name RunState

var archetype: ArchetypeDefinition
var run_map: RunMapDefinition
var deck_cards: Array[CardDefinition] = []
var relics: Array[RelicDefinition] = []
var cleared_nodes: Dictionary = {}
var unlocked_nodes: Dictionary = {}
var current_node_id: String = ""

func begin_run(new_archetype: ArchetypeDefinition, new_map: RunMapDefinition) -> void:
	archetype = new_archetype
	run_map = new_map
	deck_cards.clear()
	relics.clear()
	cleared_nodes.clear()
	unlocked_nodes.clear()
	current_node_id = ""

	for path in archetype.starter_card_paths:
		var card: CardDefinition = load(path)
		if card != null:
			deck_cards.append(card)

	for path in archetype.starter_relic_paths:
		var relic: RelicDefinition = load(path)
		if relic != null:
			relics.append(relic)

	cleared_nodes[run_map.start_node_id] = true
	unlocked_nodes[run_map.start_node_id] = true
	var start_node := get_node(run_map.start_node_id)
	if start_node != null:
		for next_id in start_node.connections:
			unlocked_nodes[next_id] = true

func get_node(node_id: String) -> RunNodeDefinition:
	for node in run_map.nodes:
		if node.node_id == node_id:
			return node
	return null

func get_selectable_nodes() -> Array[RunNodeDefinition]:
	var results: Array[RunNodeDefinition] = []
	for node in run_map.nodes:
		if node.node_type == "start":
			continue
		if bool(unlocked_nodes.get(node.node_id, false)) and not bool(cleared_nodes.get(node.node_id, false)):
			results.append(node)
	return results

func mark_node_cleared(node_id: String) -> void:
	current_node_id = node_id
	cleared_nodes[node_id] = true
	var node := get_node(node_id)
	if node == null:
		return
	for next_id in node.connections:
		unlocked_nodes[next_id] = true

func add_card(card: CardDefinition) -> void:
	if card != null:
		deck_cards.append(card)

func add_relic(relic: RelicDefinition) -> void:
	if relic != null:
		relics.append(relic)

func get_depth() -> int:
	var cleared := 0
	for node_id in cleared_nodes.keys():
		if node_id != run_map.start_node_id and bool(cleared_nodes[node_id]):
			cleared += 1
	return cleared

func is_run_complete() -> bool:
	return get_selectable_nodes().is_empty()
