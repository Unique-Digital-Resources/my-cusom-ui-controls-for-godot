class_name RenderContext
extends RefCounted

## Passed down the Control hierarchy during the layout passes.

var font: Font
var font_italic: Font
var font_bold: Font
var font_bold_italic: Font
var font_blackboard: Font
var font_caligraphic: Font

var base_size: float
var current_scale: float = 1.0
var color: Color = Color.WHITE

var item_spacing: float = 0.3
var script_spacing: float = 0.2
var limit_gap: float = 0.0
var script_scale: float = 0.7
var line_thickness: float = 0.06

var font_forced: bool = false
# NEW: Tells SymbolControl to map text to Unicode if no dedicated font is provided
var style_override: String = "" 

func _init(
		p_font: Font = null, 
		p_font_italic: Font = null, 
		p_font_bold: Font = null, 
		p_font_bold_italic: Font = null, 
		p_font_blackboard: Font = null, 
		p_font_caligraphic: Font = null, 
		p_base_size: float = 32.0, 
		p_color: Color = Color.WHITE, 
		p_item_spacing: float = 0.3, 
		p_script_spacing: float = 0.2, 
		p_limit_gap: float = 0.0, 
		p_script_scale: float = 0.7, 
		p_line_thickness: float = 0.06) -> void:
	font = p_font
	font_italic = p_font_italic
	font_bold = p_font_bold
	font_bold_italic = p_font_bold_italic
	font_blackboard = p_font_blackboard
	font_caligraphic = p_font_caligraphic
	base_size = p_base_size
	color = p_color
	item_spacing = p_item_spacing
	script_spacing = p_script_spacing
	limit_gap = p_limit_gap
	script_scale = p_script_scale
	line_thickness = p_line_thickness

func get_font_size() -> int:
	return int(base_size * current_scale)

func get_scaled_context(scale_factor: float) -> RenderContext:
	var ctx = copy()
	ctx.current_scale = current_scale * scale_factor
	return ctx

func copy() -> RenderContext:
	var ctx = RenderContext.new(
		font, font_italic, font_bold, font_bold_italic, font_blackboard, font_caligraphic,
		base_size, color, item_spacing, script_spacing, limit_gap, script_scale, line_thickness
	)
	ctx.current_scale = current_scale
	ctx.font_forced = font_forced
	ctx.style_override = style_override
	return ctx
