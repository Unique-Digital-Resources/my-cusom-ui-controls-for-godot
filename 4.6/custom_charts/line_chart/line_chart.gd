@tool
class_name LineChart
extends Container

enum LineMode { STRAIGHT, CURVED }
enum FlowDirection { LEFT_TO_RIGHT, RIGHT_TO_LEFT, BOTTOM_TO_TOP, TOP_TO_BOTTOM }

@export_group("Chart Bounds")
@export var min_x: float = 0.0 :
	set(v):
		min_x = v
		queue_sort()
@export var max_x: float = 1.0 :
	set(v):
		max_x = v
		queue_sort()
@export var min_y: float = 0.0 :
	set(v):
		min_y = v
		queue_sort()
@export var max_y: float = 1.0 :
	set(v):
		max_y = v
		queue_sort()

@export_group("Direction")
@export var flow_direction: FlowDirection = FlowDirection.LEFT_TO_RIGHT :
	set(v):
		flow_direction = v
		queue_sort()

@export_group("Aspect Ratio")
@export var fixed_aspect_ratio: float = 0.0 :
	set(v):
		fixed_aspect_ratio = v
		queue_sort()

@export_group("Line")
@export var line_mode: LineMode = LineMode.STRAIGHT :
	set(v):
		line_mode = v
		queue_sort()

@export_group("Background")
@export var draw_background: bool = true :
	set(v):
		draw_background = v
		queue_redraw()
@export var background_color: Color = Color(1, 1, 1, 0.05) :
	set(v):
		background_color = v
		queue_redraw()
@export var draw_grid: bool = true :
	set(v):
		draw_grid = v
		queue_redraw()
@export var grid_color: Color = Color(1, 1, 1, 0.15) :
	set(v):
		grid_color = v
		queue_redraw()
@export_range(1, 20) var grid_x_subdivs: int = 4 :
	set(v):
		grid_x_subdivs = v
		queue_sort()
@export_range(1, 20) var grid_y_subdivs: int = 4 :
	set(v):
		grid_y_subdivs = v
		queue_sort()

func _notification(what: int) -> void:
	if what == NOTIFICATION_CHILD_ORDER_CHANGED or what == NOTIFICATION_RESIZED:
		queue_sort()
	elif what == NOTIFICATION_SORT_CHILDREN:
		_sort_markers()

func _get_minimum_size() -> Vector2:
	return Vector2(64, 64)

func _get_chart_rect() -> Rect2:
	var rect := Rect2(Vector2.ZERO, size)
	var top_m := 0.0
	var bot_m := 0.0
	var left_m := 0.0
	var right_m := 0.0
	for c in get_children():
		if c is ChartAxis:
			var axis := c as ChartAxis
			var cmin := axis.get_combined_minimum_size()
			match axis.alignment:
				ChartAxis.AlignmentMode.TOP: top_m = maxf(top_m, cmin.y)
				ChartAxis.AlignmentMode.BOTTOM: bot_m = maxf(bot_m, cmin.y)
				ChartAxis.AlignmentMode.LEFT: left_m = maxf(left_m, cmin.x)
				ChartAxis.AlignmentMode.RIGHT: right_m = maxf(right_m, cmin.x)
				
	rect = Rect2(Vector2(left_m, top_m), size - Vector2(left_m + right_m, top_m + bot_m))
	
	if fixed_aspect_ratio > 0.0 and rect.size.y > 0.0:
		var current_ratio := rect.size.x / rect.size.y
		if current_ratio > fixed_aspect_ratio:
			var new_w := rect.size.y * fixed_aspect_ratio
			rect.position.x += (rect.size.x - new_w) * 0.5
			rect.size.x = new_w
		else:
			var new_h := rect.size.x / fixed_aspect_ratio
			rect.position.y += (rect.size.y - new_h) * 0.5
			rect.size.y = new_h
	return rect

