class_name SVGStyleWriter
extends RefCounted

# Converts RenderStyle and RenderTransform objects into SVG attribute strings

func get_style_string(style: RenderStyle) -> String:
	var attrs: PackedStringArray = PackedStringArray()
	
	if style.fill_color.a > 0:
		attrs.append("fill=\"#%s\"" % style.fill_color.to_html(false))
		if style.fill_color.a < 1.0:
			attrs.append("fill-opacity=\"%.3f\"" % style.fill_color.a)
	else:
		attrs.append("fill=\"none\"")
		
	if style.stroke_color.a > 0 and style.stroke_width > 0:
		attrs.append("stroke=\"#%s\"" % style.stroke_color.to_html(false))
		attrs.append("stroke-width=\"%.2f\"" % style.stroke_width)
		if style.stroke_color.a < 1.0:
			attrs.append("stroke-opacity=\"%.3f\"" % style.stroke_color.a)
	else:
		attrs.append("stroke=\"none\"")
		
	if style.opacity < 1.0:
		attrs.append("opacity=\"%.3f\"" % style.opacity)
		
	if style.shadow_id != "":
		attrs.append("filter=\"url(#%s)\"" % style.shadow_id)
		
	if style.modulate_id != "":
		if attrs.has("filter=\"url(#%s)\"" % style.shadow_id):
			attrs.remove_at(attrs.size() - 1) # Remove shadow filter to combine
			attrs.append("filter=\"url(#%s) url(#%s)\"" % [style.shadow_id, style.modulate_id])
		else:
			attrs.append("filter=\"url(#%s)\"" % style.modulate_id)
		
	return " ".join(attrs)

func get_group_style_string(style: RenderStyle) -> String:
	var attrs: PackedStringArray = PackedStringArray()
	
	if style.opacity < 1.0:
		attrs.append("opacity=\"%.3f\"" % style.opacity)
		
	if style.shadow_id != "":
		attrs.append("filter=\"url(#%s)\"" % style.shadow_id)
		
	if style.modulate_id != "":
		if attrs.has("filter=\"url(#%s)\"" % style.shadow_id):
			attrs.remove_at(attrs.size() - 1)
			attrs.append("filter=\"url(#%s) url(#%s)\"" % [style.shadow_id, style.modulate_id])
		else:
			attrs.append("filter=\"url(#%s)\"" % style.modulate_id)
		
	return " ".join(attrs)

func get_transform_string(transform: RenderTransform) -> String:
	if transform.origin == Vector2.ZERO and transform.rotation == 0.0 and transform.scale == Vector2.ONE:
		return ""
		
	var parts: PackedStringArray = PackedStringArray()
	
	if transform.origin != Vector2.ZERO:
		parts.append("translate(%.2f, %.2f)" % [transform.origin.x, transform.origin.y])
		
	if transform.rotation != 0.0:
		parts.append("rotate(%.2f)" % rad_to_deg(transform.rotation))
		
	if transform.scale != Vector2.ONE:
		parts.append("scale(%.2f, %.2f)" % [transform.scale.x, transform.scale.y])
		
	if parts.is_empty():
		return ""
		
	return "transform=\"%s\"" % " ".join(parts)

func get_group_clip_string(clip: RenderClip) -> String:
	if clip == null or clip.id == "":
		return ""
	return "clip-path=\"url(#%s)\"" % clip.id

func get_shape_clip_string(shape: RenderShape) -> String:
	if shape.defines_clip_id == "":
		return ""
	return "clip-path=\"url(#%s)\"" % shape.defines_clip_id
