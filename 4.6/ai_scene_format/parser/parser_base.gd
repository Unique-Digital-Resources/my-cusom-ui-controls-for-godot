@tool
class_name AIParserBase
extends RefCounted

## V2 Recursive Descent Parser for the .aiui syntax.

var lexer: AILexer = AILexer.new()
var tokens: Array[AILexer.Token] = []
var pos: int = 0

class ASTNode:
	var type: String       # "vars", "tree", "node", "prop", "anim", "track", "state", etc.
	var key: String        # The identifier (e.g., "Root", "text", "color_tween")
	var value: Variant     # The evaluated value (if it's a property)
	var children: Array[ASTNode] = []
	
	func _init(t: String, k: String = "", v: Variant = null):
		type = t; key = k; value = v

func parse(source: String) -> Array[ASTNode]:
	tokens = lexer.tokenize(source)
	pos = 0
	
	var roots: Array[ASTNode] = []
	
	while _peek().type != AILexer.TokenType.EOF:
		var tok = _peek()
		if tok.type == AILexer.TokenType.TEXT and tok.value in ["vars", "tree", "interactivity", "animations", "tweens"]:
			roots.append(_parse_root_block())
		else:
			_advance() # Skip stray tokens
			
	return roots

func _parse_root_block() -> ASTNode:
	var block_name = _advance().value
	var node = ASTNode.new(block_name, block_name)
	
	_expect(AILexer.TokenType.LBRACE)
	
	while _peek().type != AILexer.TokenType.RBRACE and _peek().type != AILexer.TokenType.EOF:
		node.children.append(_parse_statement())
		
	_expect(AILexer.TokenType.RBRACE)
	return node

func _parse_statement() -> ASTNode:
	var tok = _peek()
	
	if tok.type not in [AILexer.TokenType.TEXT, AILexer.TokenType.STRING]:
		_advance()
		return ASTNode.new("error", "invalid_statement")
		
	var first_key = _advance().value
	var full_key = first_key
	
	while _peek().type not in [AILexer.TokenType.EQUALS, AILexer.TokenType.LBRACE, AILexer.TokenType.LPAREN, AILexer.TokenType.RBRACE, AILexer.TokenType.EOF]:
		full_key += " " + str(_advance().value)
		
	full_key = full_key.strip_edges()
	
	if _peek().type == AILexer.TokenType.EQUALS:
		_advance()
		var val = _parse_value()
		return ASTNode.new("prop", full_key, val)
	elif _peek().type == AILexer.TokenType.LPAREN:
		_advance()
		var args = _parse_args()
		_expect(AILexer.TokenType.RPAREN)
		
		var node = ASTNode.new("call", full_key)
		node.value = args
		
		if _peek().type == AILexer.TokenType.LBRACE:
			_advance()
			while _peek().type != AILexer.TokenType.RBRACE and _peek().type != AILexer.TokenType.EOF:
				node.children.append(_parse_statement())
			_expect(AILexer.TokenType.RBRACE)
			
		return node
	elif _peek().type == AILexer.TokenType.LBRACE:
		_advance()
		var node = ASTNode.new("block", full_key)
		while _peek().type != AILexer.TokenType.RBRACE and _peek().type != AILexer.TokenType.EOF:
			node.children.append(_parse_statement())
		_expect(AILexer.TokenType.RBRACE)
		return node
		
	return ASTNode.new("prop", full_key, null)

