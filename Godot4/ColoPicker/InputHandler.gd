extends Node

const ColorManager = preload("res://ColoPicker/ColorManager.gd")
var color_manager = ColorManager.new()

var is_dragging_slider: bool = false
var is_dragging_radius: bool = false
var is_dragging_handle: bool = false

func handle_input(control: Control, event: InputEvent) -> void:
	var center = control.size / 2
	var inner_radius = control.effective_radius - control.line_width if control.shape_mode != 2 else control.effective_radius
	var shape_size = inner_radius / sqrt(2) if control.shape_mode != 2 else inner_radius
	var local_pos = event.position - center
	var distance = local_pos.length()
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if control.shape_mode != 2 and distance <= control.effective_radius + control.line_width / 2 and distance >= control.effective_radius - control.line_width:
				is_dragging_slider = true
				update_hue(control, local_pos)
			elif distance <= shape_size + 10:
				is_dragging_handle = true
				update_shape_handle(control, local_pos)
			control.queue_redraw()
		elif not event.pressed:
			is_dragging_slider = false
			is_dragging_handle = false
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed and distance <= control.effective_radius + control.line_width / 2:
			is_dragging_radius = true
		elif not event.pressed:
			is_dragging_radius = false
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE and event.pressed:
		control.shape_mode = (control.shape_mode + 1) % 3
		color_manager.switch_shape_mode(control)
		control.queue_redraw()
	
	if event is InputEventMouseMotion and is_dragging_slider and control.shape_mode != 2:
		update_hue(control, local_pos)
		control.queue_redraw()
	
	if event is InputEventMouseMotion and is_dragging_handle:
		update_shape_handle(control, local_pos)
		control.queue_redraw()
	
	if event is InputEventMouseMotion and is_dragging_radius:
		var new_radius = distance
		var max_radius = min(control.size.x, control.size.y) * 0.5
		control.current_radius_factor = clamp(new_radius / max_radius, control.min_radius_factor, control.max_radius_factor)
		control.update_radius()
		control.queue_redraw()

func update_hue(control: Control, local_pos: Vector2) -> void:
	var angle = atan2(local_pos.y, local_pos.x)
	var normalized_angle = rad_to_deg(angle) + 90
	if normalized_angle < 0:
		normalized_angle += 360
	control.value = remap(normalized_angle, 0, 360, control.min_value, control.max_value)
	control.value = clamp(control.value, control.min_value, control.max_value)
	color_manager.update_color_from_handle(control)

func update_shape_handle(control: Control, local_pos: Vector2) -> void:
	var inner_radius = control.effective_radius - control.line_width if control.shape_mode != 2 else control.effective_radius
	var shape_size = inner_radius / sqrt(2) if control.shape_mode != 2 else inner_radius
	if control.shape_mode == 0:
		control.handle_pos = Vector2(
			clamp(local_pos.x / shape_size, -1.0, 1.0),
			clamp(local_pos.y / shape_size, -1.0, 1.0)
		)
	elif control.shape_mode == 1:
		var base_angle = deg_to_rad(remap(control.value, control.min_value, control.max_value, -90, 270))
		var points = [
			Vector2(cos(base_angle), sin(base_angle)) * inner_radius,
			Vector2(cos(base_angle - deg_to_rad(120)), sin(base_angle - deg_to_rad(120))) * inner_radius,
			Vector2(cos(base_angle + deg_to_rad(120)), sin(base_angle + deg_to_rad(120))) * inner_radius
		]
		control.triangle_bary = point_to_barycentric(local_pos, points)
		control.triangle_bary.x = clamp(control.triangle_bary.x, 0.0, 1.0)
		control.triangle_bary.y = clamp(control.triangle_bary.y, 0.0, 1.0)
		control.triangle_bary.z = clamp(control.triangle_bary.z, 0.0, 1.0)
		var sum = control.triangle_bary.x + control.triangle_bary.y + control.triangle_bary.z
		if sum > 0:
			control.triangle_bary /= sum
	elif control.shape_mode == 2:
		control.circle_pos = (local_pos / inner_radius).limit_length(1.0)
	color_manager.update_color_from_handle(control)

func is_point_in_shape(control: Control, point: Vector2) -> bool:
	var inner_radius = control.effective_radius - control.line_width if control.shape_mode != 2 else control.effective_radius
	var shape_size = inner_radius / sqrt(2) if control.shape_mode != 2 else inner_radius
	
	if control.shape_mode == 0:
		return abs(point.x) <= shape_size and abs(point.y) <= shape_size
	elif control.shape_mode == 1:
		var base_angle = deg_to_rad(remap(control.value, control.min_value, control.max_value, -90, 270))
		var points = [
			Vector2(cos(base_angle), sin(base_angle)) * inner_radius,
			Vector2(cos(base_angle - deg_to_rad(120)), sin(base_angle - deg_to_rad(120))) * inner_radius,
			Vector2(cos(base_angle + deg_to_rad(120)), sin(base_angle + deg_to_rad(120))) * inner_radius
		]
		return is_point_in_triangle(point, points)
	elif control.shape_mode == 2:
		return point.length() <= shape_size
	return false

func is_point_in_triangle(point: Vector2, triangle: Array) -> bool:
	var bary = point_to_barycentric(point, triangle)
	return bary.x >= 0 and bary.y >= 0 and bary.z >= 0 and bary.x + bary.y + bary.z <= 1.0

func point_to_barycentric(point: Vector2, triangle: Array) -> Vector3:
	var v0 = triangle[1] - triangle[0]
	var v1 = triangle[2] - triangle[0]
	var v2 = point - triangle[0]
	var d00 = v0.dot(v0)
	var d01 = v0.dot(v1)
	var d11 = v1.dot(v1)
	var d20 = v2.dot(v0)
	var d21 = v2.dot(v1)
	var denom = d00 * d11 - d01 * d01
	if denom == 0:
		return Vector3(1.0/3.0, 1.0/3.0, 1.0/3.0)
	var v = (d11 * d20 - d01 * d21) / denom
	var w = (d00 * d21 - d01 * d20) / denom
	var u = 1.0 - v - w
	return Vector3(u, v, w)
