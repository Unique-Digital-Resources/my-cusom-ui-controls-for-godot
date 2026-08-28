@tool
class_name AILiveSync
extends Node

## V2 Synchronization Bridge.
## Coordinates between the parsed AST, the BindingManager, and the Godot SceneTree.

var binding_manager: AIBindingManager = AIBindingManager.new()
var tree_root: Node = null

# Static cache so the runtime script can access the parsed logic without re-parsing
var vars_ast: AIParserBase.ASTNode = null
var tree_ast: AIParserBase.ASTNode = null
var interact_ast: AIParserBase.ASTNode = null
var anim_ast: AIParserBase.ASTNode = null

func setup(root: Node, roots: Array[AIParserBase.ASTNode]) -> void:
	tree_root = root
	vars_ast = null
	tree_ast = null
	interact_ast = null
	anim_ast = null
	
	for r in roots:
		match r.type:
			"vars": vars_ast = r
			"tree": tree_ast = r
			"interactivity": interact_ast = r
			"animations": anim_ast = r
			
	ASTCache.vars_ast = vars_ast
	ASTCache.tree_ast = tree_ast
	ASTCache.interact_ast = interact_ast
	ASTCache.anim_ast = anim_ast
	
	if vars_ast:
		binding_manager.vars_changed.connect(_apply_vars_to_tree)
		binding_manager.setup(vars_ast)
		
	# Initial tree build
	if tree_ast:
		AILayoutExporter.apply_tree(tree_root, tree_ast)
		_apply_vars_to_tree()

func _apply_vars_to_tree() -> void:
	if not tree_root or not tree_ast: return
	
	# Walk the tree and apply any property that references a variable
	_apply_vars_recursive(tree_root, tree_ast)

func _apply_vars_recursive(godot_node: Node, node_ast: AIParserBase.ASTNode) -> void:
	for child_ast in node_ast.children:
		if child_ast.type == "prop":
			var val = child_ast.value
			var resolved_val = _resolve_var(val)
			if resolved_val != null:
				AIPropertyUtils.apply_property_to_target(godot_node, child_ast.key, resolved_val)
		elif child_ast.type == "block":
			var parts = child_ast.key.split(" ")
			var node_name = parts[1] if parts.size() > 1 else parts[0]
			var child_godot = godot_node.get_node_or_null(node_name)
			if child_godot:
				_apply_vars_recursive(child_godot, child_ast)

func _resolve_var(val: Variant) -> Variant:
	# If the property value is a string that matches a var name, return the var value
	if val is String and binding_manager.evaluated_vars.has(val):
		return binding_manager.evaluated_vars[val]
		
	# If it's an expression, evaluate it
	if val is Dictionary and val.get("__type__") == "expr":
		return binding_manager._evaluate_expression(val.get("code", ""))
		
	# If it's an animation reference, ignore it here (handled by runtime)
	if val is Dictionary and val.get("__type__") == "anim_ref":
		return null
		
	return val

# Static class to allow the generated runtime script to access the AST
class ASTCache:
	static var vars_ast: AIParserBase.ASTNode = null
	static var tree_ast: AIParserBase.ASTNode = null
	static var interact_ast: AIParserBase.ASTNode = null
	static var anim_ast: AIParserBase.ASTNode = null
