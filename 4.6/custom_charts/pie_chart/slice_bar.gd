@tool
class_name SliceBar
extends PieSlice

## A single bar within a SliceBars container.
## Its boundaries (start_angle, span_angle, base radii) are driven dynamically by its parent.
## Its `height_ratio` tells the parent how much of the total stack it should occupy.

var _driven_by_parent := false

# If ANY property changes, we must tell the parent SliceBars to recalculate the whole stack!
# This fixes the realtime update issue.
func _update_geometry() -> void:
	if _driven_by_parent:
		# We are being updated by the parent, so just calculate our own drawing
		_calculate_geometry()
		_layout_children()
		return
		
	if not is_inside_tree(): return
	var parent_bars := get_parent() as SliceBars
	if parent_bars:
		parent_bars._update_geometry()
	else:
		super._update_geometry()

# Override to draw exactly from base_inner_r to base_outer_r.
# We ignore the local height_ratio here because the parent already used it to calculate the segment size.
func _calculate_geometry() -> void:
	var bisector := deg_to_rad(start_angle + span_angle * 0.5)
	
	# Apply the bar's own local explode and focus offset on top of the parent's center
	var total_offset := global_explode + explode_offset + (focus_offset * focus_amount)
	var s_scale := lerpf(1.0, focus_scale, focus_amount)
	
	var draw_center_parent := chart_center + Vector2(cos(bisector), sin(bisector)) * total_offset
	var draw_outer := maxf(0.0, base_outer_r) * s_scale
	var draw_inner := maxf(0.0, base_inner_r) * s_scale
	
	var pts_parent := _build_wedge_polygon(draw_center_parent, draw_outer, draw_inner)
	if pts_parent.is_empty():
		return
		
	var aabb := Rect2(pts_parent[0], Vector2.ZERO)
	for i in range(1, pts_parent.size()):
		aabb = aabb.expand(pts_parent[i])
		
	self.position = aabb.position
	self.size = aabb.size
	
	_local_draw_center = draw_center_parent - aabb.position
	_local_draw_outer = draw_outer
	_local_draw_inner = draw_inner
