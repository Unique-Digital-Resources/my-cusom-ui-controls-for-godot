@tool
class_name AILexer
extends RefCounted

## V2 Tokenizer for the block-based, JSON-like .aiui syntax.

enum TokenType {
	TEXT,       # Identifiers, keywords, paths
	STRING,     # Quoted strings
	NUMBER,     # Int or Float
	LBRACE,     # {
	RBRACE,     # }
	LPAREN,     # (
	RPAREN,     # )
	LBRACKET,   # [
	RBRACKET,   # ]
	EQUALS,     # =
	COMMA,      # ,
	EOF         # End of file
}

class Token:
	var type: int
	var value: Variant
	func _init(t: int, v: Variant = ""):
		type = t; value = v

var text: String = ""
var pos: int = 0

func tokenize(source: String) -> Array[Token]:
	text = source
	pos = 0
	var tokens: Array[Token] = []
	
	while pos < text.length():
		var c = text[pos]
		
		# Whitespace
		if c in " \t\n\r":
			pos += 1
			continue
			
		# Comments
		if c == '#':
			while pos < text.length() and text[pos] != '\n':
				pos += 1
			continue
			
		# Single character tokens
		match c:
			'{': tokens.append(Token.new(TokenType.LBRACE)); pos += 1; continue
			'}': tokens.append(Token.new(TokenType.RBRACE)); pos += 1; continue
			'(': tokens.append(Token.new(TokenType.LPAREN)); pos += 1; continue
			')': tokens.append(Token.new(TokenType.RPAREN)); pos += 1; continue
			'[': tokens.append(Token.new(TokenType.LBRACKET)); pos += 1; continue
			']': tokens.append(Token.new(TokenType.RBRACKET)); pos += 1; continue
			'=': tokens.append(Token.new(TokenType.EQUALS)); pos += 1; continue
			',': tokens.append(Token.new(TokenType.COMMA)); pos += 1; continue
			'"':
				var str_val = _read_string()
				tokens.append(Token.new(TokenType.STRING, str_val))
				continue
			'-', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '.':
				# FIX: Ensure we don't read a number if it's part of a word (like Vector2)
				# This is handled by checking if the previous char was a text char.
				# But since we check _is_text_char first in the final fallback, 
				# numbers starting words are already handled. 
				# However, to be safe, we only read a number if it's NOT preceded by a letter.
				# Actually, the order of checks means _read_text will catch "Vector2" first.
				var num_val = _read_number()
				tokens.append(Token.new(TokenType.NUMBER, num_val))
				continue
				
		# Text (identifiers, keywords, true/false/null)
		if _is_text_char(c):
			var txt_val = _read_text()
			tokens.append(Token.new(TokenType.TEXT, txt_val))
			continue
			
		# Unknown character, skip
		pos += 1
		
	tokens.append(Token.new(TokenType.EOF))
	return tokens

func _read_string() -> String:
	pos += 1 # Skip opening quote
	var start = pos
	while pos < text.length() and text[pos] != '"':
		pos += 1
	var val = text.substr(start, pos - start)
	pos += 1 # Skip closing quote
	return val

func _read_number() -> Variant:
	var start = pos
	if text[pos] == '-': pos += 1
	var has_dot = false
	while pos < text.length():
		var c = text[pos]
		if c.is_valid_int():
			pos += 1
		elif c == '.' and not has_dot:
			has_dot = true
			pos += 1
		else:
			break
			
	var str_val = text.substr(start, pos - start)
	if has_dot:
		return float(str_val)
	return int(str_val)

func _read_text() -> String:
	var start = pos
	while pos < text.length() and _is_text_char(text[pos]):
		pos += 1
	return text.substr(start, pos - start)

# FIX: Allow numbers in text so "Vector2" is read as one word
func _is_text_char(c: String) -> bool:
	return c.is_valid_identifier() or c.is_valid_int() or c == "@" or c == "/" or c == ":" or c == "_"
