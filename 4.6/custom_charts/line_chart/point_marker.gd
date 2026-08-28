@tool
class_name PointMarker
extends Control

@export_group("Data")
@export var x_value: float = 0.0 :
	set(v):
		x_value = v
		_request_sort()
@export var y_value: float = 0.0 :
	set(v):
		y_value = v
		_request_sort()

@export_group("Marker Style")
@export var marker_size: Vector2 = Vector2(16, 16) :
	set(v):
		marker_size = v
		_request_sort()
@export var panel_style: StyleBox :
	set(v):
		panel_style = v
		queue_redraw()

func _init() -> void:
	if not panel_style:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.2, 0.8, 1.0)
		sb.corner_radius_top_left = 8
		sb.corner_radius_top_right = 8
		sb.corner_radius_bottom_left = 8
		sb.corner_radius_bottom_right = 8
		sb.border_color = Color.WHITE
		sb.border_width_left = 2
		sb.border_width_right = 2
		sb.border_width_top = 2
		sb.border_width_bottom = 2
		panel_style = sb

func _request_sort() -> void:
	queue_redraw()
	var p := get_parent()
	if p is LineSeries:
		var chart := p.get_parent()
		if chart is LineChart:
			chart.queue_sort()

func _draw() -> void:
	if panel_style:
		panel_style.draw(get_canvas_item(), Rect2(Vector2.ZERO, size))
