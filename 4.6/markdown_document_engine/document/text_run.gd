class_name TextRun extends RefCounted

var text: String = ""
# Phase 1 supports basic bold/italic, even if we don't parse Markdown yet
var bold: bool = false
var italic: bool = false

func _init(p_text: String = "", p_bold: bool = false, p_italic: bool = false) -> void:
	text = p_text
	bold = p_bold
	italic = p_italic
