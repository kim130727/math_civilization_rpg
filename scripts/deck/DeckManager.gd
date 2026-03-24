extends RefCounted
class_name DeckManager

var draw_pile: Array[CardDefinition] = []
var hand: Array[CardDefinition] = []
var discard_pile: Array[CardDefinition] = []

func setup(cards: Array[CardDefinition]) -> void:
	draw_pile = cards.duplicate()
	hand.clear()
	discard_pile.clear()
	_shuffle(draw_pile)

func draw_cards(count: int) -> Array[CardDefinition]:
	var drawn: Array[CardDefinition] = []
	for _i in range(count):
		if draw_pile.is_empty():
			if discard_pile.is_empty():
				break
			draw_pile = discard_pile.duplicate()
			discard_pile.clear()
			_shuffle(draw_pile)
		var card: CardDefinition = draw_pile.pop_back() as CardDefinition
		hand.append(card)
		drawn.append(card)
	return drawn

func get_hand() -> Array[CardDefinition]:
	return hand.duplicate()

func get_card_in_hand(index: int) -> CardDefinition:
	if index < 0 or index >= hand.size():
		return null
	return hand[index]

func consume_hand_card(index: int) -> CardDefinition:
	if index < 0 or index >= hand.size():
		return null
	var card: CardDefinition = hand[index]
	hand.remove_at(index)
	discard_pile.append(card)
	return card

func discard_hand() -> void:
	while not hand.is_empty():
		discard_pile.append(hand.pop_back())

func get_draw_count() -> int:
	return draw_pile.size()

func get_discard_count() -> int:
	return discard_pile.size()

func _shuffle(cards: Array) -> void:
	for i in range(cards.size() - 1, 0, -1):
		var swap_index := randi_range(0, i)
		var temp = cards[i]
		cards[i] = cards[swap_index]
		cards[swap_index] = temp
