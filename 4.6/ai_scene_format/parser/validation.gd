@tool
class_name AIValidation
extends RefCounted

## Syntax and semantic validation engine for V2 AST.

class Issue:
	var severity: int # 0 = Error, 1 = Warning
	var message: String
	var context: String
	
	func _to_string() -> String:
		var s = "WARNING" if severity == 1 else "ERROR"
		return "[%s] %s: %s" % [s, context, message]

var issues: Array[Issue] = []

func validate_ast(roots: Array[AIParserBase.ASTNode]) -> bool:
	issues.clear()
	
	var valid_roots = ["vars", "tree", "interactivity", "animations", "tweens"]
	
	for root in roots:
		if root.type not in valid_roots:
			_add_issue(0, "Unknown root block type: '%s'. Expected vars, tree, interactivity, animations, or tweens." % root.type, root.key)
		else:
			_validate_recursive(root, root.type)
			
	return issues.size() == 0

func _validate_recursive(node: AIParserBase.ASTNode, context: String) -> void:
	for child in node.children:
		# 1. Validate based on current context
		match context:
			"tree":
				if child.type == "block":
					var parts = child.key.split(" ")
					var type_str = parts[0]
					
					# FIX: If it's a resource block (e.g., "theme_override_styles/panel StyleBoxFlat"), skip node check
					var is_resource = false
					if parts.size() >= 2:
						var res_type = parts[1]
						if ClassDB.class_exists(res_type) and ClassDB.is_parent_class(res_type, "Resource"):
							is_resource = true
							
					if not is_resource and not ClassDB.class_exists(type_str):
						_add_issue(1, "Node type '%s' might not exist or isn't a registered global class." % type_str, child.key)
						
			"animations":
				if child.type == "block" and not child.key.begins_with("animation"):
					_add_issue(0, "Only 'animation' blocks are allowed inside 'animations'.", child.key)
					
			"animation":
				if child.type == "block" and not child.key.begins_with("track"):
					_add_issue(0, "Only 'track' blocks are allowed inside 'animation'.", child.key)
					
			"tweens":
				if child.type == "block" and not child.key.begins_with("tween"):
					_add_issue(0, "Only 'tween' blocks are allowed inside 'tweens'.", child.key)
					
			"interactivity":
				if child.type == "call" and child.key not in ["state", "trigger"]:
					_add_issue(0, "Only 'state' and 'trigger' calls are allowed inside 'interactivity'.", child.key)
					
			"state", "trigger":
				if child.type == "prop" and child.key != "condition":
					_add_issue(1, "Unexpected property '%s' in state/trigger." % child.key, child.key)
				elif child.type == "block" and child.key != "action":
					_add_issue(0, "Only 'action' blocks are allowed inside state/trigger.", child.key)
					
			"action":
				if child.type == "call" and child.key not in ["play", "set", "run"]:
					_add_issue(0, "Only 'play', 'set', or 'run' calls are allowed in 'action'.", child.key)
					
		# 2. Determine the context for the child's children
		var next_context = context
		if child.type == "block":
			if child.key.begins_with("animation"): next_context = "animation"
			elif child.key.begins_with("track"): next_context = "track"
			elif child.key.begins_with("tween"): next_context = "tween"
			elif child.key == "action": next_context = "action"
			# In 'tree', context remains 'tree' so we validate nested nodes properly
		elif child.type == "call":
			if child.key in ["state", "trigger"]: next_context = child.key
				
		if child.children.size() > 0:
			_validate_recursive(child, next_context)

func _add_issue(sev: int, msg: String, ctx: String) -> void:
	var issue = Issue.new()
	issue.severity = sev
	issue.message = msg
	issue.context = ctx
	issues.append(issue)
