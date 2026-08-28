@tool
class_name PieChartAxis
extends Container

## A container that distributes its children around a PieChart.
## height_ratio: 0.0 = center, 1.0 = outer circumference.

@export_range(-360.0, 360.0, 0.1) var start_angle: float = -90.0 :
	set(v):
		start_angle = v
		_sort_axis()

@export_range(0.0, 1.0, 0.01) var height_ratio: float = 1.0 :
	set(v):
		height_ratio = v
		_sort_axis()

var _chart_center := Vector2.ZERO
var _chart_outer_r := 0.0

func set_chart_geometry(center: Vector2, outer_r: float, inner_r: float) -> void:
	_chart_center = center
	_chart_outer_r = outer_r
	_sort_axis()

func _notification(what: int) -> void:
	if what == NOTIFICATION_CHILD_ORDER_CHANGED or what == NOTIFICATION_SORT_CHILDREN:
		_sort_axis()

func _sort_axis() -> void:
	var items: Array[Control] = []
	for c in get_children():
		if c is Control: items.append(c as Control)
	if items.is_empty(): return
	
	var count := items.size()
	var step := 360.0 / count
	
	var r_offset := _chart_outer_r * height_ratio
	
	for i in range(count):
		var c := items[i]
		var cmin := c.get_combined_minimum_size()
		c.size = cmin
		var angle := deg_to_rad(start_angle + step * i)
		var px := _chart_center.x + cos(angle) * r_offset
		var py := _chart_center.y + sin(angle) * r_offset
		c.position = Vector2(px - cmin.x * 0.5, py - cmin.y * 0.5)
