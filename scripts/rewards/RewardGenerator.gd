extends RefCounted
class_name RewardGenerator

func build_reward_choices(encounter: EncounterDefinition, _run_state: RunState) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	match encounter.reward_type:
		"relic_choice":
			for path in encounter.reward_relic_paths:
				var relic: RelicDefinition = load(path)
				if relic != null:
					results.append({
						"type": "relic",
						"title": relic.title,
						"description": relic.description,
						"resource": relic,
					})
		"card_draft":
			for path in encounter.reward_card_paths:
				var card: CardDefinition = load(path)
				if card != null:
					results.append({
						"type": "card",
						"title": card.title,
						"description": card.description,
						"resource": card,
					})
		"mixed":
			for path in encounter.reward_card_paths:
				var card: CardDefinition = load(path)
				if card != null:
					results.append({
						"type": "card",
						"title": card.title,
						"description": card.description,
						"resource": card,
					})
			for path in encounter.reward_relic_paths:
				var relic: RelicDefinition = load(path)
				if relic != null:
					results.append({
						"type": "relic",
						"title": relic.title,
						"description": relic.description,
						"resource": relic,
					})
		_:
			pass

	results.append({
		"type": "skip",
		"title": "그대로 두기",
		"description": "지금 덱 구성을 유지한 채 다음 노드로 이동합니다.",
		"resource": null,
	})
	return results

