extends RefCounted
class_name ChapterRuleLibrary

static func get_goal_label(level_data: MathLevelData) -> String:
	match level_data.rule_type:
		"multiplication_total":
			return "Goal: make groups of %d until the products reach %d." % [level_data.goal_target_value, level_data.goal_target_amount]
		"addition_total":
			return "Goal: add matched groups until you reach %d." % level_data.goal_target_amount
		_:
			return "Goal: collect %d tile(s) showing value %d." % [level_data.goal_target_amount, level_data.goal_target_value]

static func get_progress_message(level_data: MathLevelData, progress_gained: int, matches: Array = [], board_values: Array = []) -> String:
	match level_data.rule_type:
		"multiplication_total":
			var groups := _get_equal_groups(matches, board_values)
			var parts: Array = []
			for group in groups:
				var value: int = int(group.get("value", 0))
				var count: int = int(group.get("count", 0))
				if level_data.goal_target_value > 0 and value != level_data.goal_target_value:
					continue
				parts.append("%d x %d = %d" % [value, count, value * count])
			if parts.is_empty():
				return "Only groups of %d count in this level." % level_data.goal_target_value
			return "Built %s." % _join_parts(parts)
		"addition_total":
			return "Added %d to the running total." % progress_gained
		_:
			return "Collected %d target tile(s)." % progress_gained

static func get_level_status_text(chapter_id: String) -> String:
	if "multiplication" in chapter_id or "multiply" in chapter_id:
		return "Swap adjacent tiles to make matches of 3 or more. Only the target number counts, and each equal group becomes value x group size."
	if "addition" in chapter_id:
		return "Swap adjacent tiles to make matches of 3 or more. Every matched value adds to the bridge total."
	return "Swap adjacent tiles to make matches of 3 or more. Matching the target value fills the goal."

static func get_chapter_note(chapter_id: String) -> String:
	if "multiplication" in chapter_id or "multiply" in chapter_id:
		return "This unit teaches multiplication through equal groups. Matching four 3 tiles means 3 x 4 = 12."
	if "addition" in chapter_id:
		return "This unit teaches addition through visible accumulated totals."
	return "This unit teaches counting by collecting the exact number you are looking for."

static func collect_progress(level_data: MathLevelData, matches: Array, board_values: Array) -> int:
	match level_data.rule_type:
		"multiplication_total":
			var grouped_total := 0
			for group in _get_equal_groups(matches, board_values):
				var value: int = int(group.get("value", 0))
				var count: int = int(group.get("count", 0))
				if level_data.goal_target_value > 0 and value != level_data.goal_target_value:
					continue
				grouped_total += value * count
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

static func _get_equal_groups(matches: Array, board_values: Array) -> Array:
	var matched_lookup := {}
	for cell in matches:
		matched_lookup[_cell_key(cell)] = cell

	var visited := {}
	var groups: Array = []
	var directions := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]

	for cell in matches:
		var key := _cell_key(cell)
		if visited.get(key, false):
			continue

		var value: int = int(board_values[cell.y][cell.x])
		var stack: Array = [cell]
		var count := 0
		visited[key] = true

		while not stack.is_empty():
			var current: Vector2i = stack.pop_back()
			count += 1
			for direction in directions:
				var next := current + direction
				var next_key := _cell_key(next)
				if not matched_lookup.has(next_key):
					continue
				if visited.get(next_key, false):
					continue
				if int(board_values[next.y][next.x]) != value:
					continue
				visited[next_key] = true
				stack.append(next)

		groups.append({
			"value": value,
			"count": count,
		})

	return groups

static func _cell_key(cell: Vector2i) -> String:
	return "%d,%d" % [cell.x, cell.y]

static func _join_parts(parts: Array) -> String:
	var text := ""
	for i in range(parts.size()):
		if i > 0:
			text += ", "
		text += String(parts[i])
	return text

