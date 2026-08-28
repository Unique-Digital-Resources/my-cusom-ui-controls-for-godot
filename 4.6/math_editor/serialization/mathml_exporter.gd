class_name MathMLExporter
extends RefCounted

## Reconstructs a MathML string from the generated Control hierarchy.
## Differentiates between <mi> (identifiers), <mn> (numbers), and <mo> (operators).

static func export(root: Control) -> String:
	if not root:
		return "<math></math>"
	return "<math>\n%s\n</math>" % _traverse(root, 1)

static func _traverse(node: Control, indent: int) -> String:
	var pad = "  ".repeat(indent)
	
	if node is SequenceControl:
		var parts: Array[String] = []
		parts.append(pad + "<mrow>")
		for c in node.get_children():
			if c is MathElement:
				parts.append(_traverse(c, indent + 1))
		parts.append(pad + "</mrow>")
		return "\n".join(parts)
		
	elif node is ScriptControl:
		var base = _traverse(node.get_node_or_null("Base"), indent + 1)
		var sup = node.get_node_or_null("Super")
		var sub = node.get_node_or_null("Sub")
		
		if sup and sub:
			return pad + "<msubsup>\n%s\n%s\n%s\n%s</msubsup>" % [base, _traverse(sup, indent + 1), _traverse(sub, indent + 1), pad]
		elif sup:
			return pad + "<msup>\n%s\n%s\n%s</msup>" % [base, _traverse(sup, indent + 1), pad]
		elif sub:
			return pad + "<msub>\n%s\n%s\n%s</msub>" % [base, _traverse(sub, indent + 1), pad]
		return pad + "<mrow>\n%s\n%s</mrow>" % [base, pad]
		
	elif node is FractionControl:
		var num = _traverse(node.get_node_or_null("Numerator"), indent + 1)
		var den = _traverse(node.get_node_or_null("Denominator"), indent + 1)
		return pad + "<mfrac>\n%s\n%s\n%s</mfrac>" % [num, den, pad]
		
	elif node is RootControl:
		var rad = _traverse(node.get_node_or_null("Radicand"), indent + 1)
		var idx = node.get_node_or_null("Index")
		if idx:
			var idx_str = _traverse(idx, indent + 1)
			return pad + "<mroot>\n%s\n%s\n%s</mroot>" % [rad, idx_str, pad]
		return pad + "<msqrt>\n%s\n%s</msqrt>" % [rad, pad]
		
	elif node is FencedControl:
		var content = _traverse(node.get_node_or_null("Content"), indent + 1)
		var open_esc = node.open_char.replace("\"", "&quot;").replace("<", "&lt;").replace(">", "&gt;")
		var close_esc = node.close_char.replace("\"", "&quot;").replace("<", "&lt;").replace(">", "&gt;")
		return pad + "<mfenced open=\"%s\" close=\"%s\">\n%s\n%s</mfenced>" % [open_esc, close_esc, content, pad]
		
	elif node is MatrixControl:
		var cols = node.columns
		var children = node.get_children()
		var rows_xml: Array[String] = []
		var current_row_xml: Array[String] = []
		
		for i in range(children.size()):
			current_row_xml.append(_traverse(children[i], indent + 2))
			if (i + 1) % cols == 0:
				rows_xml.append(pad + "  <mtr>\n" + "\n".join(current_row_xml) + "\n" + pad + "  </mtr>")
				current_row_xml.clear()
				
		if not current_row_xml.is_empty():
			rows_xml.append(pad + "  <mtr>\n" + "\n".join(current_row_xml) + "\n" + pad + "  </mtr>")
			
		return pad + "<mtable>\n" + "\n".join(rows_xml) + "\n" + pad + "</mtable>"
		
	elif node is UnderOverControl:
		var base = _traverse(node.get_node_or_null("Base"), indent + 1)
		var sup = node.get_node_or_null("Super")
		var sub = node.get_node_or_null("Sub")
		
		if sup and sub:
			return pad + "<munderover>\n%s\n%s\n%s\n%s</munderover>" % [base, _traverse(sup, indent + 1), _traverse(sub, indent + 1), pad]
		elif sup:
			return pad + "<mover>\n%s\n%s\n%s</mover>" % [base, _traverse(sup, indent + 1), pad]
		elif sub:
			return pad + "<munder>\n%s\n%s\n%s</munder>" % [base, _traverse(sub, indent + 1), pad]
		return pad + "<mrow>\n%s\n%s</mrow>" % [base, pad]
		
	elif node is SymbolControl:
		var text = node.text
		var tag = "mi"
		if text.is_valid_float():
			tag = "mn"
		elif text in ["+", "-", "*", "/", "=", "&", "\\\\", "<", ">", "\\leq", "\\geq"]:
			tag = "mo"
			
		# Escape XML special characters
		var escaped_text = text.replace("<", "&lt;").replace(">", "&gt;").replace("&", "&amp;")
		return pad + "<%s>%s</%s>" % [tag, escaped_text, tag]
		
	return pad + "<merror>Unknown Node</merror>"
