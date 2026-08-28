class_name ThemeResolver
extends RefCounted

# Resolves every visual style for a Control, including inherited themes and overrides.

var resource_resolver: ResourceResolver

# Predefined lists of common theme properties to query
const COLOR_PROPS: Array[String] = ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color", "font_placeholder_color", "font_selected_color", "default_color"]
const CONSTANT_PROPS: Array[String] = [
	"separation", "h_separation", "v_separation", # Fix: Added GridContainer separations
	"margin_left", "margin_top", "margin_right", "margin_bottom", 
	"outline_size", "shadow_offset_x", "shadow_offset_y"
]
const FONT_PROPS: Array[String] = ["font", "normal_font"]
const FONT_SIZE_PROPS: Array[String] = ["font_size", "normal_font_size"]
const ICON_PROPS: Array[String] = ["checked", "unchecked", "radio_checked", "radio_unchecked", "arrow", "close", "add"]
const STYLEBOX_PROPS: Array[String] = ["panel", "normal", "hover", "pressed", "focus", "disabled", "read_only"]

func _init(res_resolver: ResourceResolver):
	resource_resolver = res_resolver

func resolve(node: Control) -> Dictionary:
	var theme_type = node.get("theme_type_variation") if "theme_type_variation" in node else ""
	if theme_type == "" or theme_type == &"":
		theme_type = node.get_class()
		
	var resolved: Dictionary = {
		"colors": {},
		"constants": {},
		"fonts": {}, 
		"font_sizes": {},
		"icons": {}, 
		"styleboxes": {}
	}
	
	# Query Colors
	for prop in COLOR_PROPS:
		if node.has_theme_color(prop, theme_type):
			resolved.colors[prop] = node.get_theme_color(prop, theme_type)
			
	# Query Constants
	for prop in CONSTANT_PROPS:
		if node.has_theme_constant(prop, theme_type):
			resolved.constants[prop] = node.get_theme_constant(prop, theme_type)
			
	# Query Fonts
	for prop in FONT_PROPS:
		if node.has_theme_font(prop, theme_type):
			var font = node.get_theme_font(prop, theme_type)
			resolved.fonts[prop] = resource_resolver.register_resource(font)
			
	# Query Font Sizes
	for prop in FONT_SIZE_PROPS:
		if node.has_theme_font_size(prop, theme_type):
			resolved.font_sizes[prop] = node.get_theme_font_size(prop, theme_type)
			
	# Query Icons
	for prop in ICON_PROPS:
		if node.has_theme_icon(prop, theme_type):
			var icon = node.get_theme_icon(prop, theme_type)
			resolved.icons[prop] = resource_resolver.register_resource(icon)
			
	# Query StyleBoxes
	for prop in STYLEBOX_PROPS:
		if node.has_theme_stylebox(prop, theme_type):
			var sb = node.get_theme_stylebox(prop, theme_type)
			resolved.styleboxes[prop] = resource_resolver.register_resource(sb)
			
	return resolved