func _parse_value() -> Variant:
	var tok = _peek()
	var val = null
	
	match tok.type:
		AILexer.TokenType.STRING:
			_advance()
			val = tok.value
		AILexer.TokenType.NUMBER:
			_advance()
			val = tok.value
		AILexer.TokenType.LPAREN:
			_advance()
			var expr_str = _read_expression()
			_expect(AILexer.TokenType.RPAREN)
			val = {"__type__": "expr", "code": expr_str}
		AILexer.TokenType.TEXT:
			var v = _advance().value
			var lower_v = v.to_lower()
			
			if lower_v == "true":
				val = true
			elif lower_v == "false":
				val = false
			elif lower_v == "null":
				val = null
			elif _peek().type == AILexer.TokenType.LPAREN:
				_advance()
				var args = _parse_args()
				_expect(AILexer.TokenType.RPAREN)
				val = _evaluate_call(v, args)
			else:
				val = v
		_:
			_advance()
			val = null
			
	if _peek().type == AILexer.TokenType.TEXT and _peek().value == "ease" and _peek(1).type == AILexer.TokenType.LPAREN:
		_advance()
		_expect(AILexer.TokenType.LPAREN)
		var args = _parse_args()
		_expect(AILexer.TokenType.RPAREN)
		var ease_data = _evaluate_call("ease", args)
		return {"value": val, "ease": ease_data}
		
	return val

func _read_expression() -> String:
	var expr_parts = []
	var paren_depth = 0
	while _peek().type != AILexer.TokenType.EOF:
		var t = _peek()
		if t.type == AILexer.TokenType.LPAREN:
			paren_depth += 1
			expr_parts.append("(")
			_advance()
		elif t.type == AILexer.TokenType.RPAREN:
			if paren_depth == 0: break
			paren_depth -= 1
			expr_parts.append(")")
			_advance()
		else:
			expr_parts.append(str(t.value))
			_advance()
	return " ".join(expr_parts)

func _parse_args() -> Array:
	var args = []
	while _peek().type != AILexer.TokenType.RPAREN and _peek().type != AILexer.TokenType.EOF:
		args.append(_parse_value())
		if _peek().type == AILexer.TokenType.COMMA:
			_advance()
	return args

func _evaluate_call(func_name: String, args: Array) -> Variant:
	var lower_name = func_name.to_lower()
	match lower_name:
		"color":
			var r = float(args[0]) if args.size() > 0 else 0.0
			var g = float(args[1]) if args.size() > 1 else 0.0
			var b = float(args[2]) if args.size() > 2 else 0.0
			var a = float(args[3]) if args.size() > 3 else 1.0
			return Color(r, g, b, a)
		"vector2", "vec2":
			var x = float(args[0]) if args.size() > 0 else 0.0
			var y = float(args[1]) if args.size() > 1 else 0.0
			return Vector2(x, y)
		"vector3", "vec3":
			var x = float(args[0]) if args.size() > 0 else 0.0
			var y = float(args[1]) if args.size() > 1 else 0.0
			var z = float(args[2]) if args.size() > 2 else 0.0
			return Vector3(x, y, z)
		"ease":
			return {"__type__": "ease", "curve": args[0] if args.size() > 0 else "LINEAR", "dir": args[1] if args.size() > 1 else "IN"}
		"source": return {"__type__": "source", "path": args[0] if args.size() > 0 else ""}
		"backend": return {"__type__": "backend", "node": args[0] if args.size() > 0 else "", "prop": args[1] if args.size() > 1 else ""}
		"run": return {"__type__": "run", "node": args[0] if args.size() > 0 else "", "func": args[1] if args.size() > 1 else ""}
		"play": return {"__type__": "play", "anim": args[0] if args.size() > 0 else "", "player": args[1] if args.size() > 1 else ""}
		"set": return {"__type__": "set", "path": args[0] if args.size() > 0 else "", "prop": args[1] if args.size() > 1 else "", "val": args[2] if args.size() > 2 else null}
		"audio": return {"__type__": "audio", "path": args[0] if args.size() > 0 else ""}
		
		# FIX: Added load constructor
		"load": return {"__type__": "load", "path": args[0] if args.size() > 0 else ""}
		
		_:
			if func_name.begins_with("@"): return {"__type__": "anim_ref", "name": func_name.substr(1), "args": args}
			return {"__type__": "call", "name": func_name, "args": args}

func _peek(offset: int = 0) -> AILexer.Token:
	if pos + offset < tokens.size(): return tokens[pos + offset]
	return AILexer.Token.new(AILexer.TokenType.EOF)

func _advance() -> AILexer.Token:
	var t = _peek()
	if pos < tokens.size(): pos += 1
	return t

func _expect(type: int) -> void:
	if _peek().type == type: _advance()
