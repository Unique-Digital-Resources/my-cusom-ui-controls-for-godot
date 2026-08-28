class_name DocParagraph extends RefCounted

var raw_text: String = ""
var tokens: Array = []
var blocks: Array = []
var block_type: String = "paragraph"
var heading_level: int = 0

var registry: SyntaxRegistry

func _init(p_registry: SyntaxRegistry) -> void:
	registry = p_registry
	parse_markdown()

func parse_markdown() -> void:
	tokens.clear()
	blocks.clear()
	block_type = "paragraph"
	heading_level = 0
	
	var states = {}
	for def in registry.definitions:
		states[def.name] = false
		
	var open_blocks = {}
	var i := 0
	var text_start := 0
	
	if raw_text.begins_with("## "):
		block_type = "heading"
		heading_level = 2
	elif raw_text.begins_with("# "):
		block_type = "heading"
		heading_level = 1

	while i < raw_text.length():
		if i == 0 and block_type == "heading":
			var prefix = "## " if heading_level == 2 else "# "
			tokens.append({
				"text": prefix, "bold": true, "italic": false, "highlight": false,
				"is_syntax": true, "syntax_name": "heading_prefix", "raw_start": 0
			})
			blocks.append({ "type": "heading_prefix", "start": 0, "start_tok": tokens.size() - 1, "end": prefix.length(), "end_tok": tokens.size() - 1 })
			i += prefix.length()
			text_start = i
			continue
			
		var matched_def = null
		var is_open = false
		
		for def in registry.definitions:
			if def.kind == SyntaxDefinition.Kind.INLINE and states[def.name] and raw_text.substr(i).begins_with(def.close_token):
				matched_def = def
				is_open = false
				break
				
		if not matched_def:
			for def in registry.definitions:
				if def.kind == SyntaxDefinition.Kind.INLINE and not states[def.name] and raw_text.substr(i).begins_with(def.open_token):
					matched_def = def
					is_open = true
					break
					
		if matched_def:
			if i > text_start:
				_add_text_token(raw_text.substr(text_start, i - text_start), states, text_start)
				
			# CRITICAL FIX: Use the correct token string for length calculation
			var token_str = matched_def.open_token if is_open else matched_def.close_token
				
			tokens.append({
				"text": token_str,
				"bold": states.bold, "italic": states.italic, "highlight": states.highlight,
				"is_syntax": true, "syntax_name": matched_def.name, "raw_start": i
			})
			
			if is_open:
				var block = { "type": matched_def.name, "start": i, "start_tok": tokens.size() - 1, "end": -1, "end_tok": -1 }
				blocks.append(block)
				open_blocks[matched_def.name] = block
			else:
				if open_blocks.has(matched_def.name):
					var b = open_blocks[matched_def.name]
					b.end = i + token_str.length()
					b.end_tok = tokens.size() - 1
					open_blocks.erase(matched_def.name)
					
			states[matched_def.name] = is_open
			
			# CRITICAL FIX: Advance by the ACTUAL matched token length, not always the open token length
			i += token_str.length()
			text_start = i
		else:
			i += 1
			
	if i > text_start:
		_add_text_token(raw_text.substr(text_start, i - text_start), states, text_start)

func _add_text_token(text: String, states: Dictionary, raw_start: int) -> void:
	tokens.append({
		"text": text, 
		"bold": states.get("bold", false), 
		"italic": states.get("italic", false), 
		"highlight": states.get("highlight", false),
		"is_syntax": false, 
		"raw_start": raw_start
	})

func get_plain_text() -> String:
	var t := ""
	for tok in tokens:
		if not tok.is_syntax:
			t += tok.text
	return t

func get_char_count() -> int:
	return get_plain_text().length()

func get_render_tokens(caret_offset: int) -> Array:
	var active_blocks := []
	for b in blocks:
		active_blocks.append(caret_offset >= b.start and (b.end == -1 or caret_offset <= b.end))
		
	var render_tokens := []
	var i := 0
	while i < tokens.size():
		var tok = tokens[i]
		var block_idx := -1
		for j in range(blocks.size()):
			if i == blocks[j].start_tok or i == blocks[j].end_tok or (i > blocks[j].start_tok and i < blocks[j].end_tok):
				block_idx = j
				break
				
		if block_idx != -1:
			var b = blocks[block_idx]
			var is_provider = false
			var provider_path = ""
			for def in registry.definitions:
				if def.name == b.type and def.provider != "":
					is_provider = true
					provider_path = def.provider
					break
					
			if is_provider and b.end != -1 and not active_blocks[block_idx]:
				var inner_text = ""
				if b.end_tok > b.start_tok:
					for k in range(b.start_tok + 1, b.end_tok):
						inner_text += tokens[k].text
						
				render_tokens.append({
					"is_object": true, "provider": provider_path, "args": inner_text,
					"raw_start": b.start, "raw_length": b.end - b.start
				})
				i = b.end_tok + 1
				continue
				
		if tok.is_syntax:
			if block_idx != -1 and not active_blocks[block_idx]:
				i += 1
				continue
		render_tokens.append(tok)
		i += 1
	return render_tokens