func _sort_markers() -> void:
	var chart_rect := _get_chart_rect()
	var series_arr: Array[LineSeries] = []
	var axes_arr: Array[ChartAxis] = []
	
	for c in get_children():
		if c is LineSeries: series_arr.append(c as LineSeries)
		elif c is ChartAxis: axes_arr.append(c as ChartAxis)
		
	for axis in axes_arr:
		var axis_min := axis.get_combined_minimum_size()
		match axis.alignment:
			ChartAxis.AlignmentMode.BOTTOM:
				axis.position = Vector2(chart_rect.position.x, chart_rect.position.y + chart_rect.size.y)
				axis.size = Vector2(chart_rect.size.x, axis_min.y)
				axis.set_chart_subdivs(grid_x_subdivs)
			ChartAxis.AlignmentMode.TOP:
				axis.position = Vector2(chart_rect.position.x, chart_rect.position.y - axis_min.y)
				axis.size = Vector2(chart_rect.size.x, axis_min.y)
				axis.set_chart_subdivs(grid_x_subdivs)
			ChartAxis.AlignmentMode.LEFT:
				axis.position = Vector2(chart_rect.position.x - axis_min.x, chart_rect.position.y)
				axis.size = Vector2(axis_min.x, chart_rect.size.y)
				axis.set_chart_subdivs(grid_y_subdivs)
			ChartAxis.AlignmentMode.RIGHT:
				axis.position = Vector2(chart_rect.position.x + chart_rect.size.x, chart_rect.position.y)
				axis.size = Vector2(axis_min.x, chart_rect.size.y)
				axis.set_chart_subdivs(grid_y_subdivs)
		axis.queue_sort()
		
	for series in series_arr:
		series.position = chart_rect.position
		series.size = chart_rect.size
		series.chart_rect_local = Rect2(Vector2.ZERO, chart_rect.size)
		series.screen_points.clear()
		
		# Determine the baseline X and Y for area filling
		if flow_direction in [FlowDirection.LEFT_TO_RIGHT, FlowDirection.RIGHT_TO_LEFT]:
			series.baseline_y = chart_rect.size.y
			series.baseline_x = 0.0
		else:
			series.baseline_y = 0.0
			series.baseline_x = 0.0 # Vertical flows fill towards the left edge (X=0)
			
		series.line_mode = line_mode
		series.flow_direction = flow_direction
		
		var markers: Array[PointMarker] = []
		for m in series.get_children():
			if m is PointMarker: markers.append(m as PointMarker)
			
		markers.sort_custom(func(a, b): return a.x_value < b.x_value)
		
		for m in markers:
			var norm_x := 0.0
			if max_x > min_x: norm_x = clampf((m.x_value - min_x) / (max_x - min_x), 0.0, 1.0)
			var norm_y := 0.0
			if max_y > min_y: norm_y = clampf((m.y_value - min_y) / (max_y - min_y), 0.0, 1.0)
			
			var px := 0.0
			var py := 0.0
			match flow_direction:
				FlowDirection.LEFT_TO_RIGHT:
					px = chart_rect.size.x * norm_x
					py = chart_rect.size.y - (chart_rect.size.y * norm_y)
				FlowDirection.RIGHT_TO_LEFT:
					px = chart_rect.size.x - (chart_rect.size.x * norm_x)
					py = chart_rect.size.y - (chart_rect.size.y * norm_y)
				FlowDirection.BOTTOM_TO_TOP:
					px = chart_rect.size.x * norm_y
					py = chart_rect.size.y - (chart_rect.size.y * norm_x)
				FlowDirection.TOP_TO_BOTTOM:
					px = chart_rect.size.x * norm_y
					py = chart_rect.size.y * norm_x
			
			var m_size := m.marker_size
			m.position = Vector2(px - m_size.x * 0.5, py - m_size.y * 0.5)
			m.size = m_size
			m.queue_redraw()
			series.screen_points.append(Vector2(px, py))
			
		series.queue_redraw()
	queue_redraw()

func _draw() -> void:
	var chart_rect := _get_chart_rect()
	var local_rect = Rect2(Vector2.ZERO, size)
	
	if draw_background: draw_rect(local_rect, background_color, true)
	
	if draw_grid:
		for i in range(grid_x_subdivs + 1):
			var t := float(i) / float(grid_x_subdivs)
			if flow_direction in [FlowDirection.LEFT_TO_RIGHT, FlowDirection.RIGHT_TO_LEFT]:
				var x_pos := chart_rect.position.x + chart_rect.size.x * t
				draw_line(Vector2(x_pos, chart_rect.position.y), Vector2(x_pos, chart_rect.position.y + chart_rect.size.y), grid_color, 1.0, true)
			else:
				var y_pos := chart_rect.position.y + chart_rect.size.y * t
				draw_line(Vector2(chart_rect.position.x, y_pos), Vector2(chart_rect.position.x + chart_rect.size.x, y_pos), grid_color, 1.0, true)
				
		for i in range(grid_y_subdivs + 1):
			var t := float(i) / float(grid_y_subdivs)
			if flow_direction in [FlowDirection.LEFT_TO_RIGHT, FlowDirection.RIGHT_TO_LEFT]:
				var y_pos := chart_rect.position.y + chart_rect.size.y * t
				draw_line(Vector2(chart_rect.position.x, y_pos), Vector2(chart_rect.position.x + chart_rect.size.x, y_pos), grid_color, 1.0, true)
			else:
				var x_pos := chart_rect.position.x + chart_rect.size.x * t
				draw_line(Vector2(x_pos, chart_rect.position.y), Vector2(x_pos, chart_rect.position.y + chart_rect.size.y), grid_color, 1.0, true)
