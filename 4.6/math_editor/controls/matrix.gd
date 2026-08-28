@tool
class_name MatrixControl
extends MathContainer

## Visual control for grid-based layouts (Matrices, Cases, Arrays, Aligns).

var columns: int = 1
var matrix_type: String = "matrix"
var col_def: String = ""
var hlines: Array[int] = [] 

var _context: RenderContext
var _col_widths: Array[float] = []
var _haligns: Array[String] = []
var _vlines_x: Array[float] = [] # Exact X-coordinates for vertical lines

func measure(context: RenderContext) -> void:
	_context = context
	super.measure(context)
	
	_setup_alignments()
	
	var children_list = get_children()
	var rows = int(ceil(float(children_list.size()) / float(columns)))
	
	_col_widths.clear()
	_col_widths.resize(columns)
	for i in columns: _col_widths[i] = 0.0
	
	var row_heights = []
	var row_baselines = []
	row_heights.resize(rows)
	row_baselines.resize(rows)
	for i in rows: row_heights[i] = 0.0; row_baselines[i] = 0.0
	
	var font_size = context.get_font_size()
	var h_spacing = font_size * 1.5 if matrix_type == "align" else font_size * 0.8
	var v_spacing = font_size * 0.2
	var bracket_width = font_size * 0.3
	var padding = font_size * 0.1
	
	var left_padding = 0.0
	var right_padding = 0.0
	if matrix_type in ["cases", "pmatrix", "bmatrix", "Bmatrix", "vmatrix", "Vmatrix"]:
		left_padding = bracket_width + padding * 2.0
		right_padding = left_padding if matrix_type != "cases" else 0.0
	elif matrix_type == "array": 
		left_padding = padding
		right_padding = padding
	
	for i in range(children_list.size()):
		var child = children_list[i]
		if child is MathElement:
			var r = i / columns
			var c = i % columns
			var child_w = child.measured_size.x
			if matrix_type == "cases" and c == 0:
				child_w += _get_operator_padding(child, context)
			_col_widths[c] = max(_col_widths[c], child_w)
			
			var child_h = child.measured_size.y
			if child_h > row_heights[r]:
				row_heights[r] = child_h
				row_baselines[r] = child.baseline
				
	var total_w = left_padding + right_padding
	for w in _col_widths:
		total_w += w + h_spacing
	total_w -= h_spacing
	
	var total_h = 0.0
	for h_val in row_heights:
		total_h += h_val + v_spacing
	total_h -= v_spacing
	
	measured_size.x = total_w
	measured_size.y = total_h
	baseline = total_h / 2.0
	
	custom_minimum_size = measured_size
	size = measured_size

func arrange(context: RenderContext, pos: Vector2) -> void:
	super.arrange(context, pos)
	
	var children_list = get_children()
	var rows = int(ceil(float(children_list.size()) / float(columns)))
	
	var row_heights = []
	var row_baselines = []
	row_heights.resize(rows)
	row_baselines.resize(rows)
	for i in rows: row_heights[i] = 0.0; row_baselines[i] = 0.0
	
	var font_size = context.get_font_size()
	var h_spacing = font_size * 1.5 if matrix_type == "align" else font_size * 0.8
	var bracket_width = font_size * 0.3
	var padding = font_size * 0.1
	
	var left_padding = 0.0
	if matrix_type in ["cases", "pmatrix", "bmatrix", "Bmatrix", "vmatrix", "Vmatrix"]:
		left_padding = bracket_width + padding * 2.0
	elif matrix_type == "array":
		left_padding = padding
		
	for i in range(children_list.size()):
		var child = children_list[i]
		if child is MathElement:
			var r = i / columns
			var c = i % columns
			var child_w = child.measured_size.x
			if matrix_type == "cases" and c == 0:
				child_w += _get_operator_padding(child, context)
			if child_w > _col_widths[c]: _col_widths[c] = child_w
			if child.measured_size.y > row_heights[r]:
				row_heights[r] = child.measured_size.y
				row_baselines[r] = child.baseline
				
	var current_y = 0.0
	for r in range(rows):
		var current_x = left_padding
		var row_baseline = row_baselines[r]
		for c in range(columns):
			var idx = r * columns + c
			if idx < children_list.size():
				var child = children_list[idx]
				if child is MathElement:
					var cell_x = current_x
					var align = "c"
					if c < _haligns.size(): align = _haligns[c]
					
					if align == "l":
						if matrix_type == "cases" and c == 0:
							cell_x += _get_operator_padding(child, context)
					elif align == "r":
						cell_x += _col_widths[c] - child.measured_size.x
					else: 
						if matrix_type != "cases":
							cell_x += (_col_widths[c] - child.measured_size.x) / 2.0
							
					var cell_y = current_y + (row_baseline - child.baseline)
					child.arrange(context, Vector2(cell_x, cell_y))
			current_x += _col_widths[c] + h_spacing
		current_y += row_heights[r] + (font_size * 0.2)

