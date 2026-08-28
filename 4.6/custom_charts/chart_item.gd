@tool
class_name ChartItem
extends Control

## Base class for chart items (slices, bars, points...).

@export_group("Data")
## Relative share (proportional=true) or direct percentage (proportional=false).
@export var value: float = 1.0 :
	set(v): value = v; _request_parent_sort()

@export_group("Focus")
## 0 = unfocused, 1 = focused. Animatable for smooth transitions.
@export_range(0.0, 1.0, 0.01) var focus_amount: float = 0.0 :
	set(v):
		focus_amount = clamp(v, 0.0, 1.0)
		queue_redraw()
		z_index = int(round(focus_amount)) # bring focused on top

## If true, the slice is always on top regardless of focus_amount.
@export var always_on_top: bool = false :
	set(v):
		always_on_top = v
		z_index = 99 if v else int(round(focus_amount))

func _request_parent_sort() -> void:
	queue_redraw()
	if is_inside_tree() and get_parent() is Container:
		get_parent().queue_sort()
