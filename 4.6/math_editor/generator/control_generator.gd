@tool
class_name ControlGenerator
extends RefCounted

## Generates the Control hierarchy from a MathAST.

const SequenceControlScript = preload("res://addons/math_editor/controls/sequence.gd")

static func generate(ast_root: MathAST) -> Control:
	if not ast_root:
		return null
	return _generate_node(ast_root)

static func _generate_node(ast_node: MathAST) -> Control:
	
	if ast_node.type == MathConstants.ElementType.SCRIPT:
		var script_ctrl = ControlFactory.create_control(ast_node)
		if ast_node.children.size() > 0 and ast_node.children[0]:
			var base_ctrl = _generate_node(ast_node.children[0])
			if base_ctrl: base_ctrl.name = "Base"; script_ctrl.add_child(base_ctrl)
		if ast_node.children.size() > 1 and ast_node.children[1]:
			var sup_ctrl = _generate_node(ast_node.children[1])
			if sup_ctrl: sup_ctrl.name = "Super"; script_ctrl.add_child(sup_ctrl)
		if ast_node.children.size() > 2 and ast_node.children[2]:
			var sub_ctrl = _generate_node(ast_node.children[2])
			if sub_ctrl: sub_ctrl.name = "Sub"; script_ctrl.add_child(sub_ctrl)
		return script_ctrl
		
	if ast_node.type == MathConstants.ElementType.UNDER_OVER:
		var uo_ctrl = ControlFactory.create_control(ast_node)
		if ast_node.children.size() > 0 and ast_node.children[0]:
			var base_ctrl = _generate_node(ast_node.children[0])
			if base_ctrl: base_ctrl.name = "Base"; uo_ctrl.add_child(base_ctrl)
		if ast_node.children.size() > 1 and ast_node.children[1]:
			var sup_ctrl = _generate_node(ast_node.children[1])
			if sup_ctrl: sup_ctrl.name = "Super"; uo_ctrl.add_child(sup_ctrl)
		if ast_node.children.size() > 2 and ast_node.children[2]:
			var sub_ctrl = _generate_node(ast_node.children[2])
			if sub_ctrl: sub_ctrl.name = "Sub"; uo_ctrl.add_child(sub_ctrl)
		return uo_ctrl
		
	if ast_node.type == MathConstants.ElementType.FRACTION:
		var frac_ctrl = ControlFactory.create_control(ast_node)
		if ast_node.children.size() > 0 and ast_node.children[0]:
			var num_ctrl = _generate_node(ast_node.children[0])
			if num_ctrl: num_ctrl.name = "Numerator"; frac_ctrl.add_child(num_ctrl)
		if ast_node.children.size() > 1 and ast_node.children[1]:
			var den_ctrl = _generate_node(ast_node.children[1])
			if den_ctrl: den_ctrl.name = "Denominator"; frac_ctrl.add_child(den_ctrl)
		return frac_ctrl
		
	if ast_node.type == MathConstants.ElementType.ROOT:
		var root_ctrl = ControlFactory.create_control(ast_node)
		if ast_node.children.size() > 0 and ast_node.children[0]:
			var idx_ctrl = _generate_node(ast_node.children[0])
			if idx_ctrl: idx_ctrl.name = "Index"; root_ctrl.add_child(idx_ctrl)
		if ast_node.children.size() > 1 and ast_node.children[1]:
			var rad_ctrl = _generate_node(ast_node.children[1])
			if rad_ctrl: rad_ctrl.name = "Radicand"; root_ctrl.add_child(rad_ctrl)
		return root_ctrl
		
	if ast_node.type == MathConstants.ElementType.FENCED:
		var fenced_ctrl = ControlFactory.create_control(ast_node)
		if ast_node.children.size() > 0 and ast_node.children[0]:
			var content_ctrl = _generate_node(ast_node.children[0])
			if content_ctrl: content_ctrl.name = "Content"; fenced_ctrl.add_child(content_ctrl)
		return fenced_ctrl
		
	if ast_node.type == MathConstants.ElementType.MATRIX:
		var matrix_ctrl = ControlFactory.create_control(ast_node)
		matrix_ctrl.columns = int(ast_node.get_meta("columns", 1))
		matrix_ctrl.matrix_type = String(ast_node.get_meta("matrix_type", "matrix"))
		matrix_ctrl.col_def = String(ast_node.get_meta("col_def", ""))
		
		# NEW: Pass hlines array
		var hlines_data = ast_node.get_meta("hlines", [])
		var hlines_arr: Array[int] = []
		for val in hlines_data:
			hlines_arr.append(int(val))
		matrix_ctrl.hlines = hlines_arr
		
		var cols = matrix_ctrl.columns
		for i in range(ast_node.children.size()):
			var cell_ctrl = _generate_node(ast_node.children[i])
			if cell_ctrl:
				var r = i / cols
				var c = i % cols
				cell_ctrl.name = "Cell_%d_%d" % [r, c]
				matrix_ctrl.add_child(cell_ctrl)
		return matrix_ctrl
		
	if ast_node.type == MathConstants.ElementType.STYLE_GROUP:
		var style_ctrl = ControlFactory.create_control(ast_node)
		if ast_node.children.size() > 0 and ast_node.children[0]:
			var content_ctrl = _generate_node(ast_node.children[0])
			if content_ctrl: content_ctrl.name = "Content"; style_ctrl.add_child(content_ctrl)
		return style_ctrl
		
	if ast_node.type == MathConstants.ElementType.ACCENT:
		var accent_ctrl = ControlFactory.create_control(ast_node)
		if ast_node.children.size() > 0 and ast_node.children[0]:
			var content_ctrl = _generate_node(ast_node.children[0])
			if content_ctrl: content_ctrl.name = "Content"; accent_ctrl.add_child(content_ctrl)
		return accent_ctrl
		
	var control = ControlFactory.create_control(ast_node)
	for child_ast in ast_node.children:
		var child_control = _generate_node(child_ast)
		if child_control:
			control.add_child(child_control)
			
	return control
