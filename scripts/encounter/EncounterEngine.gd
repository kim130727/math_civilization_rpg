extends Node
class_name EncounterEngine

signal state_changed(state: Dictionary)
signal log_changed(text: String)
signal encounter_won(definition: EncounterDefinition)
signal encounter_lost(definition: EncounterDefinition)

var definition: EncounterDefinition
var deck_manager := DeckManager.new()
var run_state: RunState
var slots: Array[int] = []
var guards: Array[bool] = []
var turns_remaining: int = 0
var plays_remaining: int = 0
var encounter_over: bool = false

func setup(new_definition: EncounterDefinition, new_run_state: RunState) -> void:
	definition = new_definition
	run_state = new_run_state
	slots = []
	guards = []
	for i in range(definition.slot_count):
		var value := 0
		if i < definition.starting_values.size():
			value = int(definition.starting_values[i])
		slots.append(value)
		guards.append(false)

	turns_remaining = definition.turn_limit
	plays_remaining = definition.plays_per_turn
	encounter_over = false
	deck_manager.setup(run_state.deck_cards)
	_apply_relics("encounter_start")
	_draw_new_hand()
	log_changed.emit(definition.flavor_text)
	_emit_state()

func get_state() -> Dictionary:
	return {
		"title": definition.title,
		"objective_text": _build_objective_summary(),
		"flavor_text": definition.flavor_text,
		"slots": slots.duplicate(),
		"guards": guards.duplicate(),
		"turns_remaining": turns_remaining,
		"plays_remaining": plays_remaining,
		"hand": deck_manager.get_hand(),
		"draw_count": deck_manager.get_draw_count(),
		"discard_count": deck_manager.get_discard_count(),
		"encounter_over": encounter_over,
	}

func play_card(hand_index: int, target_slot: int = -1) -> void:
	if encounter_over:
		return
	if plays_remaining <= 0:
		log_changed.emit("이번 턴에는 더 이상 카드를 사용할 수 없습니다. 턴 종료로 구조를 정리하세요.")
		return

	var card := deck_manager.get_card_in_hand(hand_index)
	if card == null:
		return
	if card.target_mode == "slot" and (target_slot < 0 or target_slot >= slots.size()):
		log_changed.emit("%s 카드를 쓰기 전에 슬롯을 먼저 선택하세요." % card.title)
		return

	var summary := _apply_card_effect(card, target_slot)
	deck_manager.consume_hand_card(hand_index)
	plays_remaining -= card.energy_cost
	log_changed.emit(summary)
	if _check_victory():
		return
	_emit_state()

func end_turn() -> void:
	if encounter_over:
		return
	_apply_entropy()
	if _check_victory():
		return
	turns_remaining -= 1
	if turns_remaining <= 0:
		_trigger_loss("패턴이 안정되기 전에 무너졌습니다.")
		return
	for i in range(guards.size()):
		guards[i] = false
	plays_remaining = definition.plays_per_turn
	deck_manager.discard_hand()
	_apply_relics("turn_start")
	_draw_new_hand()
	log_changed.emit("엔트로피가 구조를 흔들었습니다. 새 손패를 뽑습니다.")
	_emit_state()

func _draw_new_hand() -> void:
	deck_manager.draw_cards(definition.hand_size)

func _apply_card_effect(card: CardDefinition, target_slot: int) -> String:
	match card.effect_id:
		"add":
			slots[target_slot] += card.primary_value
			return "%s: 슬롯 %d에 %d 추가." % [card.title, target_slot + 1, card.primary_value]
		"multiply":
			slots[target_slot] *= card.primary_value
			return "%s: 슬롯 %d을(를) x%d배로 확장." % [card.title, target_slot + 1, card.primary_value]
		"copy_to_empty":
			var empty_slot := _find_first_empty_slot(target_slot)
			if empty_slot == -1 or slots[target_slot] == 0:
				return "%s: 복제할 빈 슬롯이 없습니다." % card.title
			slots[empty_slot] = slots[target_slot]
			return "%s: 슬롯 %d의 값을 슬롯 %d에 복제." % [card.title, target_slot + 1, empty_slot + 1]
		"merge_all_into_target":
			var total := 0
			for i in range(slots.size()):
				if i == target_slot:
					continue
				total += slots[i]
				slots[i] = 0
			slots[target_slot] += total
			return "%s: 다른 값을 모두 슬롯 %d로 모읍니다." % [card.title, target_slot + 1]
		"add_to_all_filled":
			var touched := 0
			for i in range(slots.size()):
				if slots[i] > 0:
					slots[i] += card.primary_value
					touched += 1
			return "%s: 활성 슬롯 %d곳을 키웁니다." % [card.title, touched]
		"add_to_lowest":
			var targets := _find_lowest_slots(max(card.secondary_value, 1))
			for slot_index in targets:
				slots[slot_index] += card.primary_value
			return "%s: 가장 작은 그룹을 보강합니다." % card.title
		"fill_to":
			if slots[target_slot] < card.primary_value:
				slots[target_slot] = card.primary_value
			return "%s: 슬롯 %d을(를) 최소 %d까지 채웁니다." % [card.title, target_slot + 1, card.primary_value]
		"guard":
			guards[target_slot] = true
			return "%s: 슬롯 %d을(를) 다음 붕괴에서 보호합니다." % [card.title, target_slot + 1]
		"multiply_all_equal":
			if _all_filled_slots_equal():
				for i in range(slots.size()):
					if slots[i] > 0:
						slots[i] *= card.primary_value
				return "%s: 같은 그룹 전체를 함께 확장합니다." % card.title
			return "%s: 0이 아닌 같은 값의 그룹이 먼저 필요합니다." % card.title
		"broadcast_value":
			if slots[target_slot] == 0:
				return "%s: 반복할 기준이 되는 0이 아닌 슬롯이 필요합니다." % card.title
			for i in range(slots.size()):
				if i == target_slot or slots[i] == 0:
					continue
				slots[i] += slots[target_slot]
			return "%s: 슬롯 %d의 값을 다른 활성 구조에 반복합니다." % [card.title, target_slot + 1]
		"add_per_filled":
			var filled := _count_filled_slots()
			slots[target_slot] += filled * card.primary_value
			return "%s: 활성 그룹 수만큼 슬롯 %d을(를) 키웁니다." % [card.title, target_slot + 1]
		_:
			return "%s: 아직 구현되지 않은 효과입니다." % card.title

