class_name HTMLWriter
extends RefCounted

# Converts the NodeInfo tree directly into Semantic HTML/CSS.
# Uses a separate <style> block for clean, readable CSS.
# Accurately maps Godot's Flex/Grid layout system to native CSS.

var resource_resolver: ResourceResolver
var settings: ExportSettings
var css_rules: PackedStringArray = PackedStringArray()
var anim_counter: int = 0

func _init(p_resolver: ResourceResolver, p_settings: ExportSettings):
	resource_resolver = p_resolver
	settings = p_settings

func write(root_info: NodeInfo) -> String:
	css_rules.clear()
	anim_counter = 0
	
	# Pre-collect all animations
	var anim_css = _collect_animations(root_info)
	
	# Build HTML tree and collect CSS rules
	var body_html = _write_node(root_info, 1)
	
	var head_css = "* { box-sizing: border-box; margin: 0; padding: 0; }\n"
	head_css += "html, body { width: 100%; height: 100%; overflow: hidden; background: #000; display: flex; justify-content: center; align-items: center; }\n"
	
	# Embed Fonts
	var resources = resource_resolver.get_all_resources()
	for key in resources:
		var res = resources[key]
		if res is Dictionary: res = res.res
		if res is Font and settings.embed_fonts:
			var base64 = resource_resolver.get_font_base64(res)
			if base64 != "":
				head_css += "@font-face { font-family: '%s'; src: url(data:font/ttf;base64,%s) format('truetype'); }\n" % [key, base64]
				
	head_css += "\n".join(css_rules)
	head_css += "\n" + anim_css
	
	var html = "<!DOCTYPE html>\n<html>\n<head>\n<meta charset=\"UTF-8\">\n<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n<style>\n%s\n</style>\n</head>\n<body>\n%s</body>\n</html>" % [head_css, body_html]
	return html

func _write_node(info: NodeInfo, indent: int) -> String:
	if not info.visibility.get("is_visible_in_tree", true):
		return ""
		
	var tabs = "\t".repeat(indent)
	var node_id = "node_%d" % info.node.get_instance_id()
	var node_class = "godot-%s" % info.node_type.to_lower()
	
	var style_str = _get_css_style(info)
	css_rules.append("#%s { %s }" % [node_id, style_str])
	
	var html = "%s<div id=\"%s\" class=\"%s\">\n" % [tabs, node_id, node_class]
	
	var inner_html = _get_inner_html(info)
	if inner_html != "":
		html += "%s\t%s\n" % [tabs, inner_html]
		
	for child in info.children_info:
		html += _write_node(child, indent + 1)
		
	html += "%s</div>\n" % tabs
	return html

func _get_inner_html(info: NodeInfo) -> String:
	if info.node_type in ["Label", "RichTextLabel", "Button", "LineEdit"]:
		var text_val = info.properties.get("text", "")
		if info.node_type == "RichTextLabel":
			text_val = info.node.text
			text_val = text_val.replace("[right]", "").replace("[/right]", "")
			text_val = text_val.replace("[center]", "").replace("[/center]", "")
			text_val = text_val.replace("[b]", "<b>").replace("[/b]", "</b>")
			text_val = text_val.replace("[font_size=24]", "<span style=\"font-size:24px\">").replace("[/font_size]", "</span>")
			text_val = text_val.replace("\n", "<br>")
		else:
			text_val = text_val.replace("\n", "<br>")
			
		var rtl_style = ""
		if _is_rtl(text_val):
			rtl_style = "direction: rtl; unicode-bidi: embed; "
			
		return "<div style=\"" + rtl_style + "max-width: 100%; white-space: pre-wrap; word-wrap: break-word; line-height: 1.5;\">" + text_val + "</div>"
	return ""

func _is_rtl(text: String) -> bool:
	for c in text:
		var code = c.unicode_at(0)
		if code >= 0x0600 and code <= 0x06FF:
			return true
	return false

