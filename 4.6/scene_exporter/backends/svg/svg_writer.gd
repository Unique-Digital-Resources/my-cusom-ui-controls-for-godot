class_name SVGWriter
extends RefCounted

# Converts the backend-independent RenderDocument into a valid SVG string

var style_writer: SVGStyleWriter
var shape_writer: SVGShapeWriter
var text_writer: SVGTextWriter
var image_writer: SVGImageWriter
var anim_writer: SVGAnimationWriter

func _init():
	style_writer = SVGStyleWriter.new()
	shape_writer = SVGShapeWriter.new()
	text_writer = SVGTextWriter.new()
	image_writer = SVGImageWriter.new()
	anim_writer = SVGAnimationWriter.new()

func write(document: RenderDocument, context: ExportContext, camera_transform_str: String = "") -> String:
	var svg_doc = SVGDocument.new()
	
	# Initialize image writer with the context's resource resolver
	image_writer.resource_resolver = context.resource_resolver
	
	svg_doc.add_declaration()
	svg_doc.add_root(document.width, document.height)
	
	var defs_writer = SVGDefsWriter.new(context.resource_resolver, context.settings)
	var defs_str = defs_writer.write(document)
	if defs_str != "":
		svg_doc.add_raw(defs_str)
	
	if document.background_color.a > 0:
		var bg_attrs = "x=\"0\" y=\"0\" width=\"%d\" height=\"%d\" fill=\"#%s\"" % [document.width, document.height, document.background_color.to_html(false)]
		if document.background_color.a < 1.0:
			bg_attrs += " fill-opacity=\"%.3f\"" % document.background_color.a
		svg_doc.add_self_closing_tag("rect", bg_attrs)
	
	var has_camera = camera_transform_str != ""
	
	if has_camera:
		var group_attrs = "id=\"CameraTransform\" transform=\"%s\"" % camera_transform_str
		
		var clip_id = "camera_viewport_clip"
		svg_doc.add_raw("  <clipPath id=\"%s\">\n" % clip_id)
		svg_doc.add_raw("    <rect x=\"0\" y=\"0\" width=\"%d\" height=\"%d\" />\n" % [int(document.width), int(document.height)])
		svg_doc.add_raw("  </clipPath>\n")
		
		group_attrs += " clip-path=\"url(#%s)\"" % clip_id
		
		svg_doc.open_tag("g", group_attrs)
	
	for child in document.children:
		_write_object(child, svg_doc, context)
		
	if has_camera:
		svg_doc.close_tag("g")
		
	svg_doc.close_root()
	return svg_doc.to_string()

func _write_object(obj: RenderObject, svg_doc: SVGDocument, context: ExportContext) -> void:
	if obj == null: return
	if not obj.visible:
		return
		
	var transform_attrs = style_writer.get_transform_string(obj.transform)
	var group_clip_attrs = style_writer.get_group_clip_string(obj.clip)
	if group_clip_attrs != "":
		transform_attrs += " " + group_clip_attrs if transform_attrs != "" else group_clip_attrs
		
	var anim_tags = []
	if context != null and context.settings.export_animations:
		anim_tags = anim_writer.write_animations(obj.animations)
	
	if obj is RenderGroup:
		var group_attrs = "id=\"%s\"" % obj.node_name
		if transform_attrs != "": group_attrs += " " + transform_attrs
		
		var group_style_attrs = style_writer.get_group_style_string(obj.style)
		if group_style_attrs != "": group_attrs += " " + group_style_attrs
		
		svg_doc.open_tag("g", group_attrs)
		
		for tag in anim_tags:
			svg_doc.add_raw(tag)
			
		for child in (obj as RenderGroup).children:
			_write_object(child, svg_doc, context)
			
		svg_doc.close_tag("g")
		
	elif obj is RenderShape:
		var shape = obj as RenderShape
		var style_attrs = style_writer.get_style_string(obj.style)
		var shape_clip_attrs = style_writer.get_shape_clip_string(shape)
		var tag_str = shape_writer.write(shape, style_attrs, transform_attrs, shape_clip_attrs)
		svg_doc.add_raw(tag_str)
		
	elif obj is RenderText:
		var text_obj = obj as RenderText
		var tag_str = text_writer.write(text_obj, obj.style, transform_attrs)
		svg_doc.add_raw(tag_str)
		
	elif obj is RenderImage:
		var img_obj = obj as RenderImage
		var tag_str = image_writer.write(img_obj, transform_attrs)
		svg_doc.add_raw(tag_str)
		
	elif obj is RenderSVG:
		# Fix: Inject raw SVG string directly, wrapped in a group for transforms
		var svg_obj = obj as RenderSVG
		var group_attrs = "id=\"%s\"" % svg_obj.node_name
		if transform_attrs != "": group_attrs += " " + transform_attrs
		svg_doc.open_tag("g", group_attrs)
		svg_doc.add_raw(svg_obj.svg_data)
		svg_doc.close_tag("g")
