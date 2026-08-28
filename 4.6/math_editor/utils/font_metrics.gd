class_name FontMetrics
extends RefCounted

## Helper class for measuring fonts without instantiating nodes.
## Wraps Godot's TextServer API with basic caching.

# Cache structure: { font_id : { size : { text : Vector2 } } }
static var _size_cache: Dictionary = {}

static func get_text_size(text: String, font: Font, size: int) -> Vector2:
    if not font:
        return Vector2.ZERO
        
    var font_id = font.get_instance_id()
    if not _size_cache.has(font_id):
        _size_cache[font_id] = {}
        
    var size_dict = _size_cache[font_id]
    if not size_dict.has(size):
        size_dict[size] = {}
        
    var text_dict = size_dict[size]
    if text_dict.has(text):
        return text_dict[text]
        
    var result = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size)
    text_dict[text] = result
    return result

static func get_ascent(font: Font, size: int) -> float:
    if not font:
        return 0.0
    return font.get_ascent(size)

static func get_descent(font: Font, size: int) -> float:
    if not font:
        return 0.0
    return font.get_descent(size)

static func get_underline_position(font: Font, size: int) -> float:
    if not font:
        return 0.0
    return font.get_underline_position(size)

## Clears the metric cache. Useful if fonts are changed at runtime.
static func clear_cache() -> void:
    _size_cache.clear()