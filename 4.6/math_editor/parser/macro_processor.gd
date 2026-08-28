class_name MacroProcessor
extends RefCounted

## Pre-processes a LaTeX string to extract and expand \newcommand and \def macros.

static func process(text: String) -> String:
	var macros = {}
	text = _extract_definitions(text, macros)
	
	# Expand recursively up to 5 levels deep to handle macros using other macros
	for _i in range(5):
		var new_text = _expand_macros(text, macros)
		if new_text == text:
			break
		text = new_text
		
	return text

static func _extract_definitions(text: String, macros: Dictionary) -> String:
	var result = ""
	var i = 0
	while i < text.length():
		if text.substr(i).begins_with("\\newcommand"):
			i = _parse_newcommand(text, i, macros)
		elif text.substr(i).begins_with("\\def"):
			i = _parse_def(text, i, macros)
		else:
			result += text[i]
			i += 1
	return result

static func _parse_newcommand(text: String, start_idx: int, macros: Dictionary) -> int:
	var i = start_idx + 11 # Skip \newcommand
	# Skip whitespace
	while i < text.length() and text[i] == ' ': i += 1
	
	if i >= text.length() or text[i] != '{': return start_idx + 1
	var name_block = _extract_braced_block(text, i)
	var macro_name = name_block.content
	i = name_block.end
	
	# Skip whitespace
	while i < text.length() and text[i] == ' ': i += 1
	
	var args = 0
	if i < text.length() and text[i] == '[':
		var bracket_end = text.find("]", i)
		if bracket_end != -1:
			args = int(text.substr(i + 1, bracket_end - i - 1))
			i = bracket_end + 1
			
	# Skip whitespace
	while i < text.length() and text[i] == ' ': i += 1
	
	if i >= text.length() or text[i] != '{': return start_idx + 1
	var body_block = _extract_braced_block(text, i)
	
	macros[macro_name] = { "args": args, "body": body_block.content }
	return body_block.end

static func _parse_def(text: String, start_idx: int, macros: Dictionary) -> int:
	var i = start_idx + 4 # Skip \def
	# Skip whitespace
	while i < text.length() and text[i] == ' ': i += 1
	
	if i >= text.length() or text[i] != '\\': return start_idx + 1
	var name_start = i
	i += 1
	while i < text.length() and text[i].is_valid_identifier():
		i += 1
	var macro_name = text.substr(name_start, i - name_start)
	
	# Skip whitespace
	while i < text.length() and text[i] == ' ': i += 1
	
	if i >= text.length() or text[i] != '{': return start_idx + 1
	var body_block = _extract_braced_block(text, i)
	
	macros[macro_name] = { "args": 0, "body": body_block.content }
	return body_block.end

static func _extract_braced_block(text: String, start_idx: int) -> Dictionary:
	# start_idx points to '{'
	var depth = 1
	var i = start_idx + 1
	while i < text.length():
		if text[i] == '{': depth += 1
		elif text[i] == '}':
			depth -= 1
			if depth == 0:
				return { "content": text.substr(start_idx + 1, i - start_idx - 1), "end": i + 1 }
		i += 1
	return { "content": "", "end": text.length() }

static func _expand_macros(text: String, macros: Dictionary) -> String:
	if macros.is_empty(): return text
	
	var result = ""
	var i = 0
	while i < text.length():
		if text[i] == '\\':
			var found = false
			for m_name in macros:
				if text.substr(i).begins_with(m_name):
					var m_info = macros[m_name]
					var next_char_idx = i + m_name.length()
					
					# Ensure it's an exact match (next char shouldn't be a letter)
					if next_char_idx < text.length() and text[next_char_idx].is_valid_identifier():
						continue
						
					var arg_vals = []
					var parse_idx = next_char_idx
					for _arg_idx in range(m_info.args):
						while parse_idx < text.length() and text[parse_idx] == ' ': parse_idx += 1
						if parse_idx < text.length() and text[parse_idx] == '{':
							var block = _extract_braced_block(text, parse_idx)
							arg_vals.append(block.content)
							parse_idx = block.end
						elif parse_idx < text.length():
							arg_vals.append(text[parse_idx])
							parse_idx += 1
							
					var expanded = m_info.body
					for arg_idx in range(arg_vals.size()):
						expanded = expanded.replace("#" + str(arg_idx + 1), arg_vals[arg_idx])
						
					result += expanded
					i = parse_idx
					found = true
					break
					
			if not found:
				result += text[i]
				i += 1
		else:
			result += text[i]
			i += 1
			
	return result
