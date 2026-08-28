@tool
class_name MathElement
extends Control

## Base class for ALL mathematical controls.

var measured_size: Vector2 = Vector2.ZERO
var baseline: float = 0.0
var _layout_dirty: bool = true

func _ready() -> void:
    resized.connect(_on_resized)

func _on_resized() -> void:
    pass

## Marks this element (and parents) as needing a layout pass.
func set_dirty() -> void:
    if _layout_dirty:
        return
    _layout_dirty = true
    var parent = get_parent()
    if parent is MathElement:
        parent.set_dirty()

func is_dirty() -> bool:
    return _layout_dirty

## Pass 1: Calculate width, height, and baseline.
func measure(context: RenderContext) -> void:
    _layout_dirty = false
    pass

## Pass 2: Position children and draw.
func arrange(context: RenderContext, pos: Vector2) -> void:
    position = pos
    pass