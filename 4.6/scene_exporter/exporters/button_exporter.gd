class_name ButtonExporter
extends ControlExporter

# Exporter for the Button family.

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
		elif sb is StyleBoxTexture:
			var img_obj = RenderImage.new()
			img_obj.node_name = info.node_name + "_bg_img"
			img_obj.rect = Rect2(Vector2.ZERO, info.size)
			if sb.texture:
				img_obj.resource_id = context.resource_resolver.register_resource(sb.texture)
			group.add_child(img_obj)
			
	var icon_tex = info.properties.get("icon", null)
	if icon_tex != null:
		var icon_img = RenderImage.new()
		icon_img.node_name = info.node_name + "_icon"
		var icon_size = icon_tex.get_size() if icon_tex is Texture2D else Vector2(16, 16)
		var icon_x = 8.0
		var icon_y = (info.size.y - icon_size.y) / 2.0
		icon_img.rect = Rect2(Vector2(icon_x, icon_y), icon_size)
		icon_img.resource_id = context.resource_resolver.register_resource(icon_tex)
		group.add_child(icon_img)

	var text_val = info.properties.get("text", "")
	if text_val != "":
		var text_obj = RenderText.new()
		text_obj.node_name = info.node_name + "_text"
		text_obj.text = text_val
		
		var font_size = info.resolved_theme.get("font_sizes", {}).get("font_size", 16)
		text_obj.style.font_size = font_size
		text_obj.style.font_resource_id = info.resolved_theme.get("fonts", {}).get("font", "")
		text_obj.style.text_color = info.resolved_theme.get("colors", {}).get("font_color", Color.WHITE)
		
		text_obj.alignment = "center"
		text_obj.position.x = info.size.x / 2.0
		# Improved vertical centering
		text_obj.position.y = (info.size.y / 2.0) + (font_size / 3.0)
		
		group.add_child(text_obj)
		
	return group
