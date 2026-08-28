class_name ContainerExporter
extends ControlExporter

# Exporter for Container nodes.

func export_node(info: NodeInfo, context: ExportContext) -> RenderGroup:
	if info.node_type == "PanelContainer":
		return _export_panel_container(info, context)
		
	info.is_layout_only = true
	return super.export_node(info, context)

func _export_panel_container(info: NodeInfo, context: ExportContext) -> RenderGroup:
	info.is_layout_only = false
	var group = super.export_node(info, context)
	
	var sb_id = info.resolved_theme.get("styleboxes", {}).get("panel", "")
	if sb_id != "" and sb_id != "null":
		var sb = context.resource_resolver.get_resource(sb_id)
		if sb is StyleBoxFlat:
			var visuals: Array[RenderObject] = []
			
			# 1. Draw Background
			var shape = RenderShape.new()
			shape.node_name = info.node_name + "_panel_bg"
			shape.shape_type = "rounded_rect" if sb.corner_radius_top_left > 0 else "rect"
			shape.rect = Rect2(Vector2.ZERO, info.size)
			shape.style.fill_color = sb.bg_color
			shape.corner_radius = sb.corner_radius_top_left
			shape.defines_clip_id = info.node_name + "_bg_clip"
			
			if sb.shadow_size > 0:
				shape.style.shadow_color = sb.shadow_color
				shape.style.shadow_size = sb.shadow_size
				shape.style.shadow_offset = sb.shadow_offset
				
			var bw_left = sb.border_width_left
			if bw_left > 0 and bw_left == sb.border_width_right and bw_left == sb.border_width_top and bw_left == sb.border_width_bottom:
				shape.style.stroke_color = sb.border_color
				shape.style.stroke_width = bw_left
			visuals.append(shape)
			
			# 2. Draw Non-Uniform Borders (Clipped)
			if not (bw_left == sb.border_width_right and bw_left == sb.border_width_top and bw_left == sb.border_width_bottom):
				if sb.border_width_left > 0:
					var b_shape = RenderShape.new()
					b_shape.shape_type = "rect"
					b_shape.rect = Rect2(0, 0, sb.border_width_left, info.size.y)
					b_shape.style.fill_color = sb.border_color
					b_shape.clip_id = shape.defines_clip_id
					visuals.append(b_shape)
				if sb.border_width_right > 0:
					var b_shape = RenderShape.new()
					b_shape.shape_type = "rect"
					b_shape.rect = Rect2(info.size.x - sb.border_width_right, 0, sb.border_width_right, info.size.y)
					b_shape.style.fill_color = sb.border_color
					b_shape.clip_id = shape.defines_clip_id
					visuals.append(b_shape)
				if sb.border_width_top > 0:
					var b_shape = RenderShape.new()
					b_shape.shape_type = "rect"
					b_shape.rect = Rect2(0, 0, info.size.x, sb.border_width_top)
					b_shape.style.fill_color = sb.border_color
					b_shape.clip_id = shape.defines_clip_id
					visuals.append(b_shape)
				if sb.border_width_bottom > 0:
					var b_shape = RenderShape.new()
					b_shape.shape_type = "rect"
					b_shape.rect = Rect2(0, info.size.y - sb.border_width_bottom, info.size.x, sb.border_width_bottom)
					b_shape.style.fill_color = sb.border_color
					b_shape.clip_id = shape.defines_clip_id
					visuals.append(b_shape)
					
			for i in range(visuals.size()):
				group.children.insert(i, visuals[i])
			
		elif sb is StyleBoxTexture:
			var img_obj = RenderImage.new()
			img_obj.node_name = info.node_name + "_panel_bg_img"
			img_obj.rect = Rect2(Vector2.ZERO, info.size)
			if sb.texture:
				img_obj.resource_id = context.resource_resolver.register_resource(sb.texture)
			group.children.insert(0, img_obj)
			
	return group
