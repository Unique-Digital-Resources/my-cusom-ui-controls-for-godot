class_name AIDocument
extends RefCounted

## Base document abstraction.
## Formats (Layout, Animation, etc.) will inherit from this or use it as a data container.

enum Format {
    LAYOUT,
    ANIMATION,
    TWEEN,
    INTERACTION,
    COMBINED
}

var format: int = Format.LAYOUT
var scene_model: AISceneModel = null
var raw_text: String = ""

func _init(model: AISceneModel = null, fmt: int = Format.LAYOUT) -> void:
    scene_model = model
    format = fmt