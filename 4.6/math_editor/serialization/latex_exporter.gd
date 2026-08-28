class_name LatexExporter
extends RefCounted

## Reconstructs a LaTeX string from the generated Control hierarchy.

static func export(root: Control) -> String:
	if not root:
		return ""
	return _traverse(root).strip_edges()

static func _traverse(node: Control) -> String:
	if node is SequenceControl:
		var parts: Array[String] = []
		for c in node.get_children():
			if c is MathElement:
				parts.append(_traverse(c))
		return " ".join(parts)
		
	elif node is SpacerControl:
		if abs(node.em_width - 1.0) < 0.01: return "\\quad "
		if abs(node.em_width - 2.0) < 0.01: return "\\qquad "
		if abs(node.em_width - (3.0/18.0)) < 0.01: return "\\, "
		if abs(node.em_width - (4.0/18.0)) < 0.01: return "\\: "
		if abs(node.em_width - (5.0/18.0)) < 0.01: return "\\; "
		if abs(node.em_width - (-3.0/18.0)) < 0.01: return "\\! "
		return " "
		
	elif node is StyleGroupControl:
		var content = _traverse(node.get_node_or_null("Content"))
		match node.style_type:
			"color": return "\\color{%s}{%s}" % [node.style_value, content]
			"size": return "\\size{%s}{%s}" % [node.style_value, content]
			"bold": return "\\bold{%s}" % content
			"italic": return "\\mathit{%s}" % content
			"bgcolor": return "\\colorbox{%s}{%s}" % [node.style_value, content]
		return content
		
	elif node is AccentControl:
		var content = _traverse(node.get_node_or_null("Content"))
		return "%s{%s}" % [node.accent_type, content]
		
	elif node is ScriptControl:
		var base = _traverse(node.get_node_or_null("Base"))
		var sup = _traverse(node.get_node_or_null("Super"))
		var sub = _traverse(node.get_node_or_null("Sub"))
		var res = base
		if sup and not sup.is_empty(): res += "^{%s}" % sup
		if sub and not sub.is_empty(): res += "_{%s}" % sub
		return res
		
	elif node is FractionControl:
		var num = _traverse(node.get_node_or_null("Numerator"))
		var den = _traverse(node.get_node_or_null("Denominator"))
		return "\\frac{%s}{%s}" % [num, den]
		
	elif node is RootControl:
		var rad = _traverse(node.get_node_or_null("Radicand"))
		var idx = _traverse(node.get_node_or_null("Index"))
		if idx and not idx.is_empty(): return "\\sqrt[%s]{%s}" % [idx, rad]
		return "\\sqrt{%s}" % rad
		
	elif node is FencedControl:
		var content = _traverse(node.get_node_or_null("Content"))
		return "%s%s%s" % [node.open_char, content, node.close_char]
		
	elif node is MatrixControl:
		var cols = node.columns
		var rows_str: Array[String] = []
		var current_row_str: Array[String] = []
		var children = node.get_children()
		
		# NEW: Map hlines for export
		var hlines_set = {}
		for h in node.hlines:
			hlines_set[h] = true
		var row_idx = 0
		
		for i in range(children.size()):
			current_row_str.append(_traverse(children[i]))
			if (i + 1) % cols == 0:
				var row_str = " & ".join(current_row_str)
				# Prepend \hline if this row has one
				if hlines_set.has(row_idx):
					rows_str.append("\\hline\n" + row_str)
				else:
					rows_str.append(row_str)
				current_row_str.clear()
				row_idx += 1
				
		if not current_row_str.is_empty():
			var row_str = " & ".join(current_row_str)
			if hlines_set.has(row_idx):
				rows_str.append("\\hline\n" + row_str)
			else:
				rows_str.append(row_str)
			
		var begin_str = "\\begin{" + node.matrix_type + "}"
		if node.matrix_type == "array" and node.col_def != "":
			begin_str = "\\begin{array}{" + node.col_def + "}"
			
		return begin_str + "\n" + " \\\\\n".join(rows_str) + "\n" + "\\end{" + node.matrix_type + "}"
		
	elif node is UnderOverControl:
		var base = _traverse(node.get_node_or_null("Base"))
		var sup = _traverse(node.get_node_or_null("Super"))
		var sub = _traverse(node.get_node_or_null("Sub"))
		var res = base
		if sub and not sub.is_empty(): res += "_{%s}" % sub
		if sup and not sup.is_empty(): res += "^{%s}" % sup
		return res
		
	elif node is SymbolControl:
		if node.latex_cmd != "":
			return node.latex_cmd
		return node.text
		
	return ""
