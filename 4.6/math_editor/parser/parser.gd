class_name MathParser
extends RefCounted

var errors: Array[String] = []
var tokens: Array[MathLexer.Token] = []
var pos: int = 0

func parse(p_tokens: Array[MathLexer.Token]) -> MathAST:
	errors.clear()
	tokens = p_tokens
	pos = 0
	var ast = _parse_sequence()
	if current_token().type != MathLexer.TokenType.EOF:
		errors.append("Parser Error: Unexpected token '%s' at position %d." % [current_token().value, current_token().pos])
	return ast

func current_token() -> MathLexer.Token:
	return tokens[pos]

func consume() -> MathLexer.Token:
	var t = tokens[pos]
	if t.type != MathLexer.TokenType.EOF:
		pos += 1
	return t

func _parse_sequence() -> MathAST:
	var seq := MathAST.new()
	seq.type = MathConstants.ElementType.SEQUENCE
	while current_token().type != MathLexer.TokenType.EOF:
		var t = current_token()
		if t.type in [MathLexer.TokenType.RPAREN, MathLexer.TokenType.RBRACKET, MathLexer.TokenType.RBRACE]:
			break
		if t.type == MathLexer.TokenType.OPERATOR and t.value == "&":
			break
		if t.type == MathLexer.TokenType.COMMAND and (t.value == "\\\\" or t.value == "\\end"):
			break
		var node = _parse_term()
		if node:
			seq.children.append(node)
		else:
			break
	if seq.children.size() == 1:
		return seq.children[0]
	return seq

func _parse_term() -> MathAST:
	var base_node = _parse_atom()
	if not base_node:
		return null
	var t = current_token()
	if t.type == MathLexer.TokenType.OPERATOR and t.value == "/":
		consume()
		var den_node = _parse_atom()
		if den_node:
			var frac_ast := MathAST.new()
			frac_ast.type = MathConstants.ElementType.FRACTION
			frac_ast.children.append(base_node)
			frac_ast.children.append(den_node)
			return frac_ast
		else:
			errors.append("Parser Error at %d: Expected expression after '/'." % t.pos)
			return base_node
	if t.type == MathLexer.TokenType.CARET or t.type == MathLexer.TokenType.UNDERSCORE:
		consume()
		var script_content = _parse_atom()
		if not script_content:
			errors.append("Parser Error at %d: Expected expression after '%s'." % [t.pos, t.value])
			return base_node
		var script_ast := MathAST.new()
		script_ast.type = MathConstants.ElementType.SCRIPT
		script_ast.children.append(base_node)
		if t.type == MathLexer.TokenType.CARET:
			script_ast.children.append(script_content)
			script_ast.children.append(null)
		else:
			script_ast.children.append(null)
			script_ast.children.append(script_content)
		return script_ast
	return base_node

func _parse_atom() -> MathAST:
	var t = current_token()
	if t.type == MathLexer.TokenType.LBRACE:
		var fenced_node = _parse_fenced("standard")
		if fenced_node and fenced_node.children.size() > 0:
			return fenced_node.children[0] 
		return MathAST.new()
	return _parse_single_token()

