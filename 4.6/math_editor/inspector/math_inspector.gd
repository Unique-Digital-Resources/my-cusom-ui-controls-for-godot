@tool
extends EditorInspectorPlugin

## Custom Inspector for the Math node.

const MathScript = preload("res://addons/math_editor/nodes/math.gd")

var _current_object: Object = null
var _formula_edit: TextEdit = null
var _format_option: OptionButton = null
var _error_label: Label = null

func _can_handle(object: Object) -> bool:
    return object != null and object.get_script() == MathScript

func _parse_begin(object: Object) -> void:
    _current_object = object

    var vbox := VBoxContainer.new()
    vbox.add_theme_constant_override("separation", 8)

    # ── Formula label + multi-line input ──────────────────────
    var formula_label := Label.new()
    formula_label.text = "Formula"
    vbox.add_child(formula_label)

    _formula_edit = TextEdit.new()
    _formula_edit.text = object.formula if object else ""
    _formula_edit.custom_minimum_size = Vector2(0, 80)
    _formula_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
    _formula_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    vbox.add_child(_formula_edit)

    # ── Import format label + dropdown ────────────────────────
    var format_label := Label.new()
    format_label.text = "Import Format"
    vbox.add_child(format_label)

    _format_option = OptionButton.new()
    _format_option.add_item("LaTeX", 0)
    _format_option.add_item("Plain Math", 1)
    _format_option.selected = int(object.import_format) if object else 0
    _format_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    vbox.add_child(_format_option)

    # ── Apply button ──────────────────────────────────────────
    var apply_button := Button.new()
    apply_button.text = "Apply"
    apply_button.pressed.connect(_on_apply_pressed)
    vbox.add_child(apply_button)

    # ── Error Display ─────────────────────────────────────────
    _error_label = Label.new()
    _error_label.text = "Status: OK"
    _error_label.add_theme_color_override("font_color", Color.LIME_GREEN)
    if object and object.last_error != "":
        _error_label.text = "Error:\n" + object.last_error
        _error_label.add_theme_color_override("font_color", Color.RED)
    _error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    vbox.add_child(_error_label)

    # ── Export section ────────────────────────────────────────
    vbox.add_child(HSeparator.new())
    
    var export_label := Label.new()
    export_label.text = "Export Hierarchy"
    vbox.add_child(export_label)
    
    var btn_latex := Button.new()
    btn_latex.text = "Copy LaTeX"
    btn_latex.pressed.connect(_on_copy_latex)
    vbox.add_child(btn_latex)
    
    var btn_json := Button.new()
    btn_json.text = "Copy JSON"
    btn_json.pressed.connect(_on_copy_json)
    vbox.add_child(btn_json)
    
    var btn_mathml := Button.new()
    btn_mathml.text = "Copy MathML"
    btn_mathml.pressed.connect(_on_copy_mathml)
    vbox.add_child(btn_mathml)

    # ── Visual separator before default properties ────────────
    vbox.add_child(HSeparator.new())

    add_custom_control(vbox)

func _parse_property(
        _object: Object,
        _type: Variant.Type,
        name: String,
        _hint_type: PropertyHint,
        _hint_string: String,
        _usage_flags: int,
        _wide: bool) -> bool:

    if name == "formula" or name == "import_format" or name == "last_error":
        return true
    return false

# ──────────────────────── Signal handlers ──────────────────────

func _on_apply_pressed() -> void:
    if not _current_object: 
        return
    if _formula_edit:
        _current_object.set("formula", _formula_edit.text)
    if _format_option:
        _current_object.set("import_format", _format_option.selected)
        
    if _current_object.has_method("rebuild"):
        _current_object.rebuild()
        
    # Update error label immediately
    if _error_label:
        var err = _current_object.get("last_error")
        if err == "":
            _error_label.text = "Status: OK"
            _error_label.add_theme_color_override("font_color", Color.LIME_GREEN)
        else:
            _error_label.text = "Error:\n" + err
            _error_label.add_theme_color_override("font_color", Color.RED)

func _on_copy_latex() -> void:
    if _current_object and _current_object.has_method("export_to_latex"):
        DisplayServer.clipboard_set(_current_object.export_to_latex())
        print("[MathEditor] LaTeX copied to clipboard.")

func _on_copy_json() -> void:
    if _current_object and _current_object.has_method("export_to_json"):
        DisplayServer.clipboard_set(_current_object.export_to_json())
        print("[MathEditor] JSON copied to clipboard.")

func _on_copy_mathml() -> void:
    if _current_object and _current_object.has_method("export_to_mathml"):
        DisplayServer.clipboard_set(_current_object.export_to_mathml())
        print("[MathEditor] MathML copied to clipboard.")