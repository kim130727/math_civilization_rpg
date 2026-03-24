extends Resource
class_name MathLevelData

@export var level_id: String = ""
@export var title: String = ""
@export var grade_id: String = "grade1"
@export var chapter_id: String = ""
@export var unit_id: String = ""
@export var rule_type: String = "counting_collect"
@export var board_width: int = 6
@export var board_height: int = 6
@export var palette: Array[int] = [1, 2, 3]
@export var goal_target_value: int = 1
@export var goal_target_amount: int = 12
@export var move_limit: int = 12
@export var hint: String = ""
@export var star_thresholds: Array[int] = [5, 2]
@export var tile_labels: Dictionary = {}
