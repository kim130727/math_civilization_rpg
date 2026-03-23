extends Node

signal dialogue_requested(text: String)

func show_text(text: String) -> void:
	dialogue_requested.emit(text)