func _parse_single_token() -> MathAST:
	var t = current_token()
	if t.type == MathLexer.TokenType.COMMAND:
		if t.value == "\\frac":
			return _parse_frac()
		elif t.value == "\\sqrt":
			return _parse_sqrt()
		elif t.value == "\\begin":
			return _parse_environment()
			
		var spacing_map = {
			"\\quad": 1.0, 
			"\\qquad": 2.0, 
			"\\,": 3.0/18.0, 
			"\\:": 4.0/18.0, 
			"\\;": 5.0/18.0, 
			"\\!": -3.0/18.0
		}
		if spacing_map.has(t.value):
			consume()
			var sp := MathAST.new()
			sp.type = MathConstants.ElementType.SPACER
			sp.set_meta("em_width", spacing_map[t.value])
			return sp
			
		if t.value == "\\colorbox":
			return _parse_colorbox()
			
		if t.value in ["\\color", "\\size", "\\bold", "\\mathbf", "\\textbf", "\\mathit", "\\textit", "\\mathbb", "\\mathcal"]:
			var s_type = "bold"
			if t.value in ["\\mathit", "\\textit"]: s_type = "italic"
			elif t.value == "\\color": s_type = "color"
			elif t.value == "\\size": s_type = "size"
			elif t.value in ["\\bold", "\\mathbf", "\\textbf"]: s_type = "bold"
			elif t.value == "\\mathbb": s_type = "blackboard"
			elif t.value == "\\mathcal": s_type = "caligraphic"
			return _parse_style_group(t.value, s_type)
			
		if t.value in ["\\overline", "\\underline", "\\vec", "\\hat"]:
			return _parse_accent(t.value)
			
		if t.value in ["\\sum", "\\prod", "\\int", "\\lim"]:
			consume()
			var op_ast = ValueAST.new(t.value, MathConstants.ElementType.SYMBOL)
			var t_next = current_token()
			if t_next.type == MathLexer.TokenType.CARET or t_next.type == MathLexer.TokenType.UNDERSCORE:
				var sup_node = null
				var sub_node = null
				var has_script = true
				while has_script:
					has_script = false
					t_next = current_token()
					if t_next.type == MathLexer.TokenType.CARET:
						consume()
						sup_node = _parse_atom()
						has_script = true
					elif t_next.type == MathLexer.TokenType.UNDERSCORE:
						consume()
						sub_node = _parse_atom()
						has_script = true
						
				var under_over_ast := MathAST.new()
				under_over_ast.type = MathConstants.ElementType.UNDER_OVER
				under_over_ast.children.append(op_ast)
				under_over_ast.children.append(sup_node)
				under_over_ast.children.append(sub_node)
				return under_over_ast
				
			return op_ast
			
		consume()
		return ValueAST.new(t.value, MathConstants.ElementType.SYMBOL)
		
	match t.type:
		MathLexer.TokenType.NUMBER:
			consume()
			return ValueAST.new(t.value, MathConstants.ElementType.NUMBER)
		MathLexer.TokenType.SYMBOL:
			consume()
			return ValueAST.new(t.value, MathConstants.ElementType.SYMBOL)
		MathLexer.TokenType.OPERATOR:
			consume()
			return OperatorAST.new(t.value)
		MathLexer.TokenType.PIPE:
			return _parse_fenced("pipe")
		MathLexer.TokenType.LPAREN, MathLexer.TokenType.LBRACKET:
			return _parse_fenced("standard")
		_:
			errors.append("Parser Error at %d: Unexpected token '%s'." % [t.pos, t.value])
			consume()
			return null

func _parse_frac() -> MathAST:
	consume()
	if current_token().type != MathLexer.TokenType.LBRACE:
		errors.append("Parser Error at %d: Expected '{' for numerator." % current_token().pos)
		return MathAST.new()
	consume()
	var num_ast = _parse_sequence()
	if current_token().type != MathLexer.TokenType.RBRACE:
		errors.append("Parser Error at %d: Expected '}' after numerator." % current_token().pos)
	else:
		consume()
	if current_token().type != MathLexer.TokenType.LBRACE:
		errors.append("Parser Error at %d: Expected '{' for denominator." % current_token().pos)
		return MathAST.new()
	consume()
	var den_ast = _parse_sequence()
	if current_token().type != MathLexer.TokenType.RBRACE:
		errors.append("Parser Error at %d: Expected '}' after denominator." % current_token().pos)
	else:
		consume()
	var frac_ast := MathAST.new()
	frac_ast.type = MathConstants.ElementType.FRACTION
	frac_ast.children.append(num_ast)
	frac_ast.children.append(den_ast)
	return frac_ast

func _parse_sqrt() -> MathAST:
	consume()
	var root_ast := MathAST.new()
	root_ast.type = MathConstants.ElementType.ROOT
	root_ast.children.append(null)
	root_ast.children.append(null)
	if current_token().type == MathLexer.TokenType.LBRACKET:
		consume()
		var idx_ast = _parse_sequence()
		root_ast.children[0] = idx_ast
		if current_token().type != MathLexer.TokenType.RBRACKET:
			errors.append("Parser Error at %d: Expected ']' after root index." % current_token().pos)
		else:
			consume()
	if current_token().type != MathLexer.TokenType.LBRACE:
		errors.append("Parser Error at %d: Expected '{' for radicand." % current_token().pos)
		return root_ast
	consume()
	var rad_ast = _parse_sequence()
	root_ast.children[1] = rad_ast
	if current_token().type != MathLexer.TokenType.RBRACE:
		errors.append("Parser Error at %d: Expected '}' after radicand." % current_token().pos)
	else:
		consume()
	return root_ast

