extends Node2D

func _ready() -> void:
	AbstractionManager.abstraction_changed.connect(_on_abstraction_changed)
	_on_abstraction_changed(AbstractionManager.current_level)

func _on_abstraction_changed(level: int) -> void:
	$NumberLayer.visible = level >= AbstractionManager.AbstractionLevel.NUMBER
	$AdditionLayer.visible = level >= AbstractionManager.AbstractionLevel.ADDITION
	$MultiplicationLayer.visible = level >= AbstractionManager.AbstractionLevel.MULTIPLICATION
