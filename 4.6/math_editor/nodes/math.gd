@tool
extends Control

## Root Math Control node.

enum ImportFormat { LATEX, PLAIN_MATH }

const LatexImporterScript = preload("res://addons/math_editor/parser/latex_importer.gd")
const PlainMathImporterScript = preload("res://addons/math_editor/parser/plain_math_importer.gd")
const ControlGeneratorScript = preload("res://addons/math_editor/generator/control_generator.gd")
const LayoutEngineScript = preload("res://addons/math_editor/layout/layout_engine.gd")
const RenderContextScript = preload("res://addons/math_editor/layout/render_context.gd")
const MathNodeUtilsScript = preload("res://addons/math_editor/utils/node_utils.gd")

const LatexExporterScript = preload("res://addons/math_editor/serialization/latex_exporter.gd")
const JsonExporterScript = preload("res://addons/math_editor/serialization/json_exporter.gd")
const MathMLExporterScript = preload("res://addons/math_editor/serialization/mathml_exporter.gd")

@export var formula: String = "":
	set(value):
		if formula != value:
			formula = value
			_needs_rebuild = true

@export var import_format: ImportFormat = ImportFormat.LATEX:
	set(value):
		if import_format != value:
			import_format = value
			_needs_rebuild = true

@export_group("Fonts")
@export var font: FontFile:
	set(value):
		if font != value:
			font = value
			_needs_relayout = true

@export var font_italic: FontFile:
	set(value):
		if font_italic != value:
			font_italic = value
			_needs_relayout = true

@export var font_bold: FontFile:
	set(value):
		if font_bold != value:
			font_bold = value
			_needs_relayout = true

@export var font_bold_italic: FontFile:
	set(value):
		if font_bold_italic != value:
			font_bold_italic = value
			_needs_relayout = true

# NEW: Blackboard Bold Font
@export var font_blackboard: FontFile:
	set(value):
		if font_blackboard != value:
			font_blackboard = value
			_needs_relayout = true

# NEW: Caligraphic Font
@export var font_caligraphic: FontFile:
	set(value):
		if font_caligraphic != value:
			font_caligraphic = value
			_needs_relayout = true

@export_group("Typography")
@export_range(8.0, 256.0, 1.0) var base_size: float = 32.0:
	set(value):
		if base_size != value:
			base_size = value
			_needs_relayout = true

@export var color: Color = Color.WHITE:
	set(value):
		if color != value:
			color = value
			_needs_relayout = true

@export_group("Spacing & Sizing")
@export_range(0.0, 2.0, 0.01) var item_spacing: float = 0.3:
	set(value):
		if item_spacing != value:
			item_spacing = value
			_needs_relayout = true

@export_range(0.0, 2.0, 0.01) var script_spacing: float = 0.2:
	set(value):
		if script_spacing != value:
			script_spacing = value
			_needs_relayout = true

@export_range(-0.5, 1.0, 0.01) var limit_gap: float = 0.0:
	set(value):
		if limit_gap != value:
			limit_gap = value
			_needs_relayout = true

@export_range(0.5, 0.9, 0.01) var script_scale: float = 0.7:
	set(value):
		if script_scale != value:
			script_scale = value
			_needs_relayout = true

@export_range(0.01, 0.2, 0.01) var line_thickness: float = 0.06:
	set(value):
		if line_thickness != value:
			line_thickness = value
			_needs_relayout = true

@export var last_error: String = "":
	set(value):
		if last_error != value:
			last_error = value
			notify_property_list_changed()

var _needs_rebuild: bool = true
var _needs_relayout: bool = true

func _ready() -> void:
	if Engine.is_editor_hint():
		_needs_rebuild = true
		set_process(true)

func _process(delta: float) -> void:
	if not _needs_rebuild and not _needs_relayout:
		set_process(false)
		return
		
	if _needs_rebuild:
		_needs_rebuild = false
		rebuild()
	elif _needs_relayout:
		_needs_relayout = false
		_relayout()

func rebuild() -> void:
	last_error = ""
	MathNodeUtilsScript.clear_children(self)
	
	if formula.is_empty():
		return
		
	var result: Dictionary
	if import_format == ImportFormat.LATEX:
		result = LatexImporterScript.parse(formula)
	else:
		result = PlainMathImporterScript.parse(formula)
		
	if result.errors.size() > 0:
		last_error = "\n".join(result.errors)
		printerr("[MathEditor] ", last_error)
		_needs_relayout = false
		return
		
	var ast: MathAST = result.ast
	if not ast:
		return
		
	var generated_root = ControlGeneratorScript.generate(ast)
	if generated_root:
		generated_root.name = "GeneratedRoot"
		add_child(generated_root)
		
		if Engine.is_editor_hint():
			MathNodeUtilsScript.set_owner_recursive(generated_root, get_tree().edited_scene_root)
			
		_relayout()

func _relayout() -> void:
	if not is_inside_tree(): 
		return
	var root = get_node_or_null("GeneratedRoot")
	if not root: 
		return
		
	var active_font = font if font else get_theme_default_font()
	var active_italic = font_italic if font_italic else active_font
	var active_bold = font_bold if font_bold else active_font
	var active_bi = font_bold_italic if font_bold_italic else active_bold
	var active_bb = font_blackboard if font_blackboard else active_font
	var active_cal = font_caligraphic if font_caligraphic else active_font
		
	var context = RenderContextScript.new(
		active_font, 
		active_italic, 
		active_bold, 
		active_bi,
		active_bb,
		active_cal,
		base_size, 
		color, 
		item_spacing, 
		script_spacing,
		limit_gap,
		script_scale, 
		line_thickness
	)
	LayoutEngineScript.layout(root, context)
	queue_redraw()

func export_to_latex() -> String:
	var root = get_node_or_null("GeneratedRoot")
	if root: 
		return LatexExporterScript.export(root)
	return ""

func export_to_json() -> String:
	var root = get_node_or_null("GeneratedRoot")
	if root: 
		return JsonExporterScript.export(root)
	return "{}"

func export_to_mathml() -> String:
	var root = get_node_or_null("GeneratedRoot")
	if root: 
		return MathMLExporterScript.export(root)
	return "<math></math>"

func _get_property_list() -> Array[Dictionary]:
	var props: Array[Dictionary] = []
	props.append({
		"name": "last_error",
		"type": TYPE_STRING,
		"usage": PROPERTY_USAGE_NO_EDITOR
	})
	return props
