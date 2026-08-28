@tool
class_name PieSlice
extends ChartItem

## A single wedge of a PieChart. Can contain child controls.

enum ContentAnchor { CHART_CENTER, SLICE_CENTER, SLICE_OUTER }
enum ContentRotation { NONE, ALIGN_SLICE, TANGENT_SLICE }
enum SizeMode { SHRINK_BEGIN, SHRINK_CENTER, SHRINK_END, EXPAND }
enum BlendMode { MIX, ADD, MULTIPLY }

@export_group("Appearance")
@export var color: Color = Color(0.55, 0.7, 0.95) :
	set(v):
		color = v
		queue_redraw()

@export_range(0.0, 1.0, 0.01) var slice_alpha: float = 1.0 :
	set(v):
		slice_alpha = v
		queue_redraw()

@export_group("Gradient Radial")
@export var grad_radial_colors: Array[Color] = [] :
	set(v):
		grad_radial_colors = v
		queue_redraw()
@export var grad_radial_stops: Array[float] = [] :
	set(v):
		grad_radial_stops = v
		queue_redraw()

@export_group("Gradient Angular")
@export var grad_angular_colors: Array[Color] = [] :
	set(v):
		grad_angular_colors = v
		queue_redraw()
@export var grad_angular_stops: Array[float] = [] :
	set(v):
		grad_angular_stops = v
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

@export_range(0.0, 1.0, 0.01) var height_ratio: float = 1.0 :
	set(v):
		height_ratio = clamp(v, 0.0, 1.0)
		queue_redraw()
		_update_geometry()

@export_group("Content Layout")
@export var content_anchor: ContentAnchor = ContentAnchor.SLICE_CENTER :
	set(v):
		content_anchor = v
		_update_geometry()
@export var content_rotation: ContentRotation = ContentRotation.NONE :
	set(v):
		content_rotation = v
		_update_geometry()
@export var content_offset: Vector2 = Vector2.ZERO :
	set(v):
		content_offset = v
		_update_geometry()
@export var content_size_mode_h: SizeMode = SizeMode.SHRINK_CENTER :
	set(v):
		content_size_mode_h = v
		_update_geometry()
@export var content_size_mode_v: SizeMode = SizeMode.SHRINK_CENTER :
	set(v):
		content_size_mode_v = v
		_update_geometry()
@export var content_scales_with_slice: bool = true :
	set(v):
		content_scales_with_slice = v
		_update_geometry()
@export var clip_children_to_bounds: bool = false :
	set(v): 
		clip_children_to_bounds = v
		clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW if v else CanvasItem.CLIP_CHILDREN_DISABLED

@export_group("Explode")
@export_range(0.0, 100.0, 1.0, "suffix:px") var explode_offset: float = 0.0 :
	set(v):
		explode_offset = v
		queue_redraw()
		_update_geometry()

@export_group("Focus")
@export_range(0.0, 200.0, 1.0, "suffix:px") var focus_offset: float = 18.0 :
	set(v):
		focus_offset = v
		queue_redraw()
		_update_geometry()
@export_range(0.5, 2.0, 0.01) var focus_scale: float = 1.06 :
	set(v):
		focus_scale = v
		queue_redraw()
		_update_geometry()
@export var focus_tint: Color = Color(1.0, 1.0, 1.0, 0.18) :
	set(v):
		focus_tint = v
		queue_redraw()

@export_group("Stroke")
@export_range(0.0, 16.0, 0.1, "suffix:px") var stroke_width: float = 0.0 :
	set(v):
		stroke_width = v
		queue_redraw()
@export var stroke_color: Color = Color.WHITE :
	set(v):
		stroke_color = v
		queue_redraw()

# --- Internal ---
var start_angle: float = 0.0 :
	set(v):
		start_angle = v
		queue_redraw()
		_update_geometry()
var span_angle: float = 0.0 :
	set(v):
		span_angle = v
		queue_redraw()
		_update_geometry()
var chart_center: Vector2 = Vector2.ZERO
var base_outer_r: float = 0.0
var base_inner_r: float = 0.0
var corner_radius: float = 0.0
var inner_corner_radius: float = 0.0
var global_explode: float = 0.0

var _local_draw_center: Vector2 = Vector2.ZERO
var _local_draw_outer: float = 0.0
var _local_draw_inner: float = 0.0

func _get_minimum_size() -> Vector2:
	return Vector2.ZERO

# Override modulate to protect children
func set_modulate(v: Color) -> void:
	slice_alpha = v.a
func get_modulate() -> Color:
	return Color(1, 1, 1, slice_alpha)
func set_self_modulate(v: Color) -> void:
	slice_alpha = v.a
