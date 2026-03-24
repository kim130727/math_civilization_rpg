extends Control

const RUN_MAP_SCENE := preload("res://scenes/run/RunMapView.tscn")
const ENCOUNTER_SCENE := preload("res://scenes/encounter/EncounterView.tscn")
const REWARD_SCENE := preload("res://scenes/reward/RewardView.tscn")

@onready var screen_host: Control = $MarginContainer/ScreenHost

var run_map_view: RunMapView
var encounter_view: EncounterView
var reward_view: RewardView

var reward_generator := RewardGenerator.new()
var run_state := RunState.new()
var active_engine: EncounterEngine
var pending_node_id: String = ""

func _ready() -> void:
	randomize()
	run_map_view = RUN_MAP_SCENE.instantiate()
	encounter_view = ENCOUNTER_SCENE.instantiate()
	reward_view = REWARD_SCENE.instantiate()
	screen_host.add_child(run_map_view)
	screen_host.add_child(encounter_view)
	screen_host.add_child(reward_view)

	run_map_view.node_selected.connect(_on_map_node_selected)
	encounter_view.encounter_back_requested.connect(_return_to_map)
	reward_view.reward_chosen.connect(_on_reward_chosen)

	_start_new_run()

func _start_new_run() -> void:
	var archetype: ArchetypeDefinition = load("res://data/archetypes/field_cartographer.tres")
	var run_map: RunMapDefinition = load("res://data/run/mini_run_map.tres")
	run_state.begin_run(archetype, run_map)
	for concept_id in archetype.starter_concepts:
		MetaProgression.unlock_concept(concept_id)
	for card in run_state.deck_cards:
		MetaProgression.register_card(card.card_id)
	for relic in run_state.relics:
		MetaProgression.register_relic(relic.relic_id)
	run_map_view.render(run_state)
	_show_map()
	DialogueManager.show_text("이 게임은 공격이 아니라 수학적 구조를 다루는 덱빌더입니다.\n\n먼저 슬롯을 선택한 뒤 카드를 사용해 정확한 수를 만들고, 합치고, 반복하고, 배수로 키워 목표 구조를 완성하세요.")

func _on_map_node_selected(node_id: String) -> void:
	var node := run_state.get_node(node_id)
	if node == null or node.encounter_path == "":
		return
	_cleanup_active_engine()
	pending_node_id = node_id
	var encounter_def: EncounterDefinition = load(node.encounter_path)
	active_engine = EncounterEngine.new()
	add_child(active_engine)
	active_engine.setup(encounter_def, run_state)
	active_engine.encounter_won.connect(_on_encounter_won)
	active_engine.encounter_lost.connect(_on_encounter_lost)
	encounter_view.bind_engine(active_engine)
	_show_encounter()
	if node.note != "":
		DialogueManager.show_text(node.note)

func _on_encounter_won(encounter_def: EncounterDefinition) -> void:
	run_state.mark_node_cleared(pending_node_id)
	if encounter_def.concept_unlock != "":
		MetaProgression.unlock_concept(encounter_def.concept_unlock)
	var rewards := reward_generator.build_reward_choices(encounter_def, run_state)
	reward_view.show_rewards(
		"새 추상 개념 선택",
		"승리하면 새로운 개념을 덱에 더할 수 있습니다. 카드나 유물 하나를 고르세요.",
		rewards
	)
	_show_reward()

func _on_encounter_lost(_encounter_def: EncounterDefinition) -> void:
	DialogueManager.show_text("구조가 무너졌습니다.\n\n런은 유지되므로 같은 덱으로 이 노드를 다시 시도할 수 있습니다.")

func _on_reward_chosen(choice: Dictionary) -> void:
	var reward_type := String(choice.get("type", "skip"))
	match reward_type:
		"card":
			var card_resource: Variant = choice.get("resource", null)
			var card: CardDefinition = card_resource as CardDefinition
			run_state.add_card(card)
			if card != null:
				MetaProgression.register_card(card.card_id)
				MetaProgression.unlock_concept(card.concept)
		"relic":
			var relic_resource: Variant = choice.get("resource", null)
			var relic: RelicDefinition = relic_resource as RelicDefinition
			run_state.add_relic(relic)
			if relic != null:
				MetaProgression.register_relic(relic.relic_id)
		_:
			pass

	_cleanup_active_engine()

	run_map_view.render(run_state)
	if run_state.is_run_complete():
		MetaProgression.record_run_completion(run_state.get_depth())
		DialogueManager.show_text("이번 수직 슬라이스는 주조 관문에서 마무리됩니다.\n\n세기는 정확함을, 덧셈은 결합을, 곱셈은 반복과 확장을 익히도록 구성했습니다.")
		_start_new_run()
		return
	_show_map()

func _return_to_map() -> void:
	if active_engine != null and not active_engine.encounter_over:
		DialogueManager.show_text("후퇴하면 이 노드는 아직 해결되지 않은 상태로 남습니다.\n\n덱 구성이 괜찮아졌다고 느껴질 때 다시 돌아오세요.")
	_cleanup_active_engine()
	run_map_view.render(run_state)
	_show_map()

func _show_map() -> void:
	run_map_view.show()
	encounter_view.hide()
	reward_view.hide()

func _show_encounter() -> void:
	run_map_view.hide()
	encounter_view.show()
	reward_view.hide()

func _show_reward() -> void:
	run_map_view.hide()
	encounter_view.hide()
	reward_view.show()

func _cleanup_active_engine() -> void:
	if is_instance_valid(active_engine):
		active_engine.queue_free()
	active_engine = null

