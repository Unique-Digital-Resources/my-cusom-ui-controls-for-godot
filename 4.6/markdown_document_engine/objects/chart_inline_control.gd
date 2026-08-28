@tool
extends Control
class_name ChartInlineControl

var color: Color = Color.CYAN

func set_args(p_args: String) -> void:
	if p_args == "red":
		color = Color.RED
	elif p_args == "blue":
		color = Color.BLUE
	else:
		color = Color.CYAN
	queue_redraw()

func _init() -> void:
	custom_minimum_size = Vector2(32, 32)
	size = custom_minimum_size

func _draw() -> void:
	var center = size / 2.0
	var radius = 12.0
	draw_circle(center, radius + 2, Color.BLACK)
	
	var points = PackedVector2Array()
	points.append(center)
	for i in range(11):
		var angle = lerp(0, PI * 1.5, float(i) / 10.0) - PI/2.0
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
		
	draw_colored_polygon(points, color)
	draw_arc(center, radius, 0, TAU, 32, Color.BLACK, 1.5)