func get_self_modulate() -> Color:
	return Color(1, 1, 1, slice_alpha)

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

func _draw() -> void:
	if span_angle <= 0.01: return

	var pts := _build_wedge_polygon(_local_draw_center, _local_draw_outer, _local_draw_inner)
	if pts.is_empty(): return

	var cols := PackedColorArray()
	cols.resize(pts.size())
	
	var has_rad = not grad_radial_colors.is_empty()
	var has_ang = not grad_angular_colors.is_empty()
	
	# Pre-calculate midpoint angle for perfect angular mapping
	var mid_angle := start_angle + (span_angle * 0.5)
	var half_span := maxf(0.01, span_angle * 0.5)
	
	for i in range(pts.size()):
		var p: Vector2 = pts[i]
		var c: Color = color
		
		if has_rad or has_ang:
			var c_rad = c
			var c_ang = c
			if has_rad:
				var dist = p.distance_to(_local_draw_center)
				var t = clampf((dist - _local_draw_inner) / maxf(0.01, _local_draw_outer - _local_draw_inner), 0.0, 1.0)
				c_rad = _sample_custom_gradient(t, grad_radial_colors, grad_radial_stops)
			if has_ang:
				var ang = rad_to_deg((p - _local_draw_center).angle())
				var diff = ang - mid_angle
				# Normalize difference to [-180, 180]
				while diff < -180.0: diff += 360.0
				while diff > 180.0: diff -= 360.0
				
				# Map from -1.0 to 1.0 based on distance from midpoint
				var t = clampf((diff / half_span) * 0.5 + 0.5, 0.0, 1.0)
				c_ang = _sample_custom_gradient(t, grad_angular_colors, grad_angular_stops)
				
			if has_rad and has_ang:
				match blend_mode:
					BlendMode.MIX: c = c_rad.lerp(c_ang, blend_ratio)
					BlendMode.ADD: c = c_rad + c_ang
					BlendMode.MULTIPLY: c = c_rad * c_ang
			elif has_rad:
				c = c_rad
			elif has_ang:
				c = c_ang
				
		c.a *= slice_alpha
		cols[i] = c

	draw_polygon(pts, cols)

	if focus_amount > 0.001 and focus_tint.a > 0.001:
		var tint_cols := PackedColorArray()
		tint_cols.resize(pts.size())
		var final_tint := Color(focus_tint.r, focus_tint.g, focus_tint.b, focus_tint.a * focus_amount * slice_alpha)
		tint_cols.fill(final_tint)
		draw_polygon(pts, tint_cols)

	if stroke_width > 0.01 and pts.size() >= 2:
		var closed_pts := pts.duplicate()
		closed_pts.append(pts[0])
		var stroke_c := stroke_color
		stroke_c.a *= slice_alpha
		draw_polyline(closed_pts, stroke_c, stroke_width, true)

# --- Geometry & Layout Update ---
func _update_geometry() -> void:
	if span_angle <= 0.01 or not is_inside_tree(): return
	_calculate_geometry()
	_layout_children()

func _calculate_geometry() -> void:
	var bisector := deg_to_rad(start_angle + span_angle * 0.5)
	var total_offset := global_explode + explode_offset + (focus_offset * focus_amount)
	var s_scale := lerpf(1.0, focus_scale, focus_amount)
	
	var draw_center_parent := chart_center + Vector2(cos(bisector), sin(bisector)) * total_offset
	var available_r := base_outer_r - base_inner_r
	var draw_outer := maxf(0.0, base_inner_r + available_r * height_ratio) * s_scale
	var draw_inner := maxf(0.0, base_inner_r) * s_scale
	
	var pts_parent := _build_wedge_polygon(draw_center_parent, draw_outer, draw_inner)
	if pts_parent.is_empty(): return
		
	var aabb := Rect2(pts_parent[0], Vector2.ZERO)
	for i in range(1, pts_parent.size()):
		aabb = aabb.expand(pts_parent[i])
		
	self.position = aabb.position
	self.size = aabb.size
	
	_local_draw_center = draw_center_parent - aabb.position
	_local_draw_outer = draw_outer
	_local_draw_inner = draw_inner

