@tool
class_name SVGUtils
extends RefCounted

## Low-level helper functions for SVG string formatting.

# Converts Godot Color to SVG rgb() string
static func color_to_rgb(c: Color) -> String:
    return "rgb(%d,%d,%d)" % [c.r8, c.g8, c.b8]

# Escapes XML special characters to prevent SVG parsing errors
static func escape_xml(text: String) -> String:
    return text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&apos;")

# Formats a float to avoid overly long decimals in the SVG file
static func fmt(n: float) -> String:
    return "%.3f" % n

# Checks if a string starts with Arabic characters (for RTL direction)
static func is_arabic(text: String) -> bool:
    if text.length() == 0: return false
    var code = text[0].unicode_at(0)
    return code >= 0x0600 and code <= 0x06FF