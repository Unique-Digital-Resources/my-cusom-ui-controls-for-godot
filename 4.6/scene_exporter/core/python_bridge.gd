class_name PythonBridge
extends RefCounted

# Bridges Godot NodeInfo to the Python SVG generator

static func generate_svg(root_info: NodeInfo, resource_resolver: ResourceResolver, settings: ExportSettings) -> bool:
	var json_path = "user://scene_data_temp.json"
	var svg_path = settings.output_path
	
	var root_node = root_info.node
	var data = {
		"settings": {
			"width": root_node.size.x if root_node is Control else 1920,
			"height": root_node.size.y if root_node is Control else 1080,
			"embed_fonts": settings.embed_fonts
		},
		"resources": _serialize_resources(resource_resolver),
		"root_node": _serialize_node(root_info, resource_resolver)
	}
	
	var file = FileAccess.open(json_path, FileAccess.WRITE)
	if not file:
		ExportUtils.log_error("Failed to write JSON for Python bridge.")
		return false
		
	file.store_string(JSON.stringify(data))
	file.close()
	
	# Detect Python executable
	var python_exe = ""
	var args = []
	var test_output = []
	
	if OS.execute("python3", ["--version"], test_output, true) == 0:
		python_exe = "python3"
		args = [ProjectSettings.globalize_path("res://addons/scene_exporter/python/svg_generator.py")]
	elif OS.execute("python", ["--version"], test_output, true) == 0:
		python_exe = "python"
		args = [ProjectSettings.globalize_path("res://addons/scene_exporter/python/svg_generator.py")]
	elif OS.execute("py", ["-3", "--version"], test_output, true) == 0:
		python_exe = "py"
		args = ["-3", ProjectSettings.globalize_path("res://addons/scene_exporter/python/svg_generator.py")]
		
	if python_exe == "":
		ExportUtils.log_error("Python not found. Please ensure Python 3 is installed and in your system PATH.")
		return false
		
	ExportUtils.log_message("Using Python executable: " + python_exe)
	
	args.append(ProjectSettings.globalize_path(json_path))
	args.append(ProjectSettings.globalize_path(svg_path))
	
	var output = []
	var exit_code = OS.execute(python_exe, args, output, true)
	
	if exit_code != 0:
		ExportUtils.log_error("Python script failed with code %d" % exit_code)
		for line in output:
			ExportUtils.log_error(line)
		return false
		
	ExportUtils.log_message("Python SVG generation completed successfully.")
	DirAccess.remove_absolute(json_path)
	return true

static func _serialize_node(info: NodeInfo, res_resolver: ResourceResolver) -> Dictionary:
	var dict: Dictionary = {
		"name": info.node_name,
		"type": info.node_type,
		"rect": [info.absolute_position.x, info.absolute_position.y, info.size.x, info.size.y],
		"visible": info.visibility.get("is_visible_in_tree", true),
		"clip": info.properties.get("clip_contents", false),
		"transform": _transform_to_array(info.absolute_transform),
		"properties": _val_to_json(info.properties),
		"theme": _serialize_theme(info.resolved_theme, res_resolver),
		"animations": _val_to_json(info.animations),
		"children": []
	}
	
	for child in info.children_info:
		if child.node is CanvasItem:
			dict["children"].append(_serialize_node(child, res_resolver))
			
	return dict

static func _val_to_json(v):
	if v is Vector2:
		return [v.x, v.y]
	elif v is Color:
		return v.to_html()
	elif v is Rect2:
		return [v.position.x, v.position.y, v.size.x, v.size.y]
	elif v is Transform2D:
		return [v.x.x, v.x.y, v.y.x, v.y.y, v.origin.x, v.origin.y]
	elif v is Array:
		var arr = []
		for item in v: arr.append(_val_to_json(item))
		return arr
	elif v is Dictionary:
		var d = {}
		for k in v.keys(): d[k] = _val_to_json(v[k])
		return d
	return v

static func _serialize_theme(theme: Dictionary, res_resolver: ResourceResolver) -> Dictionary:
	var d = {}
	for key in theme.keys():
		if key == "styleboxes":
			d[key] = {}
			for sb_name in theme[key].keys():
				var sb_id = theme[key][sb_name]
				if sb_id is String and sb_id != "null":
					var sb = res_resolver.get_resource(sb_id)
					if sb: d[key][sb_name] = _serialize_stylebox(sb)
		elif key == "fonts":
			d[key] = {}
			for f_name in theme[key].keys():
				var f_id = theme[key][f_name]
				if f_id is String and f_id != "null":
					d[key][f_name] = f_id
		elif key == "icons":
			d[key] = {}
			for i_name in theme[key].keys():
				var i_id = theme[key][i_name]
				if i_id is String and i_id != "null":
					d[key][i_name] = i_id
		else:
			d[key] = _val_to_json(theme[key])
	return d

static func _serialize_stylebox(sb: StyleBox) -> Dictionary:
	if sb is StyleBoxFlat:
		return {
			"type": "flat",
			"bg_color": sb.bg_color.to_html(),
			"border_color": sb.border_color.to_html(),
			"border_width_left": sb.border_width_left,
			"border_width_right": sb.border_width_right,
			"border_width_top": sb.border_width_top,
			"border_width_bottom": sb.border_width_bottom,
			"corner_radius_top_left": sb.corner_radius_top_left,
			"corner_radius_top_right": sb.corner_radius_top_right,
			"corner_radius_bottom_right": sb.corner_radius_bottom_right,
			"corner_radius_bottom_left": sb.corner_radius_bottom_left,
			"shadow_color": sb.shadow_color.to_html(),
			"shadow_size": sb.shadow_size,
			"shadow_offset": [sb.shadow_offset.x, sb.shadow_offset.y]
		}
	elif sb is StyleBoxTexture:
		return {
			"type": "texture",
			"texture": sb.texture.resource_path if sb.texture else ""
		}
	return {"type": "empty"}

static func _serialize_resources(res_resolver: ResourceResolver) -> Dictionary:
	var dict: Dictionary = {}
	for key in res_resolver.get_all_resources().keys():
		var res = res_resolver.get_resource(key)
		if res is Font:
			var path = res.resource_path
			if path != "" and not path.begins_with("local://"):
				dict[key] = {"type": "font", "path": ProjectSettings.globalize_path(path)}
		elif res is Texture2D:
			dict[key] = {"type": "image", "data": res_resolver.get_image_base64(res)}
	return dict

static func _transform_to_array(t: Transform2D) -> Array:
	return [t.x.x, t.x.y, t.y.x, t.y.y, t.origin.x, t.origin.y]
