extends Node

var player_position: Vector2 = Vector2.ZERO
var story_flags: Dictionary = {}

func set_flag(flag_name: String, value: bool = true) -> void:
	story_flags[flag_name] = value

func has_flag(flag_name: String) -> bool:
	return bool(story_flags.get(flag_name, false))