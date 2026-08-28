class_name TextureExporter
extends ControlExporter

# Exporter for TextureRect, TextureButton, and subclasses (like Lucide and SvgVectorControl).

func export_node(info: NodeInfo, context: ExportContext) -> RenderGroup:
	var group = super.export_node(info, context)
	
	var img_obj = RenderImage.new()
	img_obj.node_name = info.node_name + "_img"
	
	var tex = null
	if info.node is TextureRect:
		tex = info.properties.get("texture", null)
	elif info.node is TextureButton:
		tex = info.properties.get("texture_normal", null)
		
	if tex != null:
		img_obj.resource_id = context.resource_resolver.register_resource(tex)
		
		var stretch_mode = info.properties.get("stretch_mode", 0)
		var tex_size = tex.get_size() if tex is Texture2D else Vector2.ZERO
		
		# Fix: Extreme safeguards against zero sizes to prevent NaN in SVG
		if tex_size.x <= 0 or tex_size.y <= 0:
			tex_size = info.size
		if tex_size.x <= 0 or tex_size.y <= 0:
			tex_size = info.properties.get("custom_minimum_size", Vector2(24, 24))
		if tex_size.x <= 0 or tex_size.y <= 0:
			tex_size = Vector2(24, 24)
			
		var dest_size = info.size
		if dest_size.x <= 0 or dest_size.y <= 0:
			dest_size = tex_size
		if dest_size.x <= 0 or dest_size.y <= 0:
			dest_size = Vector2(24, 24)
			
		var dest_rect = Rect2(Vector2.ZERO, dest_size)
		
		match stretch_mode:
			0: # STRETCH_SCALE
				dest_rect = Rect2(Vector2.ZERO, dest_size)
			1: # STRETCH_TILE
				dest_rect = Rect2(Vector2.ZERO, dest_size)
			2: # STRETCH_KEEP
				dest_rect = Rect2(Vector2.ZERO, tex_size)
			3: # STRETCH_KEEP_CENTERED
				var offset = (dest_size - tex_size) / 2.0
				dest_rect = Rect2(offset, tex_size)
			4: # STRETCH_KEEP_ASPECT
				var scale_factor = min(dest_size.x / tex_size.x, dest_size.y / tex_size.y)
				var scaled_size = tex_size * scale_factor
				var pos = (dest_size - scaled_size) / 2.0
				dest_rect = Rect2(pos, scaled_size)
			5: # STRETCH_KEEP_ASPECT_CENTERED
				var scale_factor = min(dest_size.x / tex_size.x, dest_size.y / tex_size.y)
				var scaled_size = tex_size * scale_factor
				var pos = (dest_size - scaled_size) / 2.0
				dest_rect = Rect2(pos, scaled_size)
			6: # STRETCH_KEEP_ASPECT_COVERED
				var scale_factor = max(dest_size.x / tex_size.x, dest_size.y / tex_size.y)
				var scaled_size = tex_size * scale_factor
				var pos = (dest_size - scaled_size) / 2.0
				dest_rect = Rect2(pos, scaled_size)
				
		img_obj.rect = dest_rect
	else:
		img_obj.rect = Rect2(Vector2.ZERO, info.size)
		
	var modulate = info.properties.get("modulate", Color.WHITE)
	if modulate != Color.WHITE:
		img_obj.style.opacity = modulate.a
		
	group.add_child(img_obj)
	return group
