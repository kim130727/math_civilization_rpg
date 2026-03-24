extends Control
class_name RewardView

signal reward_chosen(choice: Dictionary)

@onready var title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var summary_label: Label = $MarginContainer/VBoxContainer/SummaryLabel
@onready var option_row: HBoxContainer = $MarginContainer/VBoxContainer/OptionRow

func show_rewards(title: String, summary: String, choices: Array[Dictionary]) -> void:
	title_label.text = title
	summary_label.text = summary
	for child in option_row.get_children():
		child.queue_free()
	for choice in choices:
		var button := Button.new()
		button.custom_minimum_size = Vector2(220, 180)
		button.text = "%s\n\n%s" % [choice.get("title", ""), choice.get("description", "")]
		button.pressed.connect(func() -> void:
			reward_chosen.emit(choice)
		)
		option_row.add_child(button)
