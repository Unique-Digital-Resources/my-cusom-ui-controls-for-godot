@tool
class_name BracketDrawer
extends RefCounted

## Static utility for drawing scalable vector brackets, braces, and pipes.

static func draw_bracket(
		canvas: CanvasItem, 
		bracket_char: String, 
		pos: Vector2, 
		height: float, 
		width: float, 
		thickness: float, 
		color: Color, 
		is_left: bool) -> void:
		
	var top_y = pos.y
	var mid_y = pos.y + (height * 0.5)
	var bot_y = pos.y + height
	var x = pos.x
	
	var dir = 1.0 if is_left else -1.0
	
	match bracket_char:
		"(", ")":
			var p1 = Vector2(x + (dir * width * 0.5), top_y)
			var p2 = Vector2(x, top_y + (height * 0.2))
			var p3 = Vector2(x, bot_y - (height * 0.2))
			var p4 = Vector2(x + (dir * width * 0.5), bot_y)
			var points = PackedVector2Array([p1, p2, p3, p4])
			canvas.draw_polyline(points, color, thickness, true)
			
		"[", "]":
			var p1 = Vector2(x + (dir * width * 0.5), top_y)
			var p2 = Vector2(x, top_y)
			var p3 = Vector2(x, bot_y)
			var p4 = Vector2(x + (dir * width * 0.5), bot_y)
			var points = PackedVector2Array([p1, p2, p3, p4])
			canvas.draw_polyline(points, color, thickness, true)
			
		"{", "}":
			# Enhanced curly brace shape
			var tip_x = x + (dir * width * 0.5)
			var pinch_x = x + (dir * width * 0.8)
			var stem_x = x
			
			var p1 = Vector2(tip_x, top_y)
			var p2 = Vector2(stem_x, top_y + (height * 0.1))
			var p3 = Vector2(stem_x, mid_y - (height * 0.15))
			var p4 = Vector2(pinch_x, mid_y - (height * 0.02))
			var p5 = Vector2(pinch_x, mid_y + (height * 0.02))
			var p6 = Vector2(stem_x, mid_y + (height * 0.15))
			var p7 = Vector2(stem_x, bot_y - (height * 0.1))
			var p8 = Vector2(tip_x, bot_y)
			
			var points = PackedVector2Array([p1, p2, p3, p4, p5, p6, p7, p8])
			canvas.draw_polyline(points, color, thickness, true)
			
		"|":
			canvas.draw_line(Vector2(x, top_y), Vector2(x, bot_y), color, thickness, true)