func _get_css_style(info: NodeInfo) -> String:
	var parts: PackedStringArray = PackedStringArray()
	
	var parent_type = info.parent_info.node_type if info.parent_info else ""
	var is_parent_vertical = parent_type in ["VBoxContainer", "PanelContainer", "MarginContainer", "ScrollContainer"]
	var is_parent_horizontal = parent_type in ["HBoxContainer"]
	var is_grid_child = parent_type == "GridContainer"
	var is_parent_container = is_parent_vertical or is_parent_horizontal or is_grid_child
	
	# 1. Layout Mapping
	if info.parent_info == null:
		# Root node: fully responsive
		parts.append("width: 100%")
		parts.append("height: 100%")
		parts.append("display: flex")
		parts.append("flex-direction: column")
		parts.append("overflow: hidden")
		parts.append("position: relative")
	elif is_parent_container:
		parts.append("position: relative")
		var h_flags = info.properties.get("size_flags_horizontal", 1)
		var v_flags = info.properties.get("size_flags_vertical", 1)
		var min_size = info.properties.get("custom_minimum_size", Vector2.ZERO)
		var stretch = info.properties.get("size_flags_stretch_ratio", 1.0)
		
		# Fix: PanelContainer and MarginContainer automatically force their children to fill and expand
		if parent_type in ["PanelContainer", "MarginContainer"]:
			h_flags = 3 # FILL + EXPAND
			v_flags = 3 # FILL + EXPAND
			
		# In Godot: FILL (1) means fill the allocated area. EXPAND (2) means grow to consume extra space.
		var is_v_expand = (v_flags & 2) != 0
		var is_h_expand = (h_flags & 2) != 0
		var is_v_fill = (v_flags & 1) != 0
		var is_h_fill = (h_flags & 1) != 0
		var is_v_center = (v_flags & 4) != 0
		var is_h_center = (h_flags & 4) != 0
		var is_v_end = (v_flags & 8) != 0
		var is_h_end = (h_flags & 8) != 0
		
		var is_fit_content = info.node_type == "RichTextLabel" and info.properties.get("fit_content", false)
		if is_fit_content:
			is_v_expand = false
			is_v_fill = false
			is_h_fill = true # Ensure it fills horizontally
			
		if is_grid_child:
			if min_size.x > 0: parts.append("min-width: %.0fpx" % min_size.x)
			if min_size.y > 0: parts.append("min-height: %.0fpx" % min_size.y)
			# In Godot, grid children fill the cell unless SHRINK is set
			if not is_h_fill and not is_h_expand:
				if is_h_center: parts.append("justify-self: center")
				elif is_h_end: parts.append("justify-self: end")
				else: parts.append("justify-self: start")
			if not is_v_fill and not is_v_expand:
				if is_v_center: parts.append("align-self: center")
				elif is_v_end: parts.append("align-self: end")
				else: parts.append("align-self: start")
		else:
			if is_parent_vertical:
				# Main Axis (Y)
				if is_v_expand:
					parts.append("flex: %.2f 1 0%%" % stretch)
				else:
					# Fix: FILL without EXPAND should take minimum size, but can shrink
					parts.append("flex: 0 1 auto")
					
				if min_size.y > 0: parts.append("min-height: %.0fpx" % min_size.y)
					
				# Cross Axis (X)
				if is_h_fill or is_h_expand: 
					parts.append("align-self: stretch")
				else:
					if is_h_center: parts.append("align-self: center")
					elif is_h_end: parts.append("align-self: flex-end")
					else: parts.append("align-self: flex-start")
					
				if min_size.x > 0: parts.append("min-width: %.0fpx" % min_size.x)
					
			elif is_parent_horizontal:
				# Main Axis (X)
				if is_h_expand:
					parts.append("flex: %.2f 1 0%%" % stretch)
				else:
					parts.append("flex: 0 1 auto")
					
				if min_size.x > 0: parts.append("min-width: %.0fpx" % min_size.x)
					
				# Cross Axis (Y)
				if is_v_fill or is_v_expand: 
					parts.append("align-self: stretch")
				else:
					if is_v_center: parts.append("align-self: center")
					elif is_v_end: parts.append("align-self: flex-end")
					else: parts.append("align-self: flex-start")
					
				if min_size.y > 0: parts.append("min-height: %.0fpx" % min_size.y)
	else:
		# Anchors (Absolute Positioning)
		var parent_size = info.parent_info.size
		var a_left = info.properties.get("anchor_left", 0.0)
		var a_top = info.properties.get("anchor_top", 0.0)
		var a_right = info.properties.get("anchor_right", 1.0)
		var a_bottom = info.properties.get("anchor_bottom", 1.0)
		var o_left = info.properties.get("offset_left", 0.0)
		var o_top = info.properties.get("offset_top", 0.0)
		var o_right = info.properties.get("offset_right", 0.0)
		var o_bottom = info.properties.get("offset_bottom", 0.0)
		
		var is_full_rect = (a_left == 0.0 and a_top == 0.0 and a_right == 1.0 and a_bottom == 1.0)
		
		parts.append("position: absolute")
		if is_full_rect:
			parts.append("left: 0")
			parts.append("top: 0")
			parts.append("width: 100%")
			parts.append("height: 100%")
		else:
			var left = a_left * parent_size.x + o_left
			var top = a_top * parent_size.y + o_top
			var width = (a_right - a_left) * parent_size.x - (o_right + o_left)
			var height = (a_bottom - a_top) * parent_size.y - (o_bottom + o_top)
			
			parts.append("left: %.2fpx" % left)
			parts.append("top: %.2fpx" % top)
			if width > 0: parts.append("width: %.2fpx" % width)
			if height > 0: parts.append("height: %.2fpx" % height)
		
	# 2. Container Types
	match info.node_type:
		"HBoxContainer":
			parts.append("display: flex")
			parts.append("flex-direction: row")
			var sep = info.resolved_theme.get("constants", {}).get("separation", 0)
			if sep > 0: parts.append("gap: %dpx" % sep)
			var align = info.properties.get("alignment", 0)
			match align:
				1: parts.append("justify-content: center")
				2: parts.append("justify-content: flex-end")
				_: parts.append("justify-content: flex-start")
		"VBoxContainer":
			parts.append("display: flex")
			parts.append("flex-direction: column")
			var sep = info.resolved_theme.get("constants", {}).get("separation", 0)
			if sep > 0: parts.append("gap: %dpx" % sep)
			var align = info.properties.get("alignment", 0)
			match align:
				1: parts.append("justify-content: center")
				2: parts.append("justify-content: flex-end")
				_: parts.append("justify-content: flex-start")
		"GridContainer":
			parts.append("display: grid")
			var cols = info.properties.get("columns", 1)
			parts.append("grid-template-columns: repeat(%d, 1fr)" % cols)
			var h_sep = info.resolved_theme.get("constants", {}).get("h_separation", 0)
			var v_sep = info.resolved_theme.get("constants", {}).get("v_separation", 0)
			if h_sep > 0 or v_sep > 0:
				parts.append("gap: %dpx %dpx" % [v_sep, h_sep])
		"MarginContainer":
			var m_left = info.resolved_theme.get("constants", {}).get("margin_left", 0)
			var m_top = info.resolved_theme.get("constants", {}).get("margin_top", 0)
			var m_right = info.resolved_theme.get("constants", {}).get("margin_right", 0)
			var m_bottom = info.resolved_theme.get("constants", {}).get("margin_bottom", 0)
			parts.append("padding: %dpx %dpx %dpx %dpx" % [m_top, m_right, m_bottom, m_left])
			parts.append("display: flex")
			parts.append("flex-direction: column")
		"PanelContainer":
			var sb_id = info.resolved_theme.get("styleboxes", {}).get("panel", "")
			if sb_id != "" and sb_id != "null":
				var sb = resource_resolver.get_resource(sb_id)
				if sb is StyleBoxFlat:
					if sb.bg_color.a > 0:
						parts.append("background-color: rgba(%d, %d, %d, %.3f)" % [int(sb.bg_color.r*255), int(sb.bg_color.g*255), int(sb.bg_color.b*255), sb.bg_color.a])
					if sb.corner_radius_top_left > 0: parts.append("border-radius: %dpx" % sb.corner_radius_top_left)
					
					# Fix: Handle non-uniform borders correctly for PanelContainer
					var border_color_str = "rgba(%d, %d, %d, %.3f)" % [int(sb.border_color.r*255), int(sb.border_color.g*255), int(sb.border_color.b*255), sb.border_color.a]
					if sb.border_width_left > 0 and sb.border_width_left == sb.border_width_right and sb.border_width_right == sb.border_width_top and sb.border_width_top == sb.border_width_bottom:
						parts.append("border: %dpx solid %s" % [sb.border_width_left, border_color_str])
					else:
						if sb.border_width_left > 0: parts.append("border-left: %dpx solid %s" % [sb.border_width_left, border_color_str])
						if sb.border_width_right > 0: parts.append("border-right: %dpx solid %s" % [sb.border_width_right, border_color_str])
						if sb.border_width_top > 0: parts.append("border-top: %dpx solid %s" % [sb.border_width_top, border_color_str])
						if sb.border_width_bottom > 0: parts.append("border-bottom: %dpx solid %s" % [sb.border_width_bottom, border_color_str])
						
					if sb.shadow_size > 0:
						parts.append("box-shadow: %.0fpx %.0fpx %.0fpx rgba(%d, %d, %d, %.3f)" % [sb.shadow_offset.x, sb.shadow_offset.y, sb.shadow_size, int(sb.shadow_color.r*255), int(sb.shadow_color.g*255), int(sb.shadow_color.b*255), sb.shadow_color.a])
						
					var m_left = sb.content_margin_left
					var m_top = sb.content_margin_top
					var m_right = sb.content_margin_right
					var m_bottom = sb.content_margin_bottom
					if m_left > 0 or m_top > 0 or m_right > 0 or m_bottom > 0:
						parts.append("padding: %dpx %dpx %dpx %dpx" % [m_top, m_right, m_bottom, m_left])
			parts.append("display: flex")
			parts.append("flex-direction: column")
			
	# 3. Visual Elements
	if info.node_type in ["Panel", "ColorRect", "NinePatchRect"]:
		if info.node_type == "ColorRect":
			var c = info.properties.get("color", Color.WHITE)
			parts.append("background-color: rgba(%d, %d, %d, %.3f)" % [int(c.r*255), int(c.g*255), int(c.b*255), c.a])
		else:
			var sb_id = info.resolved_theme.get("styleboxes", {}).get("panel", "")
			if sb_id != "" and sb_id != "null":
				var sb = resource_resolver.get_resource(sb_id)
				if sb is StyleBoxFlat:
					if sb.bg_color.a > 0:
						parts.append("background-color: rgba(%d, %d, %d, %.3f)" % [int(sb.bg_color.r*255), int(sb.bg_color.g*255), int(sb.bg_color.b*255), sb.bg_color.a])
						
					var border_color_str = "rgba(%d, %d, %d, %.3f)" % [int(sb.border_color.r*255), int(sb.border_color.g*255), int(sb.border_color.b*255), sb.border_color.a]
					if sb.border_width_left > 0 and sb.border_width_left == sb.border_width_right and sb.border_width_right == sb.border_width_top and sb.border_width_top == sb.border_width_bottom:
						parts.append("border: %dpx solid %s" % [sb.border_width_left, border_color_str])
					else:
						if sb.border_width_left > 0: parts.append("border-left: %dpx solid %s" % [sb.border_width_left, border_color_str])
						if sb.border_width_right > 0: parts.append("border-right: %dpx solid %s" % [sb.border_width_right, border_color_str])
						if sb.border_width_top > 0: parts.append("border-top: %dpx solid %s" % [sb.border_width_top, border_color_str])
						if sb.border_width_bottom > 0: parts.append("border-bottom: %dpx solid %s" % [sb.border_width_bottom, border_color_str])
						
					if sb.corner_radius_top_left > 0:
						parts.append("border-radius: %dpx" % sb.corner_radius_top_left)
					if sb.shadow_size > 0:
						parts.append("box-shadow: %.0fpx %.0fpx %.0fpx rgba(%d, %d, %d, %.3f)" % [sb.shadow_offset.x, sb.shadow_offset.y, sb.shadow_size, int(sb.shadow_color.r*255), int(sb.shadow_color.g*255), int(sb.shadow_color.b*255), sb.shadow_color.a])
						
	elif info.node_type in ["Label", "RichTextLabel", "Button", "LineEdit"]:
		var sb_id = info.resolved_theme.get("styleboxes", {}).get("normal", "")
		if sb_id != "" and sb_id != "null":
			var sb = resource_resolver.get_resource(sb_id)
			if sb is StyleBoxFlat:
				if sb.bg_color.a > 0:
					parts.append("background-color: rgba(%d, %d, %d, %.3f)" % [int(sb.bg_color.r*255), int(sb.bg_color.g*255), int(sb.bg_color.b*255), sb.bg_color.a])
				if sb.corner_radius_top_left > 0: parts.append("border-radius: %dpx" % sb.corner_radius_top_left)
				var m_left = sb.content_margin_left
				var m_top = sb.content_margin_top
				var m_right = sb.content_margin_right
				var m_bottom = sb.content_margin_bottom
				if m_left > 0 or m_top > 0 or m_right > 0 or m_bottom > 0:
					parts.append("padding: %dpx %dpx %dpx %dpx" % [m_top, m_right, m_bottom, m_left])
					
		var font_size = info.resolved_theme.get("font_sizes", {}).get("font_size", 16)
		if info.node_type == "RichTextLabel":
			font_size = info.resolved_theme.get("font_sizes", {}).get("normal_font_size", 16)
			
		parts.append("font-size: %dpx" % font_size)
		var txt_color = info.resolved_theme.get("colors", {}).get("font_color", Color.BLACK)
		if info.node_type == "RichTextLabel":
			txt_color = info.resolved_theme.get("colors", {}).get("default_color", Color.BLACK)
		parts.append("color: rgba(%d, %d, %d, %.3f)" % [int(txt_color.r*255), int(txt_color.g*255), int(txt_color.b*255), txt_color.a])
		parts.append("font-family: 'Open Sans SemiBold', sans-serif")
		
		var h_align = info.properties.get("horizontal_alignment", 0)
		var v_align = info.properties.get("vertical_alignment", 1)
		
		parts.append("display: flex")
		parts.append("flex-direction: row")
		
		match v_align:
			0: parts.append("align-items: flex-start")
			1: parts.append("align-items: center")
			2: parts.append("align-items: flex-end")
			
		var is_rtl_right = false
		var text_val = info.properties.get("text", "")
		if info.node_type == "RichTextLabel":
			text_val = info.node.text
			
		if info.node_type == "RichTextLabel" and "[right]" in info.node.text:
			is_rtl_right = true
			
		if is_rtl_right:
			parts.append("justify-content: flex-end")
			parts.append("text-align: right")
		else:
			match h_align:
				1: parts.append("justify-content: center"); parts.append("text-align: center")
				2: parts.append("justify-content: flex-end"); parts.append("text-align: right")
				_: parts.append("justify-content: flex-start"); parts.append("text-align: left")
			
	# Modulate (Opacity)
	var modulate = info.properties.get("modulate", Color.WHITE)
	# Fix: Only apply opacity if it's not completely invisible. 
	# This prevents elements with initial fade-in animations from being hidden permanently in static exports.
	if modulate.a < 1.0 and modulate.a > 0.001:
		parts.append("opacity: %.3f" % modulate.a)
		
	return "; ".join(parts) + ";"

