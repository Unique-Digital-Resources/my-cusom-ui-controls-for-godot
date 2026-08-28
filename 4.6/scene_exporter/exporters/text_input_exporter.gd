class_name TextInputExporter
extends ControlExporter

# Exporter for LineEdit, TextEdit, and CodeEdit.

func export_node(info: NodeInfo, context: ExportContext) -> RenderGroup:
	var group = super.export_node(info, context)
	
	var sb_id = info.resolved_theme.get("styleboxes", {}).get("normal", "")
	if sb_id != "" and sb_id != "null":
		var sb = context.resource_resolver.get_resource(sb_id)
		if sb is StyleBoxFlat:
			var shape = RenderShape.new()
			shape.node_name = info.node_name + "_bg"
			shape.shape_type = "rounded_rect" if sb.corner_radius_top_left > 0 else "rect"
			shape.rect = Rect2(Vector2.ZERO, info.size)
			shape.style.fill_color = sb.bg_color
			shape.style.stroke_color = sb.border_color
			shape.style.stroke_width = sb.border_width_bottom
			shape.corner_radius = sb.corner_radius_top_left
			group.add_child(shape)
			
	var text_val = info.properties.get("text", "")
	if text_val == "":
		text_val = info.properties.get("placeholder_text", "")
		
	if text_val != "":
		var text_obj = RenderText.new()
		text_obj.node_name = info.node_name + "_text"
		text_obj.text = text_val.split("\n")[0] 
		
		var font_size = info.resolved_theme.get("font_sizes", {}).get("font_size", 16)
		text_obj.style.font_size = font_size
		text_obj.style.font_resource_id = info.resolved_theme.get("fonts", {}).get("font", "")
		
		if info.properties.get("text", "") == "":
			text_obj.style.text_color = info.resolved_theme.get("colors", {}).get("font_placeholder_color", Color.GRAY)
		else:
			text_obj.style.text_color = info.resolved_theme.get("colors", {}).get("font_color", Color.WHITE)
			
		text_obj.alignment = "left"
		text_obj.position.x = 8.0
		text_obj.position.y = font_size * 1.2
		
		group.add_child(text_obj)
		
	return group
