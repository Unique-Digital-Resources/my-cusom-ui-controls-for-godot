@tool
class_name AIUndoRedo
extends RefCounted

## Integrates AI Scene Format commands with Godot's EditorUndoRedoManager.

static func apply_diff(root_node: Node, old_model: AISceneModel, new_model: AISceneModel, diff_commands: Array) -> void:
	var undo_redo = EditorInterface.get_editor_undo_redo()
	undo_redo.create_action("Apply AI Scene Format Changes")
	
	for cmd in diff_commands:
		match cmd.type:
			"create":
				_new_node_cmd(undo_redo, root_node, new_model, cmd.node_id)
			"delete":
				_delete_node_cmd(undo_redo, root_node, old_model, cmd.node_id)
			"rename":
				_rename_node_cmd(undo_redo, root_node, cmd.node_id, cmd.data.new_name)
			"move":
				_move_node_cmd(undo_redo, root_node, new_model, cmd.node_id, cmd.data.new_parent_id)
			"property":
				_property_cmd(undo_redo, root_node, old_model, new_model, cmd.node_id, cmd.data.prop)

	undo_redo.commit_action()

# --- Command Implementations ---

static func _new_node_cmd(undo_redo, root_node: Node, new_model: AISceneModel, node_id: String):
	var node_model = new_model.get_node(node_id)
	if not node_model: return
	
	var parent_node = _resolve_godot_node(root_node, new_model, node_model.parent_id)
	if not parent_node: return
	
	if not ClassDB.class_exists(node_model.type): return
	var new_node = ClassDB.instantiate(node_model.type)
	new_node.name = node_model.name
	new_node.set_meta("_ai_id_", node_id)
	
	# Use standard Godot 4 add_do_method(Object, method, args)
	undo_redo.add_do_method(parent_node, "add_child", new_node)
	undo_redo.add_do_method(new_node, "set_owner", parent_node.owner if parent_node.owner else parent_node)
	
	undo_redo.add_undo_method(parent_node, "remove_child", new_node)

static func _delete_node_cmd(undo_redo, root_node: Node, old_model: AISceneModel, node_id: String):
	var node_model = old_model.get_node(node_id)
	if not node_model: return
	var target_node = _find_node_by_ai_id(root_node, node_id)
	if not target_node: return
	
	var parent_node = target_node.get_parent()
	
	undo_redo.add_do_method(parent_node, "remove_child", target_node)
	undo_redo.add_undo_method(parent_node, "add_child", target_node)
	undo_redo.add_undo_method(target_node, "set_owner", parent_node.owner if parent_node.owner else parent_node)

static func _rename_node_cmd(undo_redo, root_node: Node, node_id: String, new_name: String):
	var target_node = _find_node_by_ai_id(root_node, node_id)
	if not target_node: return
	var old_name = target_node.name
	
	undo_redo.add_do_method(target_node, "set_name", new_name)
	undo_redo.add_undo_method(target_node, "set_name", old_name)

static func _move_node_cmd(undo_redo, root_node: Node, new_model: AISceneModel, node_id: String, new_parent_id: String):
	var target_node = _find_node_by_ai_id(root_node, node_id)
	if not target_node: return
	
	var old_parent = target_node.get_parent()
	var old_idx = target_node.get_index()
	var new_parent = _resolve_godot_node(root_node, new_model, new_parent_id)
	if not new_parent: return
	
	undo_redo.add_do_method(old_parent, "remove_child", target_node)
	undo_redo.add_do_method(new_parent, "add_child", target_node)
	undo_redo.add_do_method(target_node, "set_owner", new_parent.owner if new_parent.owner else new_parent)
	
	undo_redo.add_undo_method(new_parent, "remove_child", target_node)
	undo_redo.add_undo_method(old_parent, "add_child", target_node)
	undo_redo.add_undo_method(old_parent, "move_child", target_node, old_idx)
	undo_redo.add_undo_method(target_node, "set_owner", old_parent.owner if old_parent.owner else old_parent)

static func _property_cmd(undo_redo, root_node: Node, old_model: AISceneModel, new_model: AISceneModel, node_id: String, new_prop: AIPropertyModel):
	var target_node = _find_node_by_ai_id(root_node, node_id)
	if not target_node: return
	
	var old_val = target_node.get(new_prop.name) if target_node.get(new_prop.name) != null else null
	var revert_prop = AIPropertyModel.new(new_prop.name, old_val)
	
	# Use our command class to handle deep resource setting
	undo_redo.add_do_method(AICommandPropertyChange, "execute", target_node, new_prop)
	undo_redo.add_undo_method(AICommandPropertyChange, "execute", target_node, revert_prop)

# --- Helpers ---

static func _resolve_godot_node(root: Node, model: AISceneModel, id: String) -> Node:
	if id == model.root_id: return root
	return _find_node_by_ai_id(root, id)

static func _find_node_by_ai_id(current: Node, id: String) -> Node:
	if current.get_meta("_ai_id_", "") == id:
		return current
	for child in current.get_children():
		var found = _find_node_by_ai_id(child, id)
		if found: return found
	return null
