@tool
class_name MathStyle
extends Resource

## Controls typography, spacing, and colors for the entire math expression.

@export_group("Typography")
@export var font: FontFile:
	set(value):
		font = value
		emit_changed()

@export_group("Sizing & Spacing")
@export_range(0.5, 0.9, 0.01) var script_scale: float = 0.7:
	set(value):
		script_scale = value
		emit_changed()

# FIX: Restored operator_spacing as a master multiplier for all gaps
@export_range(0.0, 2.0, 0.01) var operator_spacing: float = 0.3:
	set(value):
		operator_spacing = value
		emit_changed()

@export_range(0.01, 0.2, 0.01) var line_thickness: float = 0.06:
	set(value):
		line_thickness = value
		emit_changed()

@export_group("Colors")
@export var color: Color = Color.WHITE:
	set(value):
		color = value
		emit_changed()
