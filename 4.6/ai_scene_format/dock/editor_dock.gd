@tool
extends Control

## V2 Main Dock Controller.

@onready var inspector_bridge = $InspectorBridge
@onready var tabs = $VBoxContainer/VSplitContainer/HBoxContainer/Tabs
@onready var status_bar = $VBoxContainer/StatusBar
@onready var code_editor = $VBoxContainer/VSplitContainer/HBoxContainer/CodeEditor
@onready var toolbar = $VBoxContainer/Toolbar
@onready var output_console = $VBoxContainer/VSplitContainer/OutputConsole

var parser: AIParserBase = AIParserBase.new()
var validator: AIValidation = AIValidation.new()
var anim_parser: AIAnimationParser = AIAnimationParser.new()

var current_tab: String = "layout"

var validate_timer: Timer

# FIX: Removed "tweens" from block_buffers
var block_buffers: Dictionary = {
	"vars": "",
	"tree": "",
	"interactivity": "",
	"animations": ""
}
var combined_buffer: String = ""

func _ready() -> void:
	validate_timer = Timer.new()
	validate_timer.wait_time = 0.5
	validate_timer.one_shot = true
	validate_timer.timeout.connect(_on_validate_requested)
	add_child(validate_timer)
	
	if tabs: tabs.tab_changed.connect(_on_tab_changed)
	if inspector_bridge: inspector_bridge.selection_changed.connect(_on_selection_changed)
	if toolbar:
		toolbar.format_requested.connect(_on_format_requested)
		toolbar.validate_requested.connect(_on_validate_requested)
		toolbar.apply_requested.connect(_on_apply_requested)
		
	if code_editor:
		code_editor.text_changed.connect(_on_text_changed)

func _on_editor_ready() -> void:
	if inspector_bridge: inspector_bridge.setup()
	if status_bar: status_bar.set_status("Initializing AI Scene Format V2...")
	output_console.clear()
	output_console.add_text("AI Scene Format Ready.\n")

func _get_block_name_for_tab(tab_id: String) -> String:
	match tab_id:
		"layout": return "tree"
		"animation": return "animations"
		"interaction": return "interactivity"
		_: return tab_id

func _on_tab_changed(tab_id: String) -> void:
	_save_current_tab_to_buffer()
	current_tab = tab_id
	if status_bar: status_bar.set_status("Switched to " + tab_id + " tab.")
	
	if current_tab == "combined":
		code_editor.text = combined_buffer
	else:
		var block_name = _get_block_name_for_tab(current_tab)
		code_editor.text = block_buffers.get(block_name, "")

func _on_text_changed() -> void:
	validate_timer.stop()
	validate_timer.start()

func _save_current_tab_to_buffer() -> void:
	if current_tab == "combined":
		combined_buffer = code_editor.text
		_split_combined_to_blocks()
	else:
		var block_name = _get_block_name_for_tab(current_tab)
		block_buffers[block_name] = code_editor.text
		_merge_blocks_to_combined()

func _split_combined_to_blocks() -> void:
	var text = combined_buffer
	for block_name in block_buffers.keys():
		block_buffers[block_name] = _extract_block(text, block_name)

func _merge_blocks_to_combined() -> void:
	var parts = []
	# FIX: Removed "tweens" from merge list
	for block_name in ["vars", "tree", "interactivity", "animations"]:
		if not block_buffers[block_name].is_empty():
			parts.append(block_buffers[block_name])
	combined_buffer = "\n\n".join(parts)

func _extract_block(text: String, block_name: String) -> String:
	var start_idx = text.find(block_name + " {")
	if start_idx == -1: return ""
	var brace_depth = 0
	var end_idx = -1
	for i in range(start_idx + block_name.length(), text.length()):
		if text[i] == '{': brace_depth += 1
		elif text[i] == '}':
			brace_depth -= 1
			if brace_depth == 0:
				end_idx = i
				break
	if end_idx == -1: return ""
	return text.substr(start_idx, end_idx - start_idx + 1)

func _on_selection_changed(node: Node) -> void:
	if status_bar:
		status_bar.set_status("Selected: " + node.name if node else "No selection.")
	if node:
		block_buffers["tree"] = _generate_tree_from_node(node)
		block_buffers["animations"] = _generate_animations_from_node(node)
		block_buffers["interactivity"] = _generate_interactions_from_node(node)
		_merge_blocks_to_combined()
		
		if current_tab == "combined":
			code_editor.text = combined_buffer
		else:
			code_editor.text = block_buffers.get(_get_block_name_for_tab(current_tab), "")

# --- Deep Scene Serialization ---

func _generate_tree_from_node(node: Node) -> String:
	var lines = ["tree {"]
	_serialize_node(node, lines, 1)
	lines.append("}")
	return "\n".join(lines)

