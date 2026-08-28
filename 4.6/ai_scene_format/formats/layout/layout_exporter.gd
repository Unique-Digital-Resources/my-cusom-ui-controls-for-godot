@tool
class_name AILayoutExporter
extends RefCounted

## V2 Tree Builder.
## Maps the AST root block directly to the selected Godot node.

static func apply_tree(root_godot_node: Node, tree_ast: AIParserBase.ASTNode) -> void:
	if not root_godot_node or not tree_ast: return
	
	# 1. Wipe existing children to mimic HTML innerHTML replacement
	for child in root_godot_node.get_children():
		if child is AnimationPlayer: continue # Keep AnimationPlayer
		root_godot_node.remove_child(child)
		child.queue_free()
		
	# 2. The tree_ast contains exactly one root block. Apply it to the selected node.
	if tree_ast.children.size() > 0 and tree_ast.children[0].type == "block":
		var root_ast = tree_ast.children[0]
		var root_name = root_ast.key.split(" ")[1] if root_ast.key.split(" ").size() > 1 else root_ast.key.split(" ")[0]
		
		# Rename the Godot node to match the AST if needed
		if root_godot_node.name != root_name:
			root_godot_node.name = root_name
			
		root_godot_node.set_meta("_ai_path", root_godot_node.name)
		
		# Apply root properties and build children
		for child_ast in root_ast.children:
			match child_ast.type:
				"prop":
					if child_ast.key == "script":
						var scr_path = child_ast.value
						if scr_path is String and scr_path.begins_with("res://"):
							var scr = load(scr_path)
							if scr: root_godot_node.set_script(scr)
					else:
						AIPropertyUtils.apply_property_to_target(root_godot_node, child_ast.key, child_ast.value)
				"block":
					var block_parts = child_ast.key.split(" ")
					var block_type = block_parts[0]
					if ClassDB.class_exists(block_type) and ClassDB.is_parent_class(block_type, "Node"):
						_build_node_recursive(root_godot_node, child_ast, root_godot_node.name)
					else:
						_apply_resource_block(root_godot_node, child_ast)
						
	EditorInterface.mark_scene_as_unsaved()

static func _build_node_recursive(parent_godot: Node, node_ast: AIParserBase.ASTNode, current_path: String) -> void:
	var parts = node_ast.key.split(" ")
	var node_type = parts[0]
	var node_name = parts[1] if parts.size() > 1 else node_type
	var logical_path = current_path + "/" + node_name
	
	if not ClassDB.class_exists(node_type):
		push_error("AI Scene Format V2: Unknown node type '" + node_type + "'")
		return
		
	var godot_node = ClassDB.instantiate(node_type)
	godot_node.name = node_name
	parent_godot.add_child(godot_node)
	godot_node.owner = parent_godot.owner if parent_godot.owner else parent_godot
	godot_node.set_meta("_ai_path", logical_path)
	
	for child_ast in node_ast.children:
		match child_ast.type:
			"prop":
				if child_ast.key == "script":
					var scr_path = child_ast.value
					if scr_path is String and scr_path.begins_with("res://"):
						var scr = load(scr_path)
						if scr: godot_node.set_script(scr)
				else:
					AIPropertyUtils.apply_property_to_target(godot_node, child_ast.key, child_ast.value)
			"block":
				var block_parts = child_ast.key.split(" ")
				var block_type = block_parts[0]
				if ClassDB.class_exists(block_type) and ClassDB.is_parent_class(block_type, "Node"):
					_build_node_recursive(godot_node, child_ast, logical_path)
				else:
					_apply_resource_block(godot_node, child_ast)

static func _apply_resource_block(target_godot: Node, res_ast: AIParserBase.ASTNode) -> void:
	var parts = res_ast.key.split(" ")
	var prop_name = parts[0]
	var res_type = parts[1] if parts.size() > 1 else "Resource"
	if not ClassDB.class_exists(res_type) or not ClassDB.is_parent_class(res_type, "Resource"): return
	var new_res = ClassDB.instantiate(res_type)
	for child in res_ast.children:
		if child.type == "prop": AIPropertyUtils.apply_property_to_target(new_res, child.key, child.value)
	if prop_name.begins_with("theme_override_styles/"):
		var override_name = prop_name.trim_prefix("theme_override_styles/").strip_edges()
		if target_godot is Control:
			target_godot.add_theme_stylebox_override(override_name, new_res)
			target_godot.queue_redraw()
	else:
		target_godot.set(prop_name, new_res)