func _layout_children() -> void:
	var bisector := deg_to_rad(start_angle + span_angle * 0.5)
	var s_scale := lerpf(1.0, focus_scale, focus_amount)
	
	var mid_r := (_local_draw_outer + _local_draw_inner) * 0.5
	var drawn_slice_center_local := _local_draw_center + Vector2(cos(bisector), sin(bisector)) * mid_r
	var drawn_outer_edge_local := _local_draw_center + Vector2(cos(bisector), sin(bisector)) * _local_draw_outer
	
	var target_pos := Vector2.ZERO
	match content_anchor:
		ContentAnchor.CHART_CENTER: target_pos = _local_draw_center
		ContentAnchor.SLICE_CENTER: target_pos = drawn_slice_center_local
		ContentAnchor.SLICE_OUTER: target_pos = drawn_outer_edge_local
		
	var target_rot := 0.0
	match content_rotation:
		ContentRotation.NONE: target_rot = 0.0
		ContentRotation.ALIGN_SLICE: target_rot = bisector
		ContentRotation.TANGENT_SLICE: target_rot = bisector + PI * 0.5
		
	target_pos += content_offset.rotated(target_rot)
	
	var R_target := target_pos.distance_to(_local_draw_center)
	var safe_w := 2.0 * R_target * sin(deg_to_rad(minf(span_angle, 179.0) * 0.5))
	var safe_h := _local_draw_outer - _local_draw_inner
	safe_w = minf(safe_w, 2.0 * _local_draw_outer)
	if safe_w < 1.0: safe_w = self.size.x 
	if safe_h < 1.0: safe_h = self.size.y
		
	for c in get_children():
		var ctrl := c as Control
		if not ctrl: continue
		if ctrl is SliceBar: continue
		
		ctrl.set_anchors_preset(Control.PRESET_TOP_LEFT)
		var min_size: Vector2 = ctrl.get_combined_minimum_size()
		var final_size: Vector2 = min_size
		var rect_pos := Vector2.ZERO
		var pivot := Vector2.ZERO
		
		match content_size_mode_h:
			SizeMode.EXPAND:
				final_size.x = maxf(min_size.x, safe_w)
				rect_pos.x = target_pos.x - final_size.x * 0.5
				pivot.x = final_size.x * 0.5
			SizeMode.SHRINK_CENTER:
				rect_pos.x = target_pos.x - final_size.x * 0.5
				pivot.x = final_size.x * 0.5
			SizeMode.SHRINK_END:
				rect_pos.x = target_pos.x - final_size.x
				pivot.x = final_size.x
			SizeMode.SHRINK_BEGIN:
				rect_pos.x = target_pos.x
				pivot.x = 0.0
					
		match content_size_mode_v:
			SizeMode.EXPAND:
				final_size.y = maxf(min_size.y, safe_h)
				rect_pos.y = target_pos.y - final_size.y * 0.5
				pivot.y = final_size.y * 0.5
			SizeMode.SHRINK_CENTER:
				rect_pos.y = target_pos.y - final_size.y * 0.5
				pivot.y = final_size.y * 0.5
			SizeMode.SHRINK_END:
				rect_pos.y = target_pos.y - final_size.y
				pivot.y = final_size.y
			SizeMode.SHRINK_BEGIN:
				rect_pos.y = target_pos.y
				pivot.y = 0.0
					
		ctrl.size = final_size
		ctrl.position = rect_pos
		ctrl.pivot_offset = pivot
		ctrl.rotation = target_rot
		
		if content_scales_with_slice:
			ctrl.scale = Vector2(s_scale, s_scale)
		else:
			ctrl.scale = Vector2.ONE

