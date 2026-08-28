class_name AISceneModel
extends RefCounted

## The internal editable scene representation (Legacy V1, kept for compatibility).

var root_id: String = ""
var nodes: Dictionary = {}               
var resources: Dictionary = {}           

# FIX: AIIds was removed in V2, use AIPathResolver or just a plain dictionary
var id_manager: Dictionary = {} 

func create_node(node_type: String, node_name: String, parent_id: String = "", p_id: String = "") -> AINodeModel:
	var node = AINodeModel.new()
	node.id = p_id if p_id != "" else str(id_manager.size() + 1)
	node.type = node_type
	node.name = node_name
	node.parent_id = parent_id
	
	nodes[node.id] = node
	
	if parent_id != "" and nodes.has(parent_id):
		(nodes[parent_id] as AINodeModel).add_child(node.id)
	elif root_id == "":
		root_id = node.id
		
	return node

func delete_node(node_id: String) -> void:
	if not nodes.has(node_id): return
	var node = nodes[node_id] as AINodeModel
	for child_id in node.child_ids.duplicate():
		delete_node(child_id)
	if node.parent_id != "" and nodes.has(node.parent_id):
		(nodes[node.parent_id] as AINodeModel).remove_child(node_id)
	nodes.erase(node_id)

func get_node(node_id: String) -> AINodeModel:
	return nodes.get(node_id)

func register_resource(res: AIResourceModel) -> void:
	if res.id == "":
		res.id = str(id_manager.size() + 1)
	resources[res.id] = res

func clear() -> void:
	root_id = ""
	nodes.clear()
	resources.clear()
	id_manager.clear()
