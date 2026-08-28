@tool
class_name ChartContainer
extends Container

## Base class for all chart containers. Children must be ChartItem-derived.

@export_group("Layout")
@export_range(0, 256, 1.0, "suffix:px") var padding: float = 0.0 :
	set(v): padding = v; queue_sort()

@export_group("Distribution")
## true  -> each item's `value` is its share of the total.
## false -> `value` is treated as a direct percentage of 100.
@export var proportional: bool = true :
	set(v): proportional = v; queue_sort()

func _get_minimum_size() -> Vector2:
	return Vector2(64, 64)

func _get_configuration_warnings() -> PackedStringArray:
	var w := PackedStringArray()
	var has_item := false
	for c in get_children():
		if c is ChartItem:
			has_item = true
			break
	if not has_item:
		w.append("Add one or more ChartItem children (e.g. PieSlice).")
	return w

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_SORT_CHILDREN: _sort_chart_items()
		NOTIFICATION_RESIZED:       queue_sort()

func _sort_chart_items() -> void:
	push_warning("ChartContainer._sort_chart_items() not implemented.")

func _get_items() -> Array[ChartItem]:
	var out: Array[ChartItem] = []
	for c in get_children():
		if c is ChartItem and not c.is_set_as_top_level():
			out.append(c as ChartItem) # Explicit cast fixes engine warning
	return out

func _get_total_value() -> float:
	var total := 0.0
	for it in _get_items():
		total += it.value
	return total