func _serialize_node(n: Node, lines: Array, indent: int) -> void:
	var spaces = " ".repeat(indent * 4)
	var type = n.get_class()
	var script = n.get_script()
	var global_name = ""
	if script is GDScript:
		global_name = script.get_global_name()
		if global_name != &"":
			type = global_name
			
	var name = n.name
	lines.append("%s%s %s {" % [spaces, type, name])
	
	if script is GDScript and global_name == &"":
		if script.resource_path != "" and not script.resource_path.begins_with("res://_generated_scripts/"):
			lines.append("%s    script = \"%s\"" % [spaces, script.resource_path])
	
	var props = n.get_property_list()
	for p in props:
		if p.usage & PROPERTY_USAGE_STORAGE == 0: continue
		if p.usage & PROPERTY_USAGE_INTERNAL != 0: continue
		if p.name in ["script", "owner", "name", "scene_file_path", "theme"]: continue
		if p.name.begins_with("metadata/"): continue
		
		var val = n.get(p.name)
		if val is Resource:
			if p.name.begins_with("theme_override_styles/"):
				var res_type = val.get_class()
				lines.append("%s    %s %s {" % [spaces, p.name, res_type])
				_serialize_resource(val, lines, indent + 2)
				lines.append("%s    }" % spaces)
			continue
			
		if typeof(val) == TYPE_OBJECT and val != null: continue
		
		if not AIDefaultsRegistry.is_default(n, p.name, val):
			lines.append("%s    %s = %s" % [spaces, p.name, _format_val(val)])
			
	for child in n.get_children():
		_serialize_node(child, lines, indent + 1)
		
	lines.append("%s}" % spaces)

func _serialize_resource(res: Resource, lines: Array, indent: int) -> void:
	var spaces = " ".repeat(indent * 4)
	var props = res.get_property_list()
	for p in props:
		if p.usage & PROPERTY_USAGE_STORAGE == 0: continue
		if p.name in ["resource_path", "resource_name", "script", "resource_local_to_scene"]: continue
		
		var val = res.get(p.name)
		if val is Resource:
			var res_type = val.get_class()
			lines.append("%s%s %s {" % [spaces, p.name, res_type])
			_serialize_resource(val, lines, indent + 1)
			lines.append("%s}" % spaces)
			continue
			
		if not AIDefaultsRegistry.is_default(res, p.name, val):
			lines.append("%s%s = %s" % [spaces, p.name, _format_val(val)])

func _generate_animations_from_node(node: Node) -> String:
	var players = _find_all_anim_players(node)
	if players.is_empty(): return ""
	
	var lines = ["animations {"]
	for player in players:
		var lib = player.get_animation_library("")
		if not lib: continue
		
		for anim_name in lib.get_animation_list():
			var anim = lib.get_animation(anim_name)
			lines.append("    animation \"%s\" {" % anim_name)
			lines.append("        length = %s" % _format_num(anim.length))
			lines.append("        loop = %s" % ("true" if anim.loop_mode == Animation.LOOP_LINEAR else "false"))
			
			for i in range(anim.get_track_count()):
				var path = anim.track_get_path(i)
				lines.append("        track \"%s\" {" % path)
				lines.append("            type = %s" % _get_track_type_string(anim.track_get_type(i)))
				lines.append("            interp = %s" % _get_interp_string(anim.track_get_interpolation_type(i)))
				
				for j in range(anim.track_get_key_count(i)):
					var time = anim.track_get_key_time(i, j)
					var val = anim.track_get_key_value(i, j)
					
					# FIX: Handle Audio Stream keyframes
					if anim.track_get_type(i) == Animation.TYPE_AUDIO:
						var stream = val.get("stream")
						if stream is AudioStream:
							lines.append("            keyframe %s = audio(\"%s\") ease(LINEAR, IN)" % [_format_num(time), stream.resource_path])
					else:
						lines.append("            keyframe %s = %s ease(LINEAR, IN)" % [_format_num(time), _format_val(val)])
					
				lines.append("        }")
			lines.append("    }")
			
	lines.append("}")
	return "\n".join(lines)

func _find_all_anim_players(node: Node) -> Array[AnimationPlayer]:
	var players: Array[AnimationPlayer] = []
	if node is AnimationPlayer: players.append(node)
	for child in node.get_children():
		players.append_array(_find_all_anim_players(child))
	return players

func _generate_interactions_from_node(node: Node) -> String:
	if not node.has_meta(AIInteractionImporter.META_KEY): return ""
	var interactions = node.get_meta(AIInteractionImporter.META_KEY)
	if not interactions is Array or interactions.is_empty(): return ""
	
	var lines = ["interactivity {"]
	for i in interactions:
		lines.append("    state(\"%s\", \"%s\") {" % [i.get("target_id", ""), i.get("name", "default")])
		if i.has("condition") and not i["condition"].is_empty():
			lines.append("        condition = \"%s\"" % i["condition"])
		lines.append("        action {")
		if i.has("property_overrides"):
			for prop in i["property_overrides"]:
				lines.append("            set(\"%s\", \"%s\", %s)" % [i.get("target_id", ""), prop, _format_val(i["property_overrides"][prop])])
		if i.has("animation_actions"):
			for action in i["animation_actions"]:
				lines.append("            play(\"%s\")" % i["animation_actions"][action])
		if i.has("tween_actions"):
			for action in i["tween_actions"]:
				lines.append("            play(\"%s\")" % i["tween_actions"][action])
		lines.append("        }")
		lines.append("    }")
	lines.append("}")
	return "\n".join(lines)

