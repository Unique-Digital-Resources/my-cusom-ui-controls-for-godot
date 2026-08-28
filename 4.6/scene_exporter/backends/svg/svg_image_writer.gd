class_name SVGImageWriter
extends RefCounted

# Serializes RenderImage objects into SVG <image> tags
# Fix: Directly embeds base64 data instead of referencing an ID

var resource_resolver: ResourceResolver

func _init(p_resolver: ResourceResolver = null):
	resource_resolver = p_resolver

func write(image_obj: RenderImage, transform_attrs: String) -> String:
	var attrs: PackedStringArray = PackedStringArray()
	
	if transform_attrs != "":
		attrs.append(transform_attrs)
		
	attrs.append("x=\"%.2f\"" % image_obj.rect.position.x)
	attrs.append("y=\"%.2f\"" % image_obj.rect.position.y)
	attrs.append("width=\"%.2f\"" % image_obj.rect.size.x)
	attrs.append("height=\"%.2f\"" % image_obj.rect.size.y)
	
	var href = image_obj.resource_id
	if href == "" or href == "null":
		href = "unknown_resource"
		
	# Fix: Resolve the resource ID to an actual data URL or file path
	if resource_resolver != null:
		var res = resource_resolver.get_resource(href)
		if res is Texture2D:
			var base64 = resource_resolver.get_image_base64(res)
			if base64 != "":
				href = "data:image/png;base64," + base64
			elif res.resource_path != "":
				href = res.resource_path.replace("res://", "")
				
	attrs.append("href=\"%s\"" % href)
	attrs.append("preserveAspectRatio=\"none\"")
	
	return "<image %s />" % " ".join(attrs)
