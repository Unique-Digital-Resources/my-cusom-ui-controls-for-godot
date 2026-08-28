@tool
class_name AISceneSync
extends RefCounted

## Orchestrates the reading and writing of the Layout format between the editor and documents.

var importer: AILayoutImporter = AILayoutImporter.new()
var serializer: AILayoutSerializer = AILayoutSerializer.new()
var parser: AILayoutParser = AILayoutParser.new()
var exporter: AILayoutExporter = AILayoutExporter.new()

var current_model: AISceneModel = null
var current_root_node: Node = null

# Reads from Godot Scene -> Internal Model -> Text Document
func read_scene_to_text(selected_node: Node) -> String:
    if not selected_node:
        return ""
        
    current_root_node = selected_node
    current_model = importer.import_subtree(selected_node)
    return serializer.serialize_subtree(current_model, current_model.root_id)

# Writes from Text Document -> Internal Model -> Godot Scene
func apply_text_to_scene(text: String) -> void:
    if not current_root_node:
        return
        
    # Parse the edited text into a new model
    current_model = parser.parse_to_model(text)
    
    # Apply the changes to the Godot scene
    exporter.apply_changes(current_root_node, current_model)
    
    # Force editor to refresh the scene tree and inspector
    EditorInterface.edit_node(current_root_node)