class_name PlainMathImporter
extends RefCounted

## Converts a plain math string into a MathAST.

const MacroProcessorScript = preload("res://addons/math_editor/parser/macro_processor.gd")

static func parse(formula: String) -> Dictionary:
	# 1. Expand custom macros before lexing
	var clean_formula = MacroProcessorScript.process(formula)
	
	# 2. Tokenize
	var lexer := MathLexer.new()
	var tokens = lexer.tokenize(clean_formula)
	
	if not lexer.errors.is_empty():
		return { "ast": null, "errors": lexer.errors }
		
	# 3. Parse
	var parser := MathParser.new()
	var ast = parser.parse(tokens)
	
	var all_errors: Array[String] = []
	all_errors.append_array(parser.errors)
	
	return {
		"ast": ast,
		"errors": all_errors
	}
