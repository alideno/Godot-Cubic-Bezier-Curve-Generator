extends Node2D

@onready var fps_label = $Label

func _ready() -> void:
	fps_label.text = str(int(Engine.get_frames_per_second())) + " fps"

func _process(delta: float) -> void:
	fps_label.text = str(int(Engine.get_frames_per_second())) + " fps"
