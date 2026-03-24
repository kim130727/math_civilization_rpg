extends RefCounted
class_name ChapterRuleLibrary

static func get_goal_label(level_data: MathLevelData) -> String:
	match level_data.rule_type:
		"multiplication_total":
			return "Goal: build equal groups until you reach %d." % level_data.goal_target_amount
		"addition_total":
			return "Goal: add matched groups until you reach %d." % level_data.goal_target_amount
		_:
			return "Goal: collect %d tile(s) showing value %d." % [level_data.goal_target_amount, level_data.goal_target_value]

static func get_progress_message(level_data: MathLevelData, progress_gained: int) -> String:
	match level_data.rule_type:
		"multiplication_total":
			return "Built %d worth of repeated groups." % progress_gained
		"addition_total":
			return "Added %d to the running total." % progress_gained
		_:
			return "Collected %d target tile(s)." % progress_gained

static func get_level_status_text(chapter_id: String) -> String:
	if "multiplication" in chapter_id:
		return "Swap adjacent tiles to make matches of 3 or more. Each matched value counts as a repeated equal group."
	if "addition" in chapter_id:
		return "Swap adjacent tiles to make matches of 3 or more. Every matched value adds to the bridge total."
	return "Swap adjacent tiles to make matches of 3 or more. Matching the target value fills the goal."

static func get_chapter_note(chapter_id: String) -> String:
	if "multiplication" in chapter_id:
		return "This unit teaches multiplication through repeated equal groups and array-building patterns."
	if "addition" in chapter_id:
		return "This unit teaches addition through visible accumulated totals."
	return "This unit teaches counting by collecting the exact number you are looking for."

static func collect_progress(level_data: MathLevelData, matches: Array, board_values: Array) -> int:
	match level_data.rule_type:
		"multiplication_total":
			var grouped_total := 0
			var counts_by_value := {}
			for cell in matches:
				var value := int(board_values[cell.y][cell.x])
				counts_by_value[value] = int(counts_by_value.get(value, 0)) + 1
			for value in counts_by_value.keys():
				grouped_total += int(value) * int(counts_by_value[value])
			return grouped_total
		"addition_total":
			var total := 0
			for cell in matches:
				total += int(board_values[cell.y][cell.x])
			return total
		_:
			var collected := 0
			for cell in matches:
				if int(board_values[cell.y][cell.x]) == level_data.goal_target_value:
					collected += 1
			return collected
