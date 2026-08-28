class_name ResourceResolver
extends RefCounted

# Caches and tracks unique resources (Fonts, Textures, StyleBoxes) for later serialization.

var _resources: Dictionary = {}
var _next_id: int = 0

func register_resource(res: Resource) -> String:
	if res == null:
		return "null"
		
	var path = res.resource_path
	if path != "" and not path.begins_with("local://"):
		if not _resources.has(path):
			_resources[path] = res
		return path
		
	# Use get_instance_id() to deduplicate identical in-memory resources
	var inst_id = str(res.get_instance_id())
	if not _resources.has(inst_id):
		var local_id = "local://res_" + str(_next_id)
		_next_id += 1
		_resources[inst_id] = {"id": local_id, "res": res}
		return local_id
		
	return _resources[inst_id].id

func get_resource(id: String) -> Resource:
	if _resources.has(id):
		var entry = _resources[id]
		if entry is Dictionary:
			return entry.res
		return entry
	return null

func get_all_resources() -> Dictionary:
	return _resources

func get_image_base64(texture: Texture2D) -> String:
	if texture == null:
		return ""
		
	var img = null
	
	# 1. Try native get_image() for standard textures
	if texture is ImageTexture or texture is CompressedTexture2D:
		img = texture.get_image()
	elif texture is AtlasTexture:
		if texture.atlas:
			img = texture.atlas.get_image()
			if img and texture.region.has_area():
				img = img.get_region(texture.region)
				
	# 2. If native failed, try the generic method (some custom textures support it)
	if img == null and texture.has_method("get_image"):
		img = texture.get_image()
			
	# 3. If still null, force rasterize via SubViewport (handles LucideTexture and other dynamic textures)
	if img == null:
		ExportUtils.log_warning("Rasterizing dynamic texture via SubViewport: " + texture.get_class())
		img = _rasterize_texture(texture)
		
	if img == null or img.is_empty():
		ExportUtils.log_warning("Failed to extract or rasterize image data for: " + texture.get_class())
		return ""
		
	var data = img.save_png_to_buffer()
	return Marshalls.raw_to_base64(data)

# Draws the texture to an off-screen viewport to force rasterization
func _rasterize_texture(texture: Texture2D) -> Image:
	if texture == null:
		return null
		
	var size = texture.get_size()
	if size.x <= 0 or size.y <= 0:
		size = Vector2(24, 24) # Fallback size
		
	var vp = SubViewport.new()
	vp.size = Vector2i(int(size.x), int(size.y))
	vp.transparent_bg = true
	vp.render_target_clear_mode = SubViewport.CLEAR_MODE_ONCE
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	
	var rect = TextureRect.new()
	rect.texture = texture
	rect.size = size
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	vp.add_child(rect)
	
	# Add to tree temporarily to force render
	Engine.get_main_loop().root.add_child(vp)
	
	# Force the rendering server to draw the frame
	RenderingServer.force_draw()
	
	var img = vp.get_texture().get_image()
	
	vp.queue_free()
	return img

func get_font_base64(font: Font) -> String:
	if font is FontFile:
		var data = (font as FontFile).get_data()
		return Marshalls.raw_to_base64(data)
	return ""
