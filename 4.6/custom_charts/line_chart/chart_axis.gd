@tool
class_name ChartAxis
extends Container

## A container that distributes its children along an axis.
## Children will automatically snap to the chart's background grid lines.

enum AlignmentMode {
	BOTTOM, ## Horizontal, left to right
	TOP,    ## Horizontal, left to right
	LEFT,   ## Vertical, bottom to top
	RIGHT   ## Vertical, bottom to top
}

@export var alignment: AlignmentMode = AlignmentMode.BOTTOM :
	set(v):
		alignment = v
		queue_sort()

var _chart_subdivs := 0

func _notification(what: int) -> void:
	if what == NOTIFICATION_CHILD_ORDER_CHANGED or what == NOTIFICATION_SORT_CHILDREN:
		_sort_axis()

func set_chart_subdivs(subdivs: int) -> void:
	if _chart_subdivs != subdivs:
		_chart_subdivs = subdivs
		queue_sort()

func _sort_axis() -> void:
	var items: Array[Control] = []
	for c in get_children():
		if c is Control: items.append(c as Control)
	if items.is_empty(): return
	
	var count := items.size()
	var grid_points := _chart_subdivs + 1 if (_chart_subdivs > 0 and count <= _chart_subdivs + 1) else count
	
	var is_horizontal := (alignment == AlignmentMode.BOTTOM or alignment == AlignmentMode.TOP)
	
	if is_horizontal:
		if count == 1:
			var c := items[0]
			var cmin := c.get_combined_minimum_size()
			c.size = cmin
			c.position = Vector2((size.x - cmin.x) * 0.5, (size.y - cmin.y) * 0.5)
			return
			
		var step := size.x / float(grid_points - 1) if grid_points > 1 else 0.0
		for i in range(count):
			var c := items[i]
			var cmin := c.get_combined_minimum_size()
			c.size = cmin
			var grid_idx := i
			if grid_points != count:
				grid_idx = int(round(float(i) * float(grid_points - 1) / float(count - 1)))
			var px := step * grid_idx
			c.position = Vector2(px - cmin.x * 0.5, (size.y - cmin.y) * 0.5)
	else:
		if count == 1:
			var c := items[0]
			var cmin := c.get_combined_minimum_size()
			c.size = cmin
			c.position = Vector2((size.x - cmin.x) * 0.5, (size.y - cmin.y) * 0.5)
			return
			
		var step := size.y / float(grid_points - 1) if grid_points > 1 else 0.0
		for i in range(count):
			var c := items[i]
			var cmin := c.get_combined_minimum_size()
			c.size = cmin
			var grid_idx := i
			if grid_points != count:
				grid_idx = int(round(float(i) * float(grid_points - 1) / float(count - 1)))
			var py := size.y - (step * grid_idx)
			c.position = Vector2((size.x - cmin.x) * 0.5, py - cmin.y * 0.5)
