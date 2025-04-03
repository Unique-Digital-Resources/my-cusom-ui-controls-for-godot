extends Node

func sync_from_color_picker(control: Control) -> void:
	update_from_color(control, Color.WHITE)

func update_from_color(control: Control, color: Color) -> void:
	control.current_color = color
	if color.s > 0.0:
		control.value = color.h * 360.0
	update_handle_from_color(control)
	control.update_color_with_alpha()
	control.queue_redraw()

func update_handle_from_color(control: Control) -> void:
	var sat = control.current_color.s
	var val = control.current_color.v
	control.value = control.current_color.h * 360.0  # Sync hue
	
	if control.shape_mode == 0:  # Square
		control.handle_pos = Vector2(
			sat * 2.0 - 1.0,  # Saturation: 0 to 1 maps to -1 to 1
			1.0 - val * 2.0   # Value: 1 to 0 maps to -1 to 1
		)
	elif control.shape_mode == 1:  # Triangle
		var w = 1.0 - sat  # White component
		var b = 1.0 - val  # Black component
		control.triangle_bary = Vector3(
			sat * val,        # Hue vertex
			w * val,          # White vertex
			sat * b           # Black vertex
		)
		var sum = control.triangle_bary.x + control.triangle_bary.y + control.triangle_bary.z
		if sum > 0:
			control.triangle_bary /= sum
		else:
			control.triangle_bary = Vector3(1.0/3.0, 1.0/3.0, 1.0/3.0)
	elif control.shape_mode == 2:  # Circle
		var angle = deg_to_rad(control.value)
		control.circle_pos = Vector2(cos(angle), sin(angle)) * sat
		control.darkness_slider.value = val * 100.0

func update_color_from_handle(control: Control) -> void:
	var hue = control.value / 360.0
	var sat: float
	var val: float
	
	if control.shape_mode == 0:
		sat = (control.handle_pos.x + 1.0) / 2.0
		val = (1.0 - control.handle_pos.y) / 2.0
	elif control.shape_mode == 1:
		sat = control.triangle_bary.x + control.triangle_bary.z
		val = control.triangle_bary.x + control.triangle_bary.y
	elif control.shape_mode == 2:
		sat = control.circle_pos.length()
		val = control.darkness_slider.value / 100.0
		if sat > 0:
			hue = rad_to_deg(atan2(control.circle_pos.y, control.circle_pos.x)) / 360.0
			if hue < 0:
				hue += 1.0
		control.value = hue * 360.0
	
	sat = clamp(sat, 0.0, 1.0)
	val = clamp(val, 0.0, 1.0)
	control.current_color = Color.from_hsv(hue, sat, val)
	control.update_color_with_alpha()
	control.queue_redraw()

func switch_shape_mode(control: Control) -> void:
	if control.shape_mode == 1:
		control.triangle_bary = square_to_triangle_barycentric(control.handle_pos)
	elif control.shape_mode == 0:
		control.handle_pos = barycentric_to_square(control.triangle_bary)
	elif control.shape_mode == 2:
		var sat = control.current_color.s
		var val = control.current_color.v
		var angle = deg_to_rad(control.value)
		control.circle_pos = Vector2(cos(angle), sin(angle)) * sat
		control.darkness_slider.value = val * 100.0
	update_handle_from_color(control)

func set_darkness_slider(control: Control, slider_val: float) -> void:
	if control.shape_mode == 2:
		var hue = control.value / 360.0
		var sat = control.circle_pos.length()
		var val = slider_val / 100.0
		control.current_color = Color.from_hsv(hue, sat, val)
		control.update_color_with_alpha()

func square_to_triangle_barycentric(square_pos: Vector2) -> Vector3:
	var sat = (square_pos.x + 1.0) / 2.0
	var val = (1.0 - square_pos.y) / 2.0
	var w = 1.0 - sat
	var b = 1.0 - val
	var bary = Vector3(sat * val, w * val, sat * b)
	var sum = bary.x + bary.y + bary.z
	if sum > 0:
		bary /= sum
	return bary

func barycentric_to_square(bary: Vector3) -> Vector2:
	var sat = bary.x + bary.z
	var val = bary.x + bary.y
	return Vector2(
		sat * 2.0 - 1.0,
		1.0 - val * 2.0
	)