# --- Geometry Math ---
func _build_wedge_polygon(draw_center: Vector2, draw_outer: float, draw_inner: float) -> PackedVector2Array:
	var a0 := deg_to_rad(start_angle)
	var a1 := deg_to_rad(start_angle + span_angle)
	
	var pts := PackedVector2Array()
	if draw_outer <= 0 or a1 <= a0: return pts

	var half_span := a1 - a0
	var max_cr_radial := (draw_outer - draw_inner) * 0.5
	var max_cr_angular_out := draw_outer * sin(half_span * 0.5)
	var max_cr_out := minf(corner_radius, minf(max_cr_radial, max_cr_angular_out))
	
	var max_cr_in := 0.0
	if draw_inner > 0.0:
		max_cr_in = minf(inner_corner_radius, minf(max_cr_radial, draw_inner * sin(half_span * 0.5)))
	
	max_cr_out = maxf(0.0, max_cr_out)
	max_cr_in = maxf(0.0, max_cr_in)

	var delta_out := asin(clamp(max_cr_out / (draw_outer - max_cr_out), -1.0, 1.0)) if max_cr_out > 0.0 else 0.0
	var c_out_start: Vector2 = draw_center + Vector2(cos(a0 + delta_out), sin(a0 + delta_out)) * (draw_outer - max_cr_out)
	var p_radial_out_start: Vector2 = draw_center + Vector2(cos(a0), sin(a0)) * ((draw_outer - max_cr_out) * cos(delta_out))
	var p_arc_out_start: Vector2 = draw_center + Vector2(cos(a0 + delta_out), sin(a0 + delta_out)) * draw_outer

	var c_out_end: Vector2 = draw_center + Vector2(cos(a1 - delta_out), sin(a1 - delta_out)) * (draw_outer - max_cr_out)
	var p_radial_out_end: Vector2 = draw_center + Vector2(cos(a1), sin(a1)) * ((draw_outer - max_cr_out) * cos(delta_out))
	var p_arc_out_end: Vector2 = draw_center + Vector2(cos(a1 - delta_out), sin(a1 - delta_out)) * draw_outer

	var delta_in := 0.0
	var c_in_start: Vector2 = draw_center
	var p_radial_in_start: Vector2 = draw_center
	var p_arc_in_start: Vector2 = draw_center
	var c_in_end: Vector2 = draw_center
	var p_radial_in_end: Vector2 = draw_center
	var p_arc_in_end: Vector2 = draw_center

	if draw_inner > 0.0:
		delta_in = asin(clamp(max_cr_in / (draw_inner + max_cr_in), -1.0, 1.0)) if max_cr_in > 0.0 else 0.0
		c_in_start = draw_center + Vector2(cos(a0 + delta_in), sin(a0 + delta_in)) * (draw_inner + max_cr_in)
		p_radial_in_start = draw_center + Vector2(cos(a0), sin(a0)) * ((draw_inner + max_cr_in) * cos(delta_in))
		p_arc_in_start = draw_center + Vector2(cos(a0 + delta_in), sin(a0 + delta_in)) * draw_inner

		c_in_end = draw_center + Vector2(cos(a1 - delta_in), sin(a1 - delta_in)) * (draw_inner + max_cr_in)
		p_radial_in_end = draw_center + Vector2(cos(a1), sin(a1)) * ((draw_inner + max_cr_in) * cos(delta_in))
		p_arc_in_end = draw_center + Vector2(cos(a1 - delta_in), sin(a1 - delta_in)) * draw_inner

	if draw_inner > 0.0:
		pts.append(p_radial_in_start)
		pts.append(p_radial_out_start)
		if max_cr_out > 0.0: _add_arc_between(pts, c_out_start, p_radial_out_start, p_arc_out_start)
		_add_arc(pts, draw_center, draw_outer, a0 + delta_out, a1 - delta_out)
		if max_cr_out > 0.0: _add_arc_between(pts, c_out_end, p_arc_out_end, p_radial_out_end)
		pts.append(p_radial_out_end)
		pts.append(p_radial_in_end)
		if max_cr_in > 0.0: _add_arc_between(pts, c_in_end, p_radial_in_end, p_arc_in_end)
		_add_arc(pts, draw_center, draw_inner, a1 - delta_in, a0 + delta_in)
		if max_cr_in > 0.0: _add_arc_between(pts, c_in_start, p_arc_in_start, p_radial_in_start)
	else:
		pts.append(draw_center)
		pts.append(p_radial_out_start)
		if max_cr_out > 0.0: _add_arc_between(pts, c_out_start, p_radial_out_start, p_arc_out_start)
		_add_arc(pts, draw_center, draw_outer, a0 + delta_out, a1 - delta_out)
		if max_cr_out > 0.0: _add_arc_between(pts, c_out_end, p_arc_out_end, p_radial_out_end)
		pts.append(p_radial_out_end)
		pts.append(draw_center)

	return pts

func _add_arc(pts: PackedVector2Array, c: Vector2, radius: float, start_rad: float, end_rad: float) -> void:
	var diff := end_rad - start_rad
	while diff > PI: diff -= TAU
	while diff < -PI: diff += TAU
	var steps := maxi(2, int(abs(diff) / 0.1))
	for i in range(1, steps + 1):
		var a := start_rad + diff * (float(i) / float(steps))
		pts.append(c + Vector2(cos(a), sin(a)) * radius)

func _add_arc_between(pts: PackedVector2Array, c: Vector2, p1: Vector2, p2: Vector2) -> void:
	var a1 := (p1 - c).angle()
	var a2 := (p2 - c).angle()
	var radius := p1.distance_to(c)
	_add_arc(pts, c, radius, a1, a2)

# --- Hit-testing ---
func _is_point_inside_wedge(p: Vector2) -> bool:
	var local_p := p - _local_draw_center
	var dist := local_p.length()
	if dist < _local_draw_inner or dist > _local_draw_outer: return false
	var ang := rad_to_deg(local_p.angle())
	var a := fmod(ang - start_angle, 360.0)
	if a < 0.0: a += 360.0
	return a <= span_angle

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _is_point_inside_wedge(event.position):
			var parent := get_parent()
			if parent.has_method("_on_slice_clicked"): parent._on_slice_clicked(self)
			get_viewport().set_input_as_handled()
