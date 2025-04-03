extends Node

func draw_shapes(control: Control, center: Vector2) -> void:
	var hue = control.value / 360.0
	if control.shape_mode == 2:
		draw_circle_shape(control, center)
		control.darkness.visible = true
	else:
		draw_color_wheel_ring(control, center)
		if control.shape_mode == 0:
			draw_fixed_square(control, center, hue)
		elif control.shape_mode == 1:
			draw_rotating_triangle(control, center, hue)
		control.darkness.visible = false

func draw_color_wheel_ring(control: Control, center: Vector2) -> void:
	const segments = 256
	var step = TAU / segments
	
	for i in range(segments):
		var angle_start = i * step
		var angle_end = (i + 1) * step
		var hue = rad_to_deg(angle_start) + 90
		if hue >= 360:
			hue -= 360
		var color = Color.from_hsv(hue / 360.0, 1.0, 1.0)
		
		var outer_start = center + Vector2(cos(angle_start), sin(angle_start)) * control.effective_radius
		var outer_end = center + Vector2(cos(angle_end), sin(angle_end)) * control.effective_radius
		var inner_start = center + Vector2(cos(angle_start), sin(angle_start)) * (control.effective_radius - control.line_width)
		var inner_end = center + Vector2(cos(angle_end), sin(angle_end)) * (control.effective_radius - control.line_width)
		
		control.draw_line(outer_start, outer_end, color, control.line_width, true)
		control.draw_line(inner_start, inner_end, color, control.line_width, true)
	
	var angle = deg_to_rad(remap(control.value, control.min_value, control.max_value, -90, 270))
	var indicator_pos = center + Vector2(cos(angle), sin(angle)) * control.effective_radius
	control.draw_arc(indicator_pos, control.line_width / 2 + 1, 0, TAU, 32, Color.BLACK, 2.0, true)
	control.draw_arc(indicator_pos, control.line_width / 3, 0, TAU, 24, Color.WHITE, control.line_width / 3, true)

func draw_fixed_square(control: Control, center: Vector2, hue: float) -> void:
	var inner_radius = control.effective_radius - control.line_width
	var half_size = inner_radius / sqrt(2)
	
	var points = [
		center + Vector2(-half_size, -half_size),  # White
		center + Vector2(half_size, -half_size),   # Full hue
		center + Vector2(half_size, half_size),    # Dark hue
		center + Vector2(-half_size, half_size)    # Black
	]
	
	var colors = [
		Color.from_hsv(hue, 0.0, 1.0),
		Color.from_hsv(hue, 1.0, 1.0),
		Color.from_hsv(hue, 1.0, 0.0),
		Color.from_hsv(hue, 0.0, 0.0)
	]
	
	control.draw_polygon(points, colors)
	for i in range(4):
		control.draw_line(points[i], points[(i + 1) % 4], Color.GRAY, 1.0, true)

func draw_rotating_triangle(control: Control, center: Vector2, hue: float) -> void:
	var inner_radius = control.effective_radius - control.line_width
	var base_angle = deg_to_rad(remap(control.value, control.min_value, control.max_value, -90, 270))
	
	var points = [
		center + Vector2(cos(base_angle), sin(base_angle)) * inner_radius,  # Full hue
		center + Vector2(cos(base_angle - deg_to_rad(120)), sin(base_angle - deg_to_rad(120))) * inner_radius,  # White
		center + Vector2(cos(base_angle + deg_to_rad(120)), sin(base_angle + deg_to_rad(120))) * inner_radius   # Dark hue
	]
	
	var colors = [
		Color.from_hsv(hue, 1.0, 1.0),
		Color.from_hsv(hue, 0.0, 1.0),
		Color.from_hsv(hue, 1.0, 0.0)
	]
	
	control.draw_polygon(points, colors)
	for i in range(3):
		control.draw_line(points[i], points[(i + 1) % 3], Color.GRAY, 1.0, true)

func draw_circle_shape(control: Control, center: Vector2) -> void:
	var outer_radius = control.effective_radius
	const segments = 64
	var points = []
	var colors = []
	var val = control.darkness_slider.value / 100.0
	
	for i in range(segments):
		var angle1 = i * TAU / segments
		var angle2 = (i + 1) * TAU / segments
		var p1 = center + Vector2(cos(angle1), sin(angle1)) * outer_radius
		var p2 = center + Vector2(cos(angle2), sin(angle2)) * outer_radius
		
		points.append_array([center, p1, p2])
		var h1 = rad_to_deg(angle1) / 360.0
		var h2 = rad_to_deg(angle2) / 360.0
		if h1 >= 1.0: h1 -= 1.0
		if h2 >= 1.0: h2 -= 1.0
		colors.append_array([
			Color.from_hsv(h1, 0.0, val),  # Center
			Color.from_hsv(h1, 1.0, val),  # Edge
			Color.from_hsv(h2, 1.0, val)   # Edge
		])
	
	control.draw_polygon(points, colors)
	control.draw_arc(center, outer_radius, 0, TAU, segments, Color.GRAY, 1.0, true)

func draw_handle(control: Control, center: Vector2) -> void:
	var inner_radius = control.effective_radius - control.line_width if control.shape_mode != 2 else control.effective_radius
	var shape_size = inner_radius / sqrt(2) if control.shape_mode != 2 else inner_radius
	var handle_offset = Vector2.ZERO
	
	if control.shape_mode == 0:
		handle_offset = control.handle_pos * shape_size
	elif control.shape_mode == 1:
		var base_angle = deg_to_rad(remap(control.value, control.min_value, control.max_value, -90, 270))
		var points = [
			center + Vector2(cos(base_angle), sin(base_angle)) * inner_radius,
			center + Vector2(cos(base_angle - deg_to_rad(120)), sin(base_angle - deg_to_rad(120))) * inner_radius,
			center + Vector2(cos(base_angle + deg_to_rad(120)), sin(base_angle + deg_to_rad(120))) * inner_radius
		]
		handle_offset = points[0] * control.triangle_bary.x + points[1] * control.triangle_bary.y + points[2] * control.triangle_bary.z - center
	elif control.shape_mode == 2:
		handle_offset = control.circle_pos * inner_radius
	
	var handle_global_pos = center + handle_offset
	var col_with_alpha = control.current_color_with_alpha["color"]
	var alpha = control.current_color_with_alpha["alpha"]
	control.draw_circle(handle_global_pos, 5.0, Color.BLACK)
	control.draw_circle(handle_global_pos, 3.0, Color(col_with_alpha.r, col_with_alpha.g, col_with_alpha.b, alpha))