# --- Formatting Helpers ---

func _format_num(n: float) -> String:
	var s = "%.3f" % n
	while s.ends_with("0"): s = s.substr(0, s.length() - 1)
	if s.ends_with("."): s = s.substr(0, s.length() - 1)
	if s == "-0": s = "0"
	return s

func _format_val(val: Variant) -> String:
	if val is Color: return "Color(%s, %s, %s, %s)" % [_format_num(val.r), _format_num(val.g), _format_num(val.b), _format_num(val.a)]
	if val is Vector2: return "Vector2(%s, %s)" % [_format_num(val.x), _format_num(val.y)]
	if val is String: return "\"%s\"" % val
	if val is bool: return "true" if val else "false"
	if val is float: return _format_num(val)
	if val == null: return "null"
	return str(val)

func _get_track_type_string(type: int) -> String:
	match type:
		Animation.TYPE_VALUE: return "VALUE"
		Animation.TYPE_POSITION_3D: return "POSITION_3D"
		Animation.TYPE_ROTATION_3D: return "ROTATION_3D"
		Animation.TYPE_SCALE_3D: return "SCALE_3D"
		Animation.TYPE_METHOD: return "METHOD"
		Animation.TYPE_BEZIER: return "BEZIER"
		# FIX: Add Audio type
		Animation.TYPE_AUDIO: return "AUDIO"
	return "VALUE"

func _get_interp_string(interp: int) -> String:
	match interp:
		Animation.INTERPOLATION_NEAREST: return "NEAREST"
		Animation.INTERPOLATION_LINEAR: return "LINEAR"
		Animation.INTERPOLATION_CUBIC: return "CUBIC"
	return "LINEAR"

# --- Toolbar Actions ---

func _on_format_requested() -> void:
	status_bar.set_status("Document formatted.")

func _on_validate_requested() -> void:
	var text = code_editor.text
	var roots = parser.parse(text)
	validator.validate_ast(roots)
	output_console.clear()
	if not validator.issues.is_empty():
		output_console.add_text("--- Validation Issues ---\n")
		for issue in validator.issues:
			var color = "red" if issue.severity == 0 else "yellow"
			output_console.append_text("[color=%s]%s[/color]\n" % [color, issue._to_string()])
	status_bar.set_errors(validator.issues)
	status_bar.set_status("Validation passed." if validator.issues.is_empty() else "Validation found issues. See Output Console.")

func _on_apply_requested() -> void:
	_save_current_tab_to_buffer()
	var text_to_apply = combined_buffer if not combined_buffer.is_empty() else code_editor.text
	_on_validate_requested()
	if not validator.issues.is_empty():
		for issue in validator.issues:
			if issue.severity == 0: 
				status_bar.set_status("Apply aborted: Fix errors first.")
				return
				
	var selected_nodes = EditorInterface.get_selection().get_selected_nodes()
	if selected_nodes.is_empty():
		status_bar.set_status("Apply aborted: No node selected in Scene Tree.")
		return
		
	var target_node = selected_nodes[0]
	status_bar.set_status("Applying changes to scene...")
	output_console.add_text("Applying changes to " + target_node.name + "...\n")
	
	var roots = parser.parse(text_to_apply)
	var tree_ast: AIParserBase.ASTNode = null
	var anim_ast: AIParserBase.ASTNode = null
	var interact_ast: AIParserBase.ASTNode = null
	
	for r in roots:
		match r.type:
			"tree": tree_ast = r
			"animations": anim_ast = r
			"interactivity": interact_ast = r
			
	if tree_ast: AILayoutExporter.apply_tree(target_node, tree_ast)
	if anim_ast:
		var animations = anim_parser.parse_animations(anim_ast)
		var player = _find_or_create_anim_player(target_node)
		if player:
			# FIX: Pass target_node (the absolute root) to the exporter
			AIAnimationExporter.apply_animations(player, animations, target_node)
	# FIX: Removed tween_ast logic
	if interact_ast:
		var i_parser = AIInteractionParser.new()
		var interactions = i_parser.parse_interactions(interact_ast)
		AIInteractionExporter.apply_changes(target_node, interactions)
		
	AIRuntimeGenerator.generate_and_attach(target_node, text_to_apply)
	EditorInterface.mark_scene_as_unsaved()
	status_bar.set_status("V2 Layout & Logic applied to " + target_node.name)
	output_console.add_text("[color=green]Apply successful![/color]\n")

func _find_or_create_anim_player(root: Node) -> AnimationPlayer:
	var players = _find_all_anim_players(root)
	if not players.is_empty(): return players[0]
	var p = AnimationPlayer.new()
	p.name = "AnimPlayer"
	root.add_child(p)
	p.owner = root
	return p
