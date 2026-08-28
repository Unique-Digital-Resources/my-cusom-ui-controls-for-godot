class_name SvgVectorExporter
extends ControlExporter

# Exporter for SvgVectorControl.
# Extracts the raw SVG string, applies vector overrides, and modifies the <svg> tag
# to fit the control's bounds perfectly while preserving all vector styles.

func export_node(info: NodeInfo, context: ExportContext) -> RenderGroup:
	var group = super.export_node(info, context)
	
	# Check if the node has the 'svg_path' property
	if info.properties.has("svg_path"):
		var path = info.properties.get("svg_path", "")
		
		if path != "" and FileAccess.file_exists(path):
			var src = FileAccess.get_file_as_string(path)
			if src != "":
				# Apply the exact same overrides as SvgVectorControl
				var override_fill = info.properties.get("override_fill", true)
				var fill_color = info.properties.get("fill_color", Color.WHITE)
				var override_stroke = info.properties.get("override_stroke", false)
				var stroke_color = info.properties.get("stroke_color", Color.BLACK)
				var stroke_width = info.properties.get("stroke_width", 1.0)
				
				if override_fill:
					src = _set_attr(src, "fill", _color_to_svg_str(fill_color))
				if override_stroke:
					src = _set_attr(src, "stroke", _color_to_svg_str(stroke_color))
					src = _set_attr(src, "stroke-width", str(stroke_width))
					
				# Fix: Overwrite the opening <svg> tag to force the correct width and height
				# while preserving the viewBox and styling attributes.
				var re_open = RegEx.new()
				re_open.compile("<svg([^>]*)>")
				var match = re_open.search(src)
				if match:
					var original_attrs = match.get_string(1)
					
					# Remove existing width, height, preserveAspectRatio to avoid conflicts
					var re_clean = RegEx.new()
					re_clean.compile("\\s(width|height|preserveAspectRatio)\\s*=\\s*(\"[^\"]*\"|'[^']*')")
					var cleaned_attrs = re_clean.sub(original_attrs, "", true)
					
					var dest_size = info.size
					if dest_size.x <= 0 or dest_size.y <= 0:
						dest_size = info.properties.get("custom_minimum_size", Vector2(24, 24))
					if dest_size.x <= 0 or dest_size.y <= 0:
						dest_size = Vector2(24, 24)
						
					# Create new opening tag with forced dimensions
					var new_open_tag = "<svg" + cleaned_attrs + " width=\"%.2f\" height=\"%.2f\" x=\"0\" y=\"0\">" % [dest_size.x, dest_size.y]
					src = re_open.sub(src, new_open_tag, true)
					
					var svg_obj = RenderSVG.new()
					svg_obj.node_name = info.node_name + "_svg"
					svg_obj.svg_data = src
					group.add_child(svg_obj)
				
	return group

# Fix: Convert Color to rgba() string if alpha is present, to prevent brightness loss
func _color_to_svg_str(c: Color) -> String:
	if c.a < 1.0:
		return "rgba(%d, %d, %d, %f)" % [int(c.r * 255), int(c.g * 255), int(c.b * 255), c.a]
	else:
		return "#" + c.to_html(false)

func _set_attr(svg: String, attr: String, value: String) -> String:
	var re := RegEx.new()
	re.compile("(?i)(\\b%s\\s*=\\s*)(\"[^\"]*\"|'[^']*')" % attr)
	return re.sub(svg, '$1"%s"' % value, true)
