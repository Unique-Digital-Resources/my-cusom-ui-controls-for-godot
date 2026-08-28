class_name MathLexer
extends RefCounted

## Tokenizer for mathematical expressions.

enum TokenType {
	NUMBER,
	SYMBOL,
	COMMAND,
	OPERATOR,
	LPAREN, RPAREN,
	LBRACKET, RBRACKET,
	LBRACE, RBRACE,
	PIPE,
	CARET,
	UNDERSCORE,
	EOF
}

class Token:
	var type: TokenType
	var value: String
	var pos: int
	
	func _init(t: TokenType, v: String, p: int) -> void:
		type = t
		value = v
		pos = p

var errors: Array[String] = []

func is_letter(ch: String) -> bool:
	return (ch >= "a" and ch <= "z") or (ch >= "A" and ch <= "Z")

func is_hex_char(ch: String) -> bool:
	return (ch >= "0" and ch <= "9") or (ch >= "a" and ch <= "f") or (ch >= "A" and ch <= "F")

func tokenize(text: String) -> Array[Token]:
	var tokens: Array[Token] = []
	errors.clear()
	var pos = 0
	var length = text.length()
	
	while pos < length:
		var ch = text[pos]
		
		if ch == " " or ch == "\t" or ch == "\n":
			pos += 1
			continue
			
		if ch.is_valid_int():
			var start = pos
			while pos < length and text[pos].is_valid_int():
				pos += 1
			if pos < length and text[pos] == ".":
				pos += 1
				while pos < length and text[pos].is_valid_int():
					pos += 1
			tokens.append(Token.new(TokenType.NUMBER, text.substr(start, pos - start), start))
			continue
			
		if ch == "#":
			var start = pos
			pos += 1
			while pos < length and is_hex_char(text[pos]):
				pos += 1
			tokens.append(Token.new(TokenType.SYMBOL, text.substr(start, pos - start), start))
			continue
			
		# LaTeX Commands & Row Breaks
		if ch == "\\":
			var start = pos
			pos += 1
			if pos < length and is_letter(text[pos]):
				while pos < length and is_letter(text[pos]):
					pos += 1
				var cmd = text.substr(start, pos - start)
				
				if cmd == "\\text":
					if pos < length and text[pos] == "{":
						pos += 1
						var text_start = pos
						var depth = 1
						while pos < length and depth > 0:
							if text[pos] == "{": depth += 1
							elif text[pos] == "}": depth -= 1
							if depth > 0: pos += 1
						var raw_text = text.substr(text_start, pos - text_start)
						tokens.append(Token.new(TokenType.SYMBOL, raw_text, start))
						if pos < length and text[pos] == "}": pos += 1
					continue
				else:
					tokens.append(Token.new(TokenType.COMMAND, cmd, start))
			# NEW: Handle single-character spacing commands like \, \; \! \:
			elif pos < length and text[pos] in [",", ";", "!", ":"]:
				pos += 1
				tokens.append(Token.new(TokenType.COMMAND, text.substr(start, pos - start), start))
			elif pos < length and text[pos] == "\\":
				pos += 1
				tokens.append(Token.new(TokenType.COMMAND, "\\\\", start))
			else:
				errors.append("Lexer Error at %d: Expected identifier or '\\' after '\\'." % start)
				pos += 1
			continue
			
		if is_letter(ch):
			var start = pos
			while pos < length and is_letter(text[pos]):
				pos += 1
			tokens.append(Token.new(TokenType.SYMBOL, text.substr(start, pos - start), start))
			continue
			
		if ch in ["+", "-", "*", "/", "=", "&", "<", ">"]:
			tokens.append(Token.new(TokenType.OPERATOR, ch, pos))
			pos += 1
			continue
			
		match ch:
			"(": tokens.append(Token.new(TokenType.LPAREN, ch, pos))
			")": tokens.append(Token.new(TokenType.RPAREN, ch, pos))
			"[": tokens.append(Token.new(TokenType.LBRACKET, ch, pos))
			"]": tokens.append(Token.new(TokenType.RBRACKET, ch, pos))
			"{": tokens.append(Token.new(TokenType.LBRACE, ch, pos))
			"}": tokens.append(Token.new(TokenType.RBRACE, ch, pos))
			"|": tokens.append(Token.new(TokenType.PIPE, ch, pos))
			"^": tokens.append(Token.new(TokenType.CARET, ch, pos))
			"_": tokens.append(Token.new(TokenType.UNDERSCORE, ch, pos))
			_:
				errors.append("Lexer Error at %d: Unexpected character '%s'." % [pos, ch])
				pos += 1
				continue
				
		pos += 1
		
	tokens.append(Token.new(TokenType.EOF, "", pos))
	return tokens