func _apply_entropy() -> void:
	match definition.entropy_pattern:
		"none":
			return
		"decay_highest":
			var index := _find_highest_unguarded_slot()
			if index >= 0:
				slots[index] = max(0, slots[index] - definition.entropy_value)
		"decay_all_unprotected":
			for i in range(slots.size()):
				if guards[i]:
					continue
				slots[i] = max(0, slots[i] - definition.entropy_value)
		_:
			# TODO: Add richer entropy patterns such as splitting, corruption, and row drift.
			pass

func _apply_relics(trigger: String) -> void:
	for relic in run_state.relics:
		if relic.trigger != trigger:
			continue
		match relic.effect_id:
			"add_leftmost":
				if not slots.is_empty():
					slots[0] += relic.primary_value
			"guard_leftmost":
				if not guards.is_empty():
					guards[0] = true
			"draw_bonus":
				deck_manager.draw_cards(relic.primary_value)
			_:
				# TODO: Add more relic hooks once encounters start using timing-sensitive mechanics.
				pass

func _check_victory() -> bool:
	if not _objective_is_met():
		return false
	encounter_over = true
	log_changed.emit("구조가 안정적으로 고정되었습니다.")
	encounter_won.emit(definition)
	_emit_state()
	return true

func _objective_is_met() -> bool:
	match definition.objective_type:
		"exact_targets":
			if definition.objective_target_values.size() != slots.size():
				return false
			for i in range(slots.size()):
				if slots[i] != int(definition.objective_target_values[i]):
					return false
			return true
		"reach_total":
			var total := 0
			for value in slots:
				total += value
			return total >= definition.objective_target_total
		"equal_groups":
			for value in slots:
				if value != definition.objective_target_total:
					return false
			return true
		_:
			return false

func _trigger_loss(reason: String) -> void:
	encounter_over = true
	log_changed.emit(reason)
	encounter_lost.emit(definition)
	_emit_state()

func _build_objective_summary() -> String:
	match definition.objective_type:
		"exact_targets":
			return "목표 구조 %s을(를) 정확히 만드세요." % str(definition.objective_target_values)
		"reach_total":
			return "활성 슬롯 전체 합을 %d 이상으로 만드세요." % definition.objective_target_total
		"equal_groups":
			return "모든 슬롯을 %d의 같은 그룹으로 만드세요." % definition.objective_target_total
		_:
			return definition.objective_text

func _emit_state() -> void:
	state_changed.emit(get_state())

func _find_first_empty_slot(excluded_slot: int) -> int:
	for i in range(slots.size()):
		if i == excluded_slot:
			continue
		if slots[i] == 0:
			return i
	return -1

func _find_lowest_slots(count: int) -> Array[int]:
	var indexed: Array[Dictionary] = []
	for i in range(slots.size()):
		indexed.append({"index": i, "value": slots[i]})
	indexed.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["value"]) == int(b["value"]):
			return int(a["index"]) < int(b["index"])
		return int(a["value"]) < int(b["value"])
	)
	var results: Array[int] = []
	for item in indexed:
		results.append(int(item["index"]))
		if results.size() >= count:
			break
	return results

func _find_highest_unguarded_slot() -> int:
	var best_index := -1
	var best_value := -1
	for i in range(slots.size()):
		if guards[i]:
			continue
		if slots[i] > best_value:
			best_value = slots[i]
			best_index = i
	return best_index

func _all_filled_slots_equal() -> bool:
	var reference := -1
	for value in slots:
		if value <= 0:
			continue
		if reference == -1:
			reference = value
			continue
		if value != reference:
			return false
	return reference != -1

func _count_filled_slots() -> int:
	var count := 0
	for value in slots:
		if value > 0:
			count += 1
	return count

