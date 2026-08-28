class_name SyntaxRegistry extends RefCounted

var definitions: Array[SyntaxDefinition] = []

func register_inline(p_name: String, p_open: String, p_close: String, p_provider: String = "") -> void:
	var d = SyntaxDefinition.new(p_name, SyntaxDefinition.Kind.INLINE, p_open, p_close, p_provider)
	definitions.append(d)

func _init() -> void:
	# Default Markdown
	register_inline("bold", "**", "**")
	register_inline("italic", "*", "*")
	register_inline("highlight", "==", "==")
	
	# Godot Built-in Control Providers
	register_inline("button", "@button(", ")", "Button")
	register_inline("colorRect", "@colorRect(", ")", "ColorRect")
	
	# Custom Script Provider
	register_inline("chart", "@chart(", ")", "res://addons/markdown_document_engine/objects/chart_inline_control.gd")
