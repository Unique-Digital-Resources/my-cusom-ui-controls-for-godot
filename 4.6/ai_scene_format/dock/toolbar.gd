@tool
extends HBoxContainer

## Toolbar actions.
## Upgraded in Phase 10 to include Format and Validate buttons.

signal format_requested
signal validate_requested
signal apply_requested

func _ready() -> void:
    for child in get_children():
        child.queue_free()
        
    var validate_btn = Button.new()
    validate_btn.text = "Validate"
    validate_btn.tooltip_text = "Check document for errors"
    validate_btn.pressed.connect(func(): validate_requested.emit())
    add_child(validate_btn)
    
    var format_btn = Button.new()
    format_btn.text = "Format"
    format_btn.tooltip_text = "Auto-format document"
    format_btn.pressed.connect(func(): format_requested.emit())
    add_child(format_btn)
    
    var apply_btn = Button.new()
    apply_btn.text = "Apply to Scene"
    apply_btn.tooltip_text = "Apply changes to Godot Scene"
    apply_btn.pressed.connect(func(): apply_requested.emit())
    add_child(apply_btn)