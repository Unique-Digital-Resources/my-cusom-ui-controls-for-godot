@tool
extends Control

var editor: Control

func _draw() -> void:
	if is_instance_valid(editor):
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.12, 0.12, 0.14))
