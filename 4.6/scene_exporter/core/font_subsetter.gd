class_name FontSubsetter
extends RefCounted

# Collects all unique characters used in the RenderDocument to simulate font subsetting.
# In a production environment, this would interface with an external tool (like fonttools)
# to strip unused glyphs from the embedded base64 font data, drastically reducing file size.

var _used_chars: Dictionary = {}

func collect_text(text: String) -> void:
    for char in text:
        _used_chars[char] = true

func get_subset_string() -> String:
    # Returns a sorted string of all unique characters encountered
    var chars = _used_chars.keys()
    chars.sort()
    return "".join(chars)

func get_subset_size() -> int:
    return _used_chars.size()