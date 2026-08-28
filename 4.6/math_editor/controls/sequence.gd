@tool
class_name SequenceControl
extends MathContainer

## Visual control for a horizontal sequence of math elements.

var _context: RenderContext

func measure(context: RenderContext) -> void:
	_context = context
	super.measure(context)
	
	var total_width := 0.0
	var max_ascent := 0.0
	var max_descent := 0.0
	var font_size = context.get_font_size()
	
	var children_list = get_children()
	for i in range(children_list.size()):
		var child = children_list[i]
		if child is MathElement:
			if i > 0:
				var prev = children_list[i - 1]
				total_width += _get_spacing(prev, child, font_size)
				
			total_width += child.measured_size.x
			max_ascent = max(max_ascent, child.baseline)
			max_descent = max(max_descent, child.measured_size.y - child.baseline)
			
	measured_size = Vector2(total_width, max_ascent + max_descent)
	baseline = max_ascent
	
	custom_minimum_size = measured_size
	size = measured_size

func arrange(context: RenderContext, pos: Vector2) -> void:
	super.arrange(context, pos)
	
	var current_x := 0.0
	var font_size = context.get_font_size()
	
	var children_list = get_children()
	for i in range(children_list.size()):
		var child = children_list[i]
		if child is MathElement:
			if i > 0:
				var prev = children_list[i - 1]
				current_x += _get_spacing(prev, child, font_size)
				
			var child_y = baseline - child.baseline
			child.arrange(context, Vector2(current_x, child_y))
			current_x += child.measured_size.x

# FIX: Removed arbitrary multipliers. Spacing is now exactly what the user sets.
func _get_spacing(prev: Node, curr: Node, font_size: float) -> float:
	var base_spacing = font_size * _context.item_spacing
	
	# Only relations (like =, <, >) get slightly more space (1.5x) for standard typography
	if _is_relation(prev) or _is_relation(curr):
		return base_spacing * 1.5
		
	# All other operators (+, -, \sum, \int) use the exact value specified
	return base_spacing

func _is_relation(node: Node) -> bool:
	if node is SymbolControl:
		if node.latex_cmd in ["=", "<", ">", "\\leq", "\\geq", "\\to", "\\rightarrow", "\\Rightarrow", "\\approx", "\\equiv"]:
			return true
		if node.text in ["=", "<", ">", "≤", "≥", "→", "⇒", "≈", "≡"]:
			return true
	return false
