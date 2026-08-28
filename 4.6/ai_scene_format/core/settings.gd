class_name AISettings
extends RefCounted

## Plugin settings configuration.
## Reads from and writes to Godot's ProjectSettings or EditorSettings.

const SETTING_PREFIX = "ai_scene_format/"

var generate_defaults: bool = false
var indent_size: int = 4
var max_recursion_depth: int = -1 # -1 means no limit

func load_settings() -> void:
    # In Phase 10+, we will hook this up to ProjectSettings
    # For now, these act as the internal defaults.
    pass

func save_settings() -> void:
    pass