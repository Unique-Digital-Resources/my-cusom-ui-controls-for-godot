class_name SVGDefsWriter
extends RefCounted

# Generates the <defs> block for the SVG document.

var resource_resolver: ResourceResolver
var settings: ExportSettings

func _init(p_resolver: ResourceResolver, p_settings: ExportSettings):
	resource_resolver = p_resolver
	settings = p_settings

func write(document: RenderDocument) -> String:
	var defs: PackedStringArray = PackedStringArray()
	
	var resources = resource_resolver.get_all_resources()
	var res_idx = 0
	for key in resources:
		var res = resources[key]
		if res is Dictionary: res = res.res
		if res == null: continue
		
		if res is Font:
			var font_id = "font_" + str(res_idx)
			defs.append(_write_font(font_id, res))
			res_idx += 1
			
	var group_clips: Dictionary = {}
	var shape_clips: Dictionary = {}
	var shadows: Dictionary = {}
	var modulates: Dictionary = {}
	
	_collect_defs(document, group_clips, shape_clips, shadows, modulates)
	
	var clip_idx = 0
	for clip_key in group_clips:
		var clip: RenderClip = group_clips[clip_key]
		clip.id = "clip_" + str(clip_idx)
		defs.append(_write_group_clip(clip))
		clip_idx += 1
		
	for clip_key in shape_clips:
		var clip_data: Dictionary = shape_clips[clip_key]
		defs.append(_write_shape_clip(clip_data))
		
	for shadow_key in shadows:
		var shadow_data = shadows[shadow_key]
		defs.append(_write_shadow_filter(shadow_data.style, shadow_data.id))
		
	# Fix: Generate modulate filters
	for mod_key in modulates:
		var mod_data = modulates[mod_key]
		defs.append(_write_modulate_filter(mod_data.style, mod_data.id))
		
	if defs.is_empty():
		return ""
		
	return "<defs>\n" + "".join(defs) + "</defs>\n"

func _write_font(id: String, font: Font) -> String:
	if not settings.embed_fonts:
		return ""
	var base64 = resource_resolver.get_font_base64(font)
	if base64 == "":
		return ""
	return "  <font-face id=\"%s\" font-family=\"%s\" src=\"data:font/ttf;base64,%s\" />\n" % [id, id, base64]

func _write_group_clip(clip: RenderClip) -> String:
	var clip_str = "  <clipPath id=\"%s\">\n" % clip.id
	if clip.clip_type == "rect":
		var r = clip.rect
		clip_str += "    <rect x=\"%.2f\" y=\"%.2f\" width=\"%.2f\" height=\"%.2f\" />\n" % [r.position.x, r.position.y, r.size.x, r.size.y]
	clip_str += "  </clipPath>\n"
	return clip_str

func _write_shape_clip(clip_data: Dictionary) -> String:
	var clip_str = "  <clipPath id=\"%s\">\n" % clip_data.id
	var r = clip_data.rect
	var rx = clip_data.corner_radius
	if rx > 0:
		clip_str += "    <rect x=\"%.2f\" y=\"%.2f\" width=\"%.2f\" height=\"%.2f\" rx=\"%.2f\" ry=\"%.2f\" />\n" % [r.position.x, r.position.y, r.size.x, r.size.y, rx, rx]
	else:
		clip_str += "    <rect x=\"%.2f\" y=\"%.2f\" width=\"%.2f\" height=\"%.2f\" />\n" % [r.position.x, r.position.y, r.size.x, r.size.y]
	clip_str += "  </clipPath>\n"
	return clip_str

func _write_shadow_filter(shadow: RenderStyle, sid: String) -> String:
	var filter_str = "  <filter id=\"%s\" x=\"-50%%\" y=\"-50%%\" width=\"200%%\" height=\"200%%\">\n" % sid
	var dx = shadow.shadow_offset.x
	var dy = shadow.shadow_offset.y
	var std_dev = shadow.shadow_size
	filter_str += "    <feOffset dx=\"%.2f\" dy=\"%.2f\" in=\"SourceAlpha\" result=\"offsetblur\" />\n" % [dx, dy]
	filter_str += "    <feGaussianBlur in=\"offsetblur\" stdDeviation=\"%.2f\" result=\"blur\" />\n" % std_dev
	filter_str += "    <feFlood flood-color=\"#%s\" flood-opacity=\"%.3f\" result=\"color\" />\n" % [shadow.shadow_color.to_html(false), shadow.shadow_color.a]
	filter_str += "    <feComposite in=\"color\" in2=\"blur\" operator=\"in\" result=\"shadow\" />\n"
	filter_str += "    <feMerge>\n"
	filter_str += "      <feMergeNode in=\"shadow\" />\n"
	filter_str += "      <feMergeNode in=\"SourceGraphic\" />\n"
	filter_str += "    </feMerge>\n"
	filter_str += "  </filter>\n"
	return filter_str

# Fix: Create an SVG filter that multiplies the RGB channels to simulate Godot's modulate
func _write_modulate_filter(style: RenderStyle, mid: String) -> String:
	var c = style.modulate_color
	var filter_str = "  <filter id=\"%s\">\n" % mid
	filter_str += "    <feColorMatrix type=\"matrix\" values=\"%.3f 0 0 0 0  0 %.3f 0 0 0  0 0 %.3f 0 0  0 0 0 1 0\" />\n" % [c.r, c.g, c.b]
	filter_str += "  </filter>\n"
	return filter_str

func _collect_defs(obj: RenderObject, group_clips: Dictionary, shape_clips: Dictionary, shadows: Dictionary, modulates: Dictionary) -> void:
	if obj == null: return
	
	if obj.clip != null:
		var key = str(obj.clip.rect)
		if not group_clips.has(key):
			group_clips[key] = obj.clip
			
	if obj is RenderShape:
		var shape = obj as RenderShape
		if shape.defines_clip_id != "":
			if not shape_clips.has(shape.defines_clip_id):
				shape_clips[shape.defines_clip_id] = {"id": shape.defines_clip_id, "rect": shape.rect, "corner_radius": shape.corner_radius}
				
		if shape.style.shadow_size > 0:
			var key = str(shape.style.shadow_size) + str(shape.style.shadow_color.to_html(false)) + str(shape.style.shadow_offset)
			if not shadows.has(key):
				var sid = "shadow_" + str(shadows.size())
				shadows[key] = {"id": sid, "style": shape.style}
				shape.style.shadow_id = sid
			else:
				shape.style.shadow_id = shadows[key].id

	# Fix: Collect modulate styles
	if obj.style.modulate_color != Color.WHITE:
		var key = str(obj.style.modulate_color)
		if not modulates.has(key):
			var mid = "modulate_" + str(modulates.size())
			modulates[key] = {"id": mid, "style": obj.style}
			obj.style.modulate_id = mid
		else:
			obj.style.modulate_id = modulates[key].id
			
	if obj is RenderGroup:
		for child in (obj as RenderGroup).children:
			_collect_defs(child, group_clips, shape_clips, shadows, modulates)
