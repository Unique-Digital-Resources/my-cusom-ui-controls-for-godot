@tool
class_name AIApplyChanges
extends RefCounted

## Executes parsed document changes by utilizing the DiffEngine and UndoRedo systems.

static func apply_document_to_scene(root_node: Node, old_model: AISceneModel, new_model: AISceneModel) -> void:
    if not root_node or not old_model or not new_model:
        return
        
    # 1. Compute the minimal diff between the old state and the new text state
    var diff_commands = AIDiffEngine.compute_diff(old_model, new_model)
    
    if diff_commands.is_empty():
        return
        
    # 2. Apply the diff via Godot's UndoRedo system
    AIUndoRedo.apply_diff(root_node, old_model, new_model, diff_commands)
    
    # 3. Force editor refresh
    EditorInterface.edit_node(root_node)