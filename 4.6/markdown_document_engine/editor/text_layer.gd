@tool
extends Control

var editor: Control

func _draw() -> void:
	if is_instance_valid(editor):
		editor._draw_text()
