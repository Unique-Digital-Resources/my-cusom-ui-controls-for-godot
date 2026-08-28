class_name SVGDocument
extends RefCounted

# Helper class to build an XML/SVG document string with proper indentation.

var _content: PackedStringArray = PackedStringArray()
var _indent_level: int = 0
var pretty_print: bool = true

func _get_indent() -> String:
    if not pretty_print:
        return ""
    return "  ".repeat(_indent_level)

func add_declaration() -> void:
    _content.append("<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>\n")

func add_root(width: float, height: float) -> void:
    var w_str = str(snapped(width, 0.01))
    var h_str = str(snapped(height, 0.01))
    _content.append("%s<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"%s\" height=\"%s\" viewBox=\"0 0 %s %s\">\n" % [_get_indent(), w_str, h_str, w_str, h_str])
    _indent_level += 1

func close_root() -> void:
    _indent_level -= 1
    _content.append("%s</svg>\n" % _get_indent())

func open_tag(tag: String, attributes: String = "") -> void:
    var attr_str = " " + attributes if attributes != "" else ""
    _content.append("%s<%s%s>\n" % [_get_indent(), tag, attr_str])
    _indent_level += 1

func close_tag(tag: String) -> void:
    _indent_level -= 1
    _content.append("%s</%s>\n" % [_get_indent(), tag])

func add_self_closing_tag(tag: String, attributes: String = "") -> void:
    var attr_str = " " + attributes if attributes != "" else ""
    _content.append("%s<%s%s/>\n" % [_get_indent(), tag, attr_str])

func add_raw(text: String) -> void:
    _content.append("%s%s\n" % [_get_indent(), text])

func to_string() -> String:
    return "".join(_content)