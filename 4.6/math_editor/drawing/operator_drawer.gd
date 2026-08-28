@tool
class_name OperatorDrawer
extends RefCounted

## Static utility for drawing mathematical vector graphics.

static func draw_fraction_line(canvas: CanvasItem, pos: Vector2, width: float, thickness: float, color: Color) -> void:
	var rect = Rect2(pos, Vector2(width, thickness))
	canvas.draw_rect(rect, color)

static func draw_root_sign(
		canvas: CanvasItem, 
		hook_x: float, 
		bar_end_x: float, 
		top_y: float, 
		bottom_y: float, 
		hook_width: float, 
		thickness: float, 
		color: Color) -> void:
		
	var p1 = Vector2(hook_x, top_y)
	var p2 = Vector2(hook_x + (hook_width * 0.5), bottom_y)
	var p3 = Vector2(hook_x + hook_width, top_y)
	var p4 = Vector2(bar_end_x, top_y)
	
	canvas.draw_polyline(PackedVector2Array([p1, p2, p3]), color, thickness, true)
	canvas.draw_line(p3, p4, color, thickness, true)

# FIX: Line stops at the base of the cape, tip extends slightly further
static func draw_vec_arrow(canvas: CanvasItem, pos: Vector2, width: float, thickness: float, color: Color) -> void:
	var ah = max(thickness * 5.0, 8.0)
	
	# Slightly extend the total length of the arrow so it looks complete
	var tip_x = pos.x + width + (ah * 0.2)
	var base_x = tip_x - ah
	
	# The line starts at pos.x and stops exactly where the cape begins
	var start = Vector2(pos.x, pos.y)
	var line_end = Vector2(base_x, pos.y)
	canvas.draw_line(start, line_end, color, thickness, true)
	
	# Draw the cape (arrowhead) starting exactly at line_end
	var tip = Vector2(tip_x, pos.y)
	var p2 = Vector2(base_x, pos.y - ah * 0.6)
	var p3 = Vector2(base_x, pos.y + ah * 0.6)
	var points = PackedVector2Array([tip, p2, p3])
	canvas.draw_polygon(points, PackedColorArray([color, color, color]))

static func draw_hat(canvas: CanvasItem, pos: Vector2, width: float, thickness: float, color: Color) -> void:
	var h = width * 0.4
	var p1 = Vector2(pos.x, pos.y + h)
	var p2 = Vector2(pos.x + width / 2.0, pos.y)
	var p3 = Vector2(pos.x + width, pos.y + h)
	var points = PackedVector2Array([p1, p2, p3])
	canvas.draw_polyline(points, color, thickness, true)
