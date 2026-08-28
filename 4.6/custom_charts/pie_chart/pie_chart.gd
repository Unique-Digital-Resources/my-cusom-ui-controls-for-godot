@tool
class_name PieChart
extends ChartContainer

enum ChartMode { FULL_PIE, HALF_PIE, DOUGHNUT, HALF_DOUGHNUT }
enum RotationDirection { CLOCKWISE, COUNTER_CLOCKWISE }

@export_group("Layout")
@export var mode: ChartMode = ChartMode.FULL_PIE :
	set(v):
		mode = v
		queue_sort()
		queue_redraw()

@export var rotation_direction: RotationDirection = RotationDirection.CLOCKWISE :
	set(v):
		rotation_direction = v
		queue_sort()

@export_group("Rotation")
@export_range(-360.0, 360.0, 0.1, "degrees") var start_rotation: float = -90.0 :
	set(v):
		start_rotation = v
		queue_sort()
		queue_redraw()

@export_group("Gap")
@export_range(0.0, 30.0, 0.1, "degrees") var pad_angle: float = 2.0 :
	set(v):
		pad_angle = v
		queue_sort()
@export_range(0.0, 5.0, 0.1) var gap_explode_factor: float = 1.0 :
	set(v):
		gap_explode_factor = v
		queue_sort()

@export_group("Doughnut")
@export_range(0.0, 0.99, 0.01) var inner_radius_ratio: float = 0.5 :
	set(v):
		inner_radius_ratio = clamp(v, 0.0, 0.99)
		queue_sort()
		queue_redraw()

@export_group("Rounded Corners")
@export_range(0.0, 64.0, 0.1, "suffix:px") var corner_radius: float = 0.0 :
	set(v):
		corner_radius = v
		queue_sort()
@export_range(0.0, 64.0, 0.1, "suffix:px") var inner_corner_radius: float = 0.0 :
	set(v):
		inner_corner_radius = v
		queue_sort()

@export_group("Focus")
@export var exclusive_focus: bool = true
@export_range(0.0, 100.0, 1.0, "suffix:px") var explode_distance: float = 0.0 :
	set(v):
		explode_distance = v
		queue_sort()

@export_group("Background Grid")
@export var draw_background_grid: bool = false :
	set(v):
		draw_background_grid = v
		queue_redraw()
@export var grid_color: Color = Color(1, 1, 1, 0.1) :
	set(v):
		grid_color = v
		queue_redraw()
@export_range(1, 20) var grid_circle_count: int = 4 :
	set(v):
		grid_circle_count = v
		queue_redraw()
@export_range(4, 60) var grid_line_count: int = 12 :
	set(v):
		grid_line_count = v
		queue_redraw()
@export_range(0.0, 10.0, 0.1, "suffix:px") var grid_line_width: float = 1.0 :
	set(v):
		grid_line_width = v
		queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_CHILD_ORDER_CHANGED or what == NOTIFICATION_RESIZED:
		queue_sort()

func _sort_chart_items() -> void:
	var items: Array[ChartItem] = _get_items()
	var axes: Array[PieChartAxis] = []
	for c in get_children():
		if c is PieChartAxis: axes.append(c as PieChartAxis)
		
	if items.is_empty() and axes.is_empty(): return

	var total := _get_total_value() if proportional else 100.0
	if total <= 0.0: total = float(items.size())

	var pie_rect := Rect2(Vector2(padding, padding), size - Vector2(padding * 2.0, padding * 2.0))
	var chart_center := pie_rect.position + pie_rect.size * 0.5
	var base_outer_r := minf(pie_rect.size.x, pie_rect.size.y) * 0.5

	var max_span := 360.0
	var is_doughnut := false
	match mode:
		ChartMode.HALF_PIE: max_span = 180.0
		ChartMode.DOUGHNUT: is_doughnut = true
		ChartMode.HALF_DOUGHNUT: max_span = 180.0; is_doughnut = true

	var gap_explode := pad_angle * gap_explode_factor
	var base_inner_r := base_outer_r * inner_radius_ratio if is_doughnut else 0.0

	# Update Axes: Give them a larger rect so labels have room to draw outside the pie
	for axis in axes:
		var axis_rect := pie_rect.grow_individual(50, 50, 50, 50)
		fit_child_in_rect(axis, axis_rect)
		var local_center := chart_center - axis.position
		axis.set_chart_geometry(local_center, base_outer_r, base_inner_r)

	var cursor := start_rotation
	for it in items:
		var slice := it as PieSlice
		if slice == null: continue

		var fraction: float = slice.value / total
		var full_span: float = fraction * max_span
		var actual_span: float = maxf(0.0, full_span - pad_angle)

		slice.span_angle = actual_span
		if rotation_direction == RotationDirection.CLOCKWISE:
			slice.start_angle = cursor + pad_angle * 0.5
			cursor += full_span
		else:
			slice.start_angle = cursor - pad_angle * 0.5 - actual_span
			cursor -= full_span

		slice.chart_center = chart_center
		slice.base_outer_r = base_outer_r
		slice.base_inner_r = base_inner_r
		slice.corner_radius = corner_radius
		slice.inner_corner_radius = inner_corner_radius
		slice.global_explode = explode_distance + gap_explode
		slice._update_geometry()

func _draw() -> void:
	if not draw_background_grid: return
	var pie_rect := Rect2(Vector2(padding, padding), size - Vector2(padding * 2.0, padding * 2.0))
	var center := pie_rect.position + pie_rect.size * 0.5
	var max_r := minf(pie_rect.size.x, pie_rect.size.y) * 0.5
	var is_doughnut := (mode == ChartMode.DOUGHNUT or mode == ChartMode.HALF_DOUGHNUT)
	var inner_r := max_r * inner_radius_ratio if is_doughnut else 0.0
	var max_span := 360.0 if mode != ChartMode.HALF_PIE and mode != ChartMode.HALF_DOUGHNUT else 180.0
	var start_rad := deg_to_rad(start_rotation)
	var end_rad := deg_to_rad(start_rotation + max_span)

	for i in range(1, grid_circle_count + 1):
		var r := lerpf(inner_r, max_r, float(i) / float(grid_circle_count))
		if r > 0.0: draw_arc(center, r, start_rad, end_rad, 64, grid_color, grid_line_width, true)

	if grid_line_count > 0:
		var angle_step := deg_to_rad(max_span / float(grid_line_count))
		for i in range(grid_line_count + 1):
			var a := start_rad + angle_step * i
			var p1 := center + Vector2(cos(a), sin(a)) * inner_r
			var p2 := center + Vector2(cos(a), sin(a)) * max_r
			draw_line(p1, p2, grid_color, grid_line_width, true)

func _on_slice_clicked(slice: PieSlice) -> void:
	if not exclusive_focus:
		slice.focus_amount = 1.0 if slice.focus_amount < 0.5 else 0.0
		return
	for it in _get_items(): it.focus_amount = 0.0
	slice.focus_amount = 1.0