func _parse_style_group(cmd: String, s_type: String) -> MathAST:
	consume()
	var style_val = ""
	
	if s_type not in ["bold", "italic", "bold_italic", "blackboard", "caligraphic"]:
		if current_token().type != MathLexer.TokenType.LBRACE:
			errors.append("Parser Error at %d: Expected '{' for style value." % current_token().pos)
			return MathAST.new()
		consume()
		if current_token().type in [MathLexer.TokenType.SYMBOL, MathLexer.TokenType.NUMBER]:
			style_val = current_token().value
			consume()
		if current_token().type != MathLexer.TokenType.RBRACE:
			errors.append("Parser Error at %d: Expected '}' after style value." % current_token().pos)
		else:
			consume()
			
	var node := MathAST.new()
	node.type = MathConstants.ElementType.STYLE_GROUP
	node.set_meta("style_type", s_type)
	node.set_meta("style_value", style_val)
	
	if current_token().type != MathLexer.TokenType.LBRACE:
		errors.append("Parser Error at %d: Expected '{' for styled content." % current_token().pos)
		return node
	consume()
	node.children.append(_parse_sequence())
	if current_token().type != MathLexer.TokenType.RBRACE:
		errors.append("Parser Error at %d: Expected '}' after styled content." % current_token().pos)
	else:
		consume()
	return node

func _parse_colorbox() -> MathAST:
	consume()
	if current_token().type != MathLexer.TokenType.LBRACE:
		errors.append("Parser Error at %d: Expected '{' for colorbox color." % current_token().pos)
		return MathAST.new()
	consume()
	var c_val = ""
	if current_token().type in [MathLexer.TokenType.SYMBOL, MathLexer.TokenType.NUMBER]:
		c_val = current_token().value
		consume()
	if current_token().type != MathLexer.TokenType.RBRACE:
		errors.append("Parser Error at %d: Expected '}' after colorbox color." % current_token().pos)
	else:
		consume()
		
	var node := MathAST.new()
	node.type = MathConstants.ElementType.STYLE_GROUP
	node.set_meta("style_type", "bgcolor")
	node.set_meta("style_value", c_val)
	
	if current_token().type != MathLexer.TokenType.LBRACE:
		errors.append("Parser Error at %d: Expected '{' for colorbox content." % current_token().pos)
		return node
	consume()
	node.children.append(_parse_sequence())
	if current_token().type != MathLexer.TokenType.RBRACE:
		errors.append("Parser Error at %d: Expected '}' after colorbox content." % current_token().pos)
	else:
		consume()
	return node

func _parse_accent(cmd: String) -> MathAST:
	consume()
	var node := MathAST.new()
	node.type = MathConstants.ElementType.ACCENT
	node.set_meta("accent_type", cmd)
	
	if current_token().type != MathLexer.TokenType.LBRACE:
		errors.append("Parser Error at %d: Expected '{' for accent content." % current_token().pos)
		return node
	consume()
	node.children.append(_parse_sequence())
	if current_token().type != MathLexer.TokenType.RBRACE:
		errors.append("Parser Error at %d: Expected '}' after accent content." % current_token().pos)
	else:
		consume()
	return node

