@tool
class_name AIActionDispatcher
extends RefCounted

## V2 Action Dispatcher.
## Evaluates conditions and executes actions (run, play, set) at runtime.

var binding_manager: AIBindingManager
var root_node: Node

func _init(root: Node, manager: AIBindingManager) -> void:
	root_node = root
	binding_manager = manager

func evaluate_condition(condition: String) -> bool:
	if condition.is_empty(): return true
	
	var expr = Expression.new()
	var var_names = binding_manager.evaluated_vars.keys()
	var var_values = binding_manager.evaluated_vars.values()
	
	var known_states = {
		"is_hovered": false,
		"is_pressed": false,
		"is_active": false,
		"ready": true
	}
	for state in known_states.keys():
		if state not in var_names:
			var_names.append(state)
			var_values.append(known_states[state])
			
	var error = expr.parse(condition, var_names)
	if error != OK:
		return false
		
	return bool(expr.execute(var_values, null, false))

func execute_actions(actions: Array, context_node: Node = null) -> void:
	for action in actions:
		match action.type:
			"run":
				_execute_run(action.data)
			"play":
				_execute_play(action.data, context_node)
			"set":
				_execute_set(action.data)

func _execute_run(data: Array) -> void:
	if data.size() < 2: return
	var node_path = data[0]
	var func_name = data[1]
	
	if node_path == "get_tree()":
		var tree = root_node.get_tree()
		if tree and tree.has_method(func_name):
			tree.call(func_name)
		return
		
	var target_node = _resolve_node(node_path)
	if target_node and target_node.has_method(func_name):
		target_node.call(func_name)

func _execute_play(data: Array, context_node: Node) -> void:
	if data.is_empty(): return
	var anim_name = data[0]
	var player_path = data[1] if data.size() > 1 else ""
	
	var player: AnimationPlayer = null
	if not player_path.is_empty():
		player = _resolve_node(player_path) as AnimationPlayer
	elif context_node:
		player = _find_anim_player(context_node)
		
	if player and player.has_animation(anim_name):
		player.play(anim_name)
	else:
		# FIX: Removed tween fallback. Just warn if animation is missing.
		push_warning("AI Scene Format V2: Animation '" + anim_name + "' not found on player.")

func _execute_set(data: Array) -> void:
	if data.size() < 3: return
	var node_path = data[0]
	var prop_name = data[1]
	var value = data[2]
	
	var target_node = _resolve_node(node_path)
	if target_node:
		if value is String and binding_manager.evaluated_vars.has(value):
			value = binding_manager.evaluated_vars[value]
		AIPropertyUtils.apply_property_to_target(target_node, prop_name, value)

func _resolve_node(path: String) -> Node:
	if not root_node: return null
	return AIPathResolver.resolve_path(root_node, path)

func _find_anim_player(node: Node) -> AnimationPlayer:
	if not node: return null
	if node is AnimationPlayer: return node
	for child in node.get_children():
		if child is AnimationPlayer:
			return child
	return _find_anim_player(node.get_parent())
