@tool
class_name LineSeries
extends Control

enum BlendMode { MIX, ADD, MULTIPLY }

@export_group("Line Style")
@export var line_color: Color = Color(0.4, 0.6, 0.9) :
	set(v):
		line_color = v
		queue_redraw()
@export_range(0.5, 16.0, 0.1, "suffix:px") var line_width: float = 2.0 :
	set(v):
		line_width = v
		queue_redraw()
@export var is_line_visible: bool = true :
	set(v):
		is_line_visible = v
		queue_redraw()

@export_group("Gradient X")
@export var grad_x_colors: Array[Color] = [] :
	set(v):
		grad_x_colors = v
		queue_redraw()
@export var grad_x_stops: Array[float] = [] :
	set(v):
		grad_x_stops = v
		queue_redraw()

@export_group("Gradient Y")
@export var grad_y_colors: Array[Color] = [] :
	set(v):
		grad_y_colors = v
		queue_redraw()
@export var grad_y_stops: Array[float] = [] :
	set(v):
		grad_y_stops = v
		queue_redraw()

@export_group("Gradient Mixing")
@export var blend_mode: BlendMode = BlendMode.MIX :
	set(v):
		blend_mode = v
		queue_redraw()
@export_range(0.0, 1.0, 0.01) var blend_ratio: float = 0.5 :
	set(v):
		blend_ratio = clampf(v, 0.0, 1.0)
		queue_redraw()

@export_group("Area Fill")
@export var fill_area: bool = false :
	set(v):
		fill_area = v
		queue_redraw()
@export var fill_color: Color = Color(0.4, 0.6, 0.9, 0.3) :
	set(v):
		fill_color = v
		queue_redraw()

var screen_points: Array[Vector2] = []
var baseline_y: float = 0.0
var baseline_x: float = 0.0
var chart_rect_local: Rect2 = Rect2()

var line_mode := 0 # 0 = STRAIGHT, 1 = CURVED
var flow_direction := 0 # 0 = L_to_R, 1 = R_to_L, 2 = B_to_T, 3 = T_to_B

func _notification(what: int) -> void:
	if what == NOTIFICATION_CHILD_ORDER_CHANGED:
		var p := get_parent()
		if p is LineChart:
			p.queue_sort()

static func _sample_custom_gradient(t: float, colors: Array[Color], stops: Array[float]) -> Color:
	if colors.is_empty(): return Color.TRANSPARENT
	if colors.size() == 1: return colors[0]
	
	var use_stops := stops
	if use_stops.size() != colors.size():
		use_stops.clear()
		for i in range(colors.size()):
			use_stops.append(float(i) / float(colors.size() - 1))
			
	t = clampf(t, 0.0, 1.0)
	if t <= use_stops[0]: return colors[0]
	if t >= use_stops[use_stops.size() - 1]: return colors.back()
	
	for i in range(colors.size() - 1):
		if t >= use_stops[i] and t <= use_stops[i+1]:
			var span = maxf(0.0001, use_stops[i+1] - use_stops[i])
			return colors[i].lerp(colors[i+1], (t - use_stops[i]) / span)
	return colors.back()

func _get_gradient_color(p: Vector2) -> Color:
	var norm_x = clampf(p.x / maxf(1.0, size.x), 0.0, 1.0)
	var norm_y = clampf(1.0 - (p.y / maxf(1.0, size.y)), 0.0, 1.0)
	
	var has_x = not grad_x_colors.is_empty()
	var has_y = not grad_y_colors.is_empty()
	
	var c_x := line_color
	var c_y := line_color
	
	if has_x:
		c_x = _sample_custom_gradient(norm_x, grad_x_colors, grad_x_stops)
	if has_y:
		c_y = _sample_custom_gradient(norm_y, grad_y_colors, grad_y_stops)
		
	if has_x and has_y:
		match blend_mode:
			BlendMode.MIX: return c_x.lerp(c_y, blend_ratio)
			BlendMode.ADD: return c_x + c_y
			BlendMode.MULTIPLY: return c_x * c_y
	elif has_x:
		return c_x
	elif has_y:
		return c_y
		
	return line_color

func _draw() -> void:
	if screen_points.size() < 2:
		return
	
	var draw_pts: PackedVector2Array = []
	if line_mode == 0: # STRAIGHT
		draw_pts = screen_points.duplicate()
	else:
		draw_pts = _get_curved_points(screen_points)
		
	if fill_area:
		var fill_pts := draw_pts.duplicate()
		
		if flow_direction <= 1: # Horizontal flows
			fill_pts.append(Vector2(draw_pts[draw_pts.size() - 1].x, baseline_y))
			fill_pts.append(Vector2(draw_pts[0].x, baseline_y))
		else: # Vertical flows
			fill_pts.append(Vector2(baseline_x, draw_pts[draw_pts.size() - 1].y))
			fill_pts.append(Vector2(baseline_x, draw_pts[0].y))
		
		var cols := PackedColorArray()
		cols.resize(fill_pts.size())
		for i in range(fill_pts.size()):
			var p: Vector2 = fill_pts[i]
			var c: Color = _get_gradient_color(p)
			c.a *= fill_color.a
			cols[i] = c
		draw_polygon(fill_pts, cols)
		
	if is_line_visible:
		var has_grad = not grad_x_colors.is_empty() or not grad_y_colors.is_empty()
		if has_grad:
			# Draw segment by segment to apply gradient smoothly
			for i in range(draw_pts.size() - 1):
				var p1 = draw_pts[i]
				var p2 = draw_pts[i+1]
				var c1 = _get_gradient_color(p1)
				draw_line(p1, p2, c1, line_width, true)
		else:
			draw_polyline(draw_pts, line_color, line_width, true)

func _get_curved_points(points: Array[Vector2]) -> PackedVector2Array:
	if points.size() < 2:
		return PackedVector2Array()
	var out: PackedVector2Array = []
	out.append(points[0])
	for i in range(points.size() - 1):
		var p0: Vector2 = points[i - 1] if i > 0 else points[i]
		var p1: Vector2 = points[i]
		var p2: Vector2 = points[i + 1]
		var p3: Vector2 = points[i + 2] if i + 2 < points.size() else points[i + 1]
		var steps := 12
		for t_idx in range(1, steps + 1):
			var t := float(t_idx) / float(steps)
			var t2 := t * t
			var t3 := t2 * t
			var x := 0.5 * ((2.0 * p1.x) + (-p0.x + p2.x) * t + (2.0*p0.x - 5.0*p1.x + 4.0*p2.x - p3.x) * t2 + (-p0.x + 3.0*p1.x - 3.0*p2.x + p3.x) * t3)
			var y := 0.5 * ((2.0 * p1.y) + (-p0.y + p2.y) * t + (2.0*p0.y - 5.0*p1.y + 4.0*p2.y - p3.y) * t2 + (-p0.y + 3.0*p1.y - 3.0*p2.y + p3.y) * t3)
			out.append(Vector2(x, y))
	return out