func _parse_environment() -> MathAST:
	consume() # \begin
	consume() # {
	var env_name = ""
	if current_token().type == MathLexer.TokenType.SYMBOL:
		env_name = current_token().value
	consume() # name
	consume() # }
	
	var matrix_ast := MathAST.new()
	matrix_ast.type = MathConstants.ElementType.MATRIX
	matrix_ast.set_meta("matrix_type", env_name)
	
	var col_def = ""
	if env_name == "array":
		if current_token().type == MathLexer.TokenType.LBRACE:
			consume() # {
			while current_token().type != MathLexer.TokenType.RBRACE and current_token().type != MathLexer.TokenType.EOF:
				if current_token().type == MathLexer.TokenType.SYMBOL:
					col_def += current_token().value
				elif current_token().type == MathLexer.TokenType.PIPE:
					col_def += "|"
				consume()
			if current_token().type == MathLexer.TokenType.RBRACE:
				consume() # }
		matrix_ast.set_meta("col_def", col_def)
		
	var cells: Array[MathAST] = []
	var cols = 0
	var current_row_size = 0
	
	# NEW: Track horizontal lines for arrays
	var hlines: Array[int] = []
	var current_row_idx = 0
	
	while current_token().type != MathLexer.TokenType.EOF:
		if current_token().type == MathLexer.TokenType.COMMAND and current_token().value == "\\end":
			break
			
		# NEW: Handle \hline
		if current_token().type == MathLexer.TokenType.COMMAND and current_token().value == "\\hline":
			hlines.append(current_row_idx)
			consume()
			continue
			
		var cell = _parse_sequence()
		cells.append(cell)
		current_row_size += 1
		if current_token().type == MathLexer.TokenType.OPERATOR and current_token().value == "&":
			consume()
		elif current_token().type == MathLexer.TokenType.COMMAND and current_token().value == "\\\\":
			consume()
			cols = max(cols, current_row_size)
			current_row_size = 0
			current_row_idx += 1
		elif current_token().type == MathLexer.TokenType.COMMAND and current_token().value == "\\end":
			cols = max(cols, current_row_size)
		else:
			break
			
	if env_name == "array" and not col_def.is_empty():
		var def_cols = 0
		for ch in col_def:
			if ch in ["l", "c", "r"]: def_cols += 1
		if def_cols > 0: cols = def_cols
		
	matrix_ast.set_meta("columns", cols)
	matrix_ast.set_meta("hlines", hlines) # NEW
	matrix_ast.children = cells
	
	if current_token().type == MathLexer.TokenType.COMMAND and current_token().value == "\\end":
		consume() # \end
		consume() # {
		consume() # name
		consume() # }
	return matrix_ast

func _parse_fenced(mode: String) -> MathAST:
	var open_token = consume()
	var node := MathAST.new()
	node.type = MathConstants.ElementType.FENCED
	match open_token.type:
		MathLexer.TokenType.LPAREN:
			node.open_fence = "("
			node.close_fence = ")"
		MathLexer.TokenType.LBRACKET:
			node.open_fence = "["
			node.close_fence = "]"
		MathLexer.TokenType.LBRACE:
			node.open_fence = "{"
			node.close_fence = "}"
		MathLexer.TokenType.PIPE:
			node.open_fence = "|"
			node.close_fence = "|"
	if open_token.type == MathLexer.TokenType.PIPE:
		var seq := MathAST.new()
		seq.type = MathConstants.ElementType.SEQUENCE
		while current_token().type != MathLexer.TokenType.PIPE and current_token().type != MathLexer.TokenType.EOF:
			if current_token().type == MathLexer.TokenType.OPERATOR and current_token().value == "&":
				break
			if current_token().type == MathLexer.TokenType.COMMAND and (current_token().value == "\\\\" or current_token().value == "\\end"):
				break
			var term = _parse_term()
			if term:
				seq.children.append(term)
			else:
				break
		if seq.children.size() == 1:
			node.children.append(seq.children[0])
		else:
			node.children.append(seq)
	else:
		node.children.append(_parse_sequence())
	var close_token = current_token()
	var expected_close_type: MathLexer.TokenType
	match open_token.type:
		MathLexer.TokenType.LPAREN: expected_close_type = MathLexer.TokenType.RPAREN
		MathLexer.TokenType.LBRACKET: expected_close_type = MathLexer.TokenType.RBRACKET
		MathLexer.TokenType.LBRACE: expected_close_type = MathLexer.TokenType.RBRACE
		MathLexer.TokenType.PIPE: expected_close_type = MathLexer.TokenType.PIPE
	if close_token.type == expected_close_type:
		consume()
	else:
		errors.append("Parser Error at %d: Expected '%s' but found '%s'." % [close_token.pos, node.close_fence, close_token.value])
	return node
