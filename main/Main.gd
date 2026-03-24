extends Control

const MAP_SCREEN_PRESENTER_SCRIPT = preload("res://scripts/ui/MapScreenPresenter.gd")
const PUZZLE_SCREEN_PRESENTER_SCRIPT = preload("res://scripts/ui/PuzzleScreenPresenter.gd")

@onready var map_screen: Control = $MapScreen
@onready var puzzle_screen: Control = $PuzzleScreen
@onready var chapter_label: Label = $MapScreen/MarginContainer/VBoxContainer/HeaderPanel/MarginContainer/HeaderVBox/ChapterLabel
@onready var progress_label: Label = $MapScreen/MarginContainer/VBoxContainer/HeaderPanel/MarginContainer/HeaderVBox/ProgressLabel
@onready var chapter_note_label: Label = $MapScreen/MarginContainer/VBoxContainer/HeaderPanel/MarginContainer/HeaderVBox/ChapterNoteLabel
@onready var chapter_tabs: HBoxContainer = $MapScreen/MarginContainer/VBoxContainer/HeaderPanel/MarginContainer/HeaderVBox/ChapterTabs
@onready var level_grid: GridContainer = $MapScreen/MarginContainer/VBoxContainer/BodyHBox/LevelsPanel/MarginContainer/LevelsVBox/LevelGrid
@onready var level_status_label: Label = $MapScreen/MarginContainer/VBoxContainer/BodyHBox/LevelsPanel/MarginContainer/LevelsVBox/LevelStatusLabel
@onready var restoration_preview_label: Label = $MapScreen/MarginContainer/VBoxContainer/BodyHBox/RestorePanel/MarginContainer/RestoreVBox/PreviewLabel
@onready var restoration_status_label: Label = $MapScreen/MarginContainer/VBoxContainer/BodyHBox/RestorePanel/MarginContainer/RestoreVBox/StatusLabel
@onready var restoration_task_list: VBoxContainer = $MapScreen/MarginContainer/VBoxContainer/BodyHBox/RestorePanel/MarginContainer/RestoreVBox/TaskList
@onready var addition_teaser_label: Label = $MapScreen/MarginContainer/VBoxContainer/FooterPanel/MarginContainer/FooterLabel
@onready var puzzle_title_label: Label = $PuzzleScreen/MarginContainer/VBoxContainer/PuzzleHeader/MarginContainer/HeaderVBox/PuzzleTitle
@onready var puzzle_goal_label: Label = $PuzzleScreen/MarginContainer/VBoxContainer/PuzzleHeader/MarginContainer/HeaderVBox/PuzzleGoal
@onready var puzzle_hint_label: Label = $PuzzleScreen/MarginContainer/VBoxContainer/PuzzleHeader/MarginContainer/HeaderVBox/PuzzleHint
@onready var puzzle_stats_label: Label = $PuzzleScreen/MarginContainer/VBoxContainer/PuzzleHeader/MarginContainer/HeaderVBox/PuzzleStats
@onready var board_mount: Match3BoardController = $PuzzleScreen/MarginContainer/VBoxContainer/PuzzlePanel/MarginContainer/PuzzleGrid
@onready var puzzle_result_label: Label = $PuzzleScreen/MarginContainer/VBoxContainer/PuzzleFooter/ResultLabel
@onready var clear_button: Button = $PuzzleScreen/MarginContainer/VBoxContainer/PuzzleFooter/ButtonRow/ClearButton
@onready var back_button: Button = $PuzzleScreen/MarginContainer/VBoxContainer/PuzzleFooter/ButtonRow/BackButton
@onready var dialogue_box: CanvasLayer = $DialogueBox

var current_chapter_id: String = "counting"
var current_level_id: String = ""
var clear_timer: SceneTreeTimer
var map_presenter: MapScreenPresenter
var puzzle_presenter: PuzzleScreenPresenter

