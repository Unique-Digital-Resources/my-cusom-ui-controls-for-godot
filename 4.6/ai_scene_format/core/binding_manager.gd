@tool
class_name AIBindingManager
extends RefCounted

## V2 Reactive Binding Manager.
## Evaluates variables, loads external sources, and connects to backend Godot nodes
## to emit a signal when the UI needs to update.

signal vars_changed

var evaluated_vars: Dictionary = {}
var backend_nodes: Dictionary = {} # Cache of connected autoloads/nodes
var _expression_vars: Array = [] # Cache of expressions to re-evaluate

func setup(vars_ast: AIParserBase.ASTNode) -> void:
	if not vars_ast: return
	evaluated_vars.clear()
	backend_nodes.clear()
	_expression_vars.clear()
	
	# 1. Evaluate base vars (backend and source)
	for child in vars_ast.children:
		if child.type == "prop":
			var val = child.value
			if val is Dictionary:
				match val.get("__type__"):
					"backend":
						var node_path = val.get("node", "")
						var prop_name = val.get("prop", "")
						_connect_backend(node_path, prop_name, child.key)
					"source":
						var path = val.get("path", "")
						var data = _load_source(path)
						if data: evaluated_vars[child.key] = data
			else:
				evaluated_vars[child.key] = val
				
	# 2. Evaluate reactive expressions (now that base vars exist)
	for child in vars_ast.children:
		if child.type == "prop" and child.value is Dictionary and child.value.get("__type__") == "expr":
			var code = child.value.get("code", "")
			_expression_vars.append({"name": child.key, "code": code})
			evaluated_vars[child.key] = _evaluate_expression(code)
			
	vars_changed.emit()

func _connect_backend(node_path: String, prop_name: String, var_name: String) -> void:
	var tree = Engine.get_main_loop() as SceneTree
	if not tree or not tree.root: return
	
	var node = tree.root.get_node_or_null(NodePath("/root/" + node_path))
	if not node:
		push_warning("AI Scene Format V2: Backend node not found: /root/" + node_path)
		evaluated_vars[var_name] = null
		return
		
	backend_nodes[node_path] = node
	evaluated_vars[var_name] = node.get(prop_name)
	
	# FIX: Godot 4 doesn't have a generic 'property_changed' signal.
	# Look for the standard convention: '<property>_changed' signal.
	var signal_name = prop_name + "_changed"
	if node.has_signal(signal_name):
		if not node.is_connected(signal_name, Callable(self, "_on_backend_signal_changed")):
			# Bind the var_name so we know what to update when the signal fires
			node.connect(signal_name, _on_backend_signal_changed.bind(var_name))
	else:
		push_warning("AI Scene Format V2: Backend node '" + node_path + "' does not emit signal '" + signal_name + "'. UI will not react to changes.")

func _on_backend_signal_changed(value: Variant, var_name: String) -> void:
	evaluated_vars[var_name] = value
	_re_evaluate_expressions()
	vars_changed.emit()

func _re_evaluate_expressions() -> void:
	for expr_var in _expression_vars:
		evaluated_vars[expr_var.name] = _evaluate_expression(expr_var.code)

func _evaluate_expression(code: String) -> Variant:
	var expr = Expression.new()
	var var_names = evaluated_vars.keys()
	var var_values = evaluated_vars.values()
	
	var error = expr.parse(code, var_names)
	if error != OK:
		push_warning("AI Scene Format V2: Expression parse error: " + code)
		return null
		
	return expr.execute(var_values, self, false)

func _load_source(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_warning("AI Scene Format V2: Source file not found: " + path)
		return null
		
	var file = FileAccess.open(path, FileAccess.READ)
	var text = file.get_as_text()
	file.close()
	
	if path.ends_with(".json"):
		return JSON.parse_string(text)
		
	return text