func _setup_alignments() -> void:
	_haligns.clear()
	_vlines_x.clear()
	
	var font_size = _context.get_font_size()
	var h_spacing = font_size * 1.5 if matrix_type == "align" else font_size * 0.8
	var padding = font_size * 0.1
	var bracket_width = font_size * 0.3
	
	var left_padding = 0.0
	if matrix_type in ["cases", "pmatrix", "bmatrix", "Bmatrix", "vmatrix", "Vmatrix"]:
		left_padding = bracket_width + padding * 2.0
	elif matrix_type == "array":
		left_padding = padding
		
	if matrix_type == "align":
		for i in range(columns):
			_haligns.append("r" if i % 2 == 0 else "l")
		return
		
	if matrix_type == "cases":
		for i in range(columns):
			_haligns.append("l")
		return
		
	if not col_def.is_empty():
		var current_x = left_padding
		var expect_vline = false
		
		# Check for leading | (left border)
		if col_def.begins_with("|"):
			_vlines_x.append(0.0)
			
		for ch in col_def:
			if ch in ["l", "c", "r"]:
				_haligns.append(ch)
				current_x += _col_widths[_haligns.size() - 1] + h_spacing
			elif ch == "|":
				# The line goes exactly in the middle of the gap
				_vlines_x.append(current_x - (h_spacing / 2.0))
				
		# Check for trailing | (right border)
		if col_def.ends_with("|"):
			_vlines_x[-1] = measured_size.x
	else:
		for i in range(columns):
			_haligns.append("c")

func _get_operator_padding(node: Node, context: RenderContext) -> float:
	if not context or not context.font: return 0.0
	var starts_with_op = false
	if node is SequenceControl:
		if node.get_child_count() > 0:
			var first = node.get_child(0)
			if first is SymbolControl and first.is_operator: starts_with_op = true
	elif node is SymbolControl:
		if node.is_operator: starts_with_op = true
	if starts_with_op: return 0.0
	var font = context.font
	var size = context.get_font_size()
	var op_w = FontMetrics.get_text_size("-", font, size).x
	var sp_w = FontMetrics.get_text_size(" ", font, size).x * context.item_spacing
	return op_w + sp_w

func _draw() -> void:
	if not _context: return
		
	var children_list = get_children()
	var rows = int(ceil(float(children_list.size()) / float(columns)))
	var row_heights = []
	row_heights.resize(rows)
	for i in rows: row_heights[i] = 0.0
	
	for i in range(children_list.size()):
		var child = children_list[i]
		if child is MathElement:
			var r = i / columns
			if child.measured_size.y > row_heights[r]:
				row_heights[r] = child.measured_size.y
				
	var font_size = _context.get_font_size()
	var bracket_width = font_size * 0.3
	var padding = font_size * 0.1
	var line_thick = font_size * _context.line_thickness
	var left_x = padding + (bracket_width * 0.5)
	var right_x = measured_size.x - padding - (bracket_width * 0.5)
	var h = measured_size.y
	var h_spacing = font_size * 1.5 if matrix_type == "align" else font_size * 0.8
	var v_spacing = font_size * 0.2
	
	match matrix_type:
		"cases": BracketDrawer.draw_bracket(self, "{", Vector2(left_x, 0), h, bracket_width, line_thick, _context.color, true)
		"pmatrix":
			BracketDrawer.draw_bracket(self, "(", Vector2(left_x, 0), h, bracket_width, line_thick, _context.color, true)
			BracketDrawer.draw_bracket(self, ")", Vector2(right_x, 0), h, bracket_width, line_thick, _context.color, false)
		"bmatrix":
			BracketDrawer.draw_bracket(self, "[", Vector2(left_x, 0), h, bracket_width, line_thick, _context.color, true)
			BracketDrawer.draw_bracket(self, "]", Vector2(right_x, 0), h, bracket_width, line_thick, _context.color, false)
		"Bmatrix":
			BracketDrawer.draw_bracket(self, "{", Vector2(left_x, 0), h, bracket_width, line_thick, _context.color, true)
			BracketDrawer.draw_bracket(self, "}", Vector2(right_x, 0), h, bracket_width, line_thick, _context.color, false)
		"vmatrix":
			BracketDrawer.draw_bracket(self, "|", Vector2(left_x, 0), h, bracket_width, line_thick, _context.color, true)
			BracketDrawer.draw_bracket(self, "|", Vector2(right_x, 0), h, bracket_width, line_thick, _context.color, false)
		"Vmatrix":
			BracketDrawer.draw_bracket(self, "|", Vector2(left_x - bracket_width*0.4, 0), h, bracket_width, line_thick, _context.color, true)
			BracketDrawer.draw_bracket(self, "|", Vector2(left_x + bracket_width*0.4, 0), h, bracket_width, line_thick, _context.color, true)
			BracketDrawer.draw_bracket(self, "|", Vector2(right_x - bracket_width*0.4, 0), h, bracket_width, line_thick, _context.color, false)
			BracketDrawer.draw_bracket(self, "|", Vector2(right_x + bracket_width*0.4, 0), h, bracket_width, line_thick, _context.color, false)
		"array":
			# Draw vertical lines using exact pre-calculated X-coordinates
			for line_x in _vlines_x:
				draw_line(Vector2(line_x, 0), Vector2(line_x, h), _context.color, line_thick)
				
			# Draw horizontal lines (\hline)
			if not hlines.is_empty():
				var current_y = 0.0
				for r in range(rows + 1):
					if hlines.has(r):
						var line_y = current_y
						if r == rows: 
							line_y = h 
						draw_line(Vector2(0, line_y), Vector2(measured_size.x, line_y), _context.color, line_thick)
					if r < rows:
						current_y += row_heights[r] + v_spacing