func _ready() -> void:
	map_presenter = MAP_SCREEN_PRESENTER_SCRIPT.new()
	map_presenter.configure({
		"chapter_label": chapter_label,
		"progress_label": progress_label,
		"chapter_note_label": chapter_note_label,
		"chapter_tabs": chapter_tabs,
		"level_grid": level_grid,
		"level_status_label": level_status_label,
		"restoration_preview_label": restoration_preview_label,
		"restoration_status_label": restoration_status_label,
		"restoration_task_list": restoration_task_list,
		"footer_label": addition_teaser_label,
	})
	puzzle_presenter = PUZZLE_SCREEN_PRESENTER_SCRIPT.new()
	puzzle_presenter.configure({
		"title_label": puzzle_title_label,
		"goal_label": puzzle_goal_label,
		"hint_label": puzzle_hint_label,
		"stats_label": puzzle_stats_label,
		"result_label": puzzle_result_label,
		"clear_button": clear_button,
	})

	PuzzleProgress.progress_changed.connect(_refresh_map_screen)
	PuzzleProgress.chapter_unlocked.connect(_on_chapter_unlocked)
	board_mount.header_changed.connect(_on_board_header_changed)
	board_mount.message_changed.connect(_on_board_message_changed)
	board_mount.level_completed.connect(_on_board_level_completed)
	board_mount.out_of_moves.connect(_on_board_out_of_moves)
	clear_button.pressed.connect(_on_clear_button_pressed)
	back_button.pressed.connect(_return_to_map)

	_refresh_map_screen()
	_show_map()
	_show_intro_messages()

func _refresh_map_screen() -> void:
	map_presenter.render(current_chapter_id, _switch_chapter, _open_level, _restore_task)

func _open_level(level_id: String) -> void:
	current_level_id = level_id
	if dialogue_box.has_method("hide_dialogue"):
		dialogue_box.call("hide_dialogue")
	board_mount.play_level(PuzzleProgress.get_level_resource(level_id))
	puzzle_presenter.show_level_started()
	_show_puzzle()

func _on_board_header_changed(title: String, goal_text: String, hint_text: String, stats_text: String) -> void:
	puzzle_presenter.update_header(title, goal_text, hint_text, stats_text)

func _on_board_message_changed(text: String) -> void:
	puzzle_presenter.update_message(text)

func _on_board_level_completed(stars: int) -> void:
	PuzzleProgress.complete_level(current_level_id, stars)
	puzzle_presenter.show_completed()
	_go_to_next_level_after_clear()

func _on_board_out_of_moves() -> void:
	puzzle_presenter.show_retry()

func _on_clear_button_pressed() -> void:
	if clear_timer != null:
		clear_timer = null
	var level: Dictionary = PuzzleProgress.get_level(current_level_id)
	if level.is_empty():
		_return_to_map()
		return
	if PuzzleProgress.get_stars_for_level(current_level_id) > 0 and puzzle_result_label.text.begins_with("Stage clear"):
		_return_to_map()
	else:
		_open_level(current_level_id)

func _go_to_next_level_after_clear() -> void:
	var next_level_id: String = PuzzleProgress.get_next_level_id(current_chapter_id, current_level_id)
	clear_timer = get_tree().create_timer(0.45)
	if next_level_id != "":
		clear_timer.timeout.connect(_open_level.bind(next_level_id), CONNECT_ONE_SHOT)
	else:
		clear_timer.timeout.connect(_return_to_map, CONNECT_ONE_SHOT)

func _return_to_map() -> void:
	_show_map()
	_refresh_map_screen()

func _restore_task(task_id: String) -> void:
	var task: Dictionary = {}
	for item in PuzzleProgress.get_restoration_tasks_for_chapter(current_chapter_id):
		if item["id"] == task_id:
			task = item
			break
	if task.is_empty():
		return

	if PuzzleProgress.complete_restoration(task_id):
		DialogueManager.show_text("%s\n\n%s" % [task["title"], task["description"]])
	else:
		DialogueManager.show_text("You need more stars. Clear more stages first.")

func _switch_chapter(chapter_id: String) -> void:
	if not PuzzleProgress.is_chapter_unlocked(chapter_id):
		return
	current_chapter_id = chapter_id
	_refresh_map_screen()

func _show_map() -> void:
	map_screen.show()
	puzzle_screen.hide()

func _show_puzzle() -> void:
	map_screen.hide()
	puzzle_screen.show()

func _show_intro_messages() -> void:
	DialogueManager.show_text("Welcome to Math Civilization Puzzle.\n\nGrade 1 starts with counting, then grows into visible addition.")

func _on_chapter_unlocked(chapter_id: String) -> void:
	if chapter_id == "addition":
		DialogueManager.show_text("New unit unlocked.\n\nAddition Bridge is now available.")
	elif chapter_id == "multiplication":
		DialogueManager.show_text("New unit unlocked.\n\nMultiplication Workshop is now available.")
	elif chapter_id == "grade3_multiply":
		DialogueManager.show_text("Prototype unlocked.\n\nGrade 3 Harvest Arrays is now available.")
