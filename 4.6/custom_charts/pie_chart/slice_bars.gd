@tool
class_name SliceBars
extends PieSlice

## A slice that acts as a container for SliceBar children, 
## stacking them radially from the inner radius outwards.
## Each bar takes the full angular span, and its height_ratio determines its share of the stack.

@export_group("Bars Layout")
## Radial gap between stacked bars.
@export_range(0.0, 20.0, 0.1, "suffix:px") var bar_gap: float = 2.0 :
	set(v): bar_gap = v; _update_geometry()

# Override to act as a transparent container. 
# We don't want to resize SliceBars itself to its wedge AABB, we just need its local draw center.
func _calculate_geometry() -> void:
	var bisector := deg_to_rad(start_angle + span_angle * 0.5)
	var total_offset := global_explode + explode_offset + (focus_offset * focus_amount)
	
	var available_r := (base_outer_r - base_inner_r) * height_ratio
	
	# Calculate center relative to THIS node's local space so children position correctly
	_local_draw_center = (chart_center - position) + Vector2(cos(bisector), sin(bisector)) * total_offset
	_local_draw_outer = base_inner_r + available_r
	_local_draw_inner = base_inner_r

func _layout_children() -> void:
	var bars := _get_bars()
	if bars.is_empty():
		# If no bars, fallback to standard behavior for regular controls
		super._layout_children()
		return
		
	var available_r := (base_outer_r - base_inner_r) * height_ratio
	var current_r := base_inner_r
	
	for bar in bars:
		var bar_height := available_r * bar.height_ratio
		var half_gap := bar_gap * 0.5
		
		# Prevent the bar from asking us to update again while we assign properties
		bar._driven_by_parent = true
		
		# Pass local geometry down. The bar will draw exactly within these bounds.
		bar.chart_center = _local_draw_center
		bar.start_angle = start_angle
		bar.span_angle = span_angle
		bar.corner_radius = corner_radius
		bar.inner_corner_radius = inner_corner_radius
		bar.global_explode = 0.0
		
		# Stack the radii: start where the previous bar ended
		bar.base_inner_r = current_r + half_gap
		bar.base_outer_r = current_r + bar_height - half_gap
		
		# Update the bar's geometry and its own children
		bar._calculate_geometry()
		bar._layout_children()
		
		# Re-enable normal updates for the bar
		bar._driven_by_parent = false
		
		# Move the cursor forward for the next bar
		current_r += bar_height

func _get_bars() -> Array[SliceBar]:
	var out: Array[SliceBar] = []
	for c in get_children():
		if c is SliceBar:
			out.append(c as SliceBar)
	return out
