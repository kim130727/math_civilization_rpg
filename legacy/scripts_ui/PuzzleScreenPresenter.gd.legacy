extends RefCounted
class_name PuzzleScreenPresenter

var title_label: Label
var goal_label: Label
var hint_label: Label
var stats_label: Label
var result_label: Label
var clear_button: Button

func configure(refs: Dictionary) -> void:
	title_label = refs["title_label"]
	goal_label = refs["goal_label"]
	hint_label = refs["hint_label"]
	stats_label = refs["stats_label"]
	result_label = refs["result_label"]
	clear_button = refs["clear_button"]

func update_header(title: String, goal_text: String, hint_text: String, stats_text: String) -> void:
	title_label.text = title
	goal_label.text = goal_text
	hint_label.text = hint_text
	stats_label.text = stats_text

func update_message(text: String) -> void:
	result_label.text = text

func show_level_started() -> void:
	clear_button.text = "Restart level"

func show_completed() -> void:
	clear_button.text = "Back to map"

func show_retry() -> void:
	clear_button.text = "Restart level"
