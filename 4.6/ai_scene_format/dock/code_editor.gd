@tool
extends CodeEdit

## V2 Shared text editor with Syntax Highlighting.

var highlighter: CodeHighlighter

func _ready() -> void:
	add_theme_color_override("background_color", Color(0.12, 0.13, 0.15, 1.0))
	add_theme_color_override("font_color", Color(0.85, 0.87, 0.9, 1.0))
	
	highlighter = CodeHighlighter.new()
	_setup_highlighting()
	syntax_highlighter = highlighter
	
	indent_automatic = true
	gutters_draw_line_numbers = true
	gutters_draw_fold_gutter = true
	draw_tabs = true

func _setup_highlighting() -> void:
	# Godot 4 uses color regions for strings and comments
	highlighter.add_color_region("\"", "\"", Color(0.85, 0.6, 0.5), false)
	highlighter.add_color_region("#", "", Color(0.4, 0.45, 0.5), true)
	
	highlighter.set_number_color(Color(0.6, 0.8, 0.5))
	highlighter.set_symbol_color(Color(0.8, 0.6, 0.9))
	highlighter.set_member_variable_color(Color(0.9, 0.7, 0.6))
	
	# V2 Root Blocks
	var root_keywords = ["vars", "tree", "interactivity", "animations"]
	for kw in root_keywords:
		highlighter.add_keyword_color(kw, Color(0.8, 0.4, 0.4))
		
	# V2 Logic Keywords
	var logic_keywords = [
		"state", "trigger", "condition", "action", 
		"animation", "track", "keyframe", "length", "loop", 
		"type", "interp", "value", "ease"
	]
	for kw in logic_keywords:
		highlighter.add_keyword_color(kw, Color(0.6, 0.75, 0.9))
		
	# V2 Function Calls / Value Constructors
	var func_keywords = [
		"Color", "Vector2", "source", "backend", "run", "play", "set"
	]
	for kw in func_keywords:
		highlighter.add_keyword_color(kw, Color(0.6, 0.8, 0.6))
		
	# Control flow / logic
	var control_keywords = ["true", "false", "null"]
	for kw in control_keywords:
		highlighter.add_keyword_color(kw, Color(0.8, 0.4, 0.4))