func _collect_animations(info: NodeInfo) -> String:
	var css: PackedStringArray = PackedStringArray()
	_traverse_animations(info, css)
	return "".join(css)

func _traverse_animations(info: NodeInfo, css: PackedStringArray):
	if settings.export_animations and info.animations.size() > 0:
		var node_id = "node_%d" % info.node.get_instance_id()
		var anim_name = "anim_%d" % anim_counter
		anim_counter += 1
		css.append(_generate_css_animation(info, anim_name, node_id))
	for child in info.children_info:
		_traverse_animations(child, css)

func _generate_css_animation(info: NodeInfo, anim_name: String, node_id: String) -> String:
	var keyframes_dict: Dictionary = {}
	var duration = 1.0
	var loop = true
	
	for anim in info.animations:
		duration = anim.duration
		loop = anim.loop
		if duration <= 0: continue
		
		for key in anim.keyframes:
			var t = key.time / duration
			if not keyframes_dict.has(t):
				keyframes_dict[t] = {}
				
			var val = key.value
			match anim.target_property:
				"transform.translate":
					if val is Vector2:
						keyframes_dict[t]["left"] = "%.2fpx" % val.x
						keyframes_dict[t]["top"] = "%.2fpx" % val.y
				"transform.translate.x":
					keyframes_dict[t]["left"] = "%.2fpx" % val
				"transform.translate.y":
					keyframes_dict[t]["top"] = "%.2fpx" % val
				"transform.rotate":
					keyframes_dict[t]["transform"] = (keyframes_dict[t].get("transform", "") + " rotate(%.2fdeg)" % rad_to_deg(val)).strip_edges()
				"transform.scale":
					if val is Vector2:
						keyframes_dict[t]["transform"] = (keyframes_dict[t].get("transform", "") + " scale(%.2f, %.2f)" % [val.x, val.y]).strip_edges()
				"opacity":
					keyframes_dict[t]["opacity"] = "%.3f" % val
				"fill":
					keyframes_dict[t]["background-color"] = "#%s" % val.to_html(false)
					
	var keyframes_str = "@keyframes %s {\n" % anim_name
	var times = keyframes_dict.keys()
	times.sort()
	
	for t in times:
		var percent = int(t * 100)
		var props = keyframes_dict[t]
		var props_str = ""
		for prop in props:
			props_str += "%s: %s; " % [prop, props[prop]]
		keyframes_str += "  %d%% { %s}\n" % [percent, props_str]
		
	keyframes_str += "}\n"
	
	var loop_str = "infinite" if loop else "1"
	var anim_class_str = "#%s { animation: %s %.2fs ease-in-out %s; }\n" % [node_id, anim_name, duration, loop_str]
	
	return keyframes_str + anim_class_str
