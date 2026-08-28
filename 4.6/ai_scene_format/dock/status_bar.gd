@tool
extends HBoxContainer

## Errors, warnings and sync status bar.
## Upgraded in Phase 10 to display formatted validation issues.

var status_label: Label
var error_label: Label
var error_icon: TextureRect

func _ready() -> void:
    alignment = BoxContainer.ALIGNMENT_BEGIN
    
    status_label = Label.new()
    status_label.text = "Ready"
    status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    add_child(status_label)
    
    error_label = Label.new()
    error_label.text = ""
    error_label.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
    add_child(error_label)

func set_status(text: String) -> void:
    status_label.text = text
    status_label.add_theme_color_override("font_color", Color(0.7, 0.8, 0.7))

func set_errors(issues: Array) -> void:
    if issues.is_empty():
        error_label.text = ""
        return
        
    var errors = 0
    var warnings = 0
    for issue in issues:
        if issue.severity == 0: errors += 1
        else: warnings += 1
        
    var txt = ""
    if errors > 0: txt += "%d Error(s) " % errors
    if warnings > 0: txt += "%d Warning(s)" % warnings
    error_label.text = txt

func show_specific_issue(issue) -> void:
    # In a full UI, clicking the status bar would jump to the line
    status_label.text = "Line %d: %s" % [issue.line, issue.message]
    status_label.add_theme_color_override("font_color", Color(1, 0.8, 0.4))