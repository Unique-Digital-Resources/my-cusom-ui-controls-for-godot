@tool
extends EditorScript

## V2 Test Suite for AI Scene Format.
## To run: Open this script in the Godot Script Editor and go to File -> Run (Ctrl+Shift+X).

func _run() -> void:
	print("\n=== 🧪 STARTING AI SCENE FORMAT V2 TESTS ===")
	
	_test_layout_format()
	_test_animation_format()
	_test_interaction_format()
	
	print("\n=== ✅ ALL TESTS COMPLETED ===\n")

func _test_layout_format() -> void:
	print("\n--- Testing Layout Format ---")
	var text = """
tree {
    Control Root {
        Button MyBtn {
			text = "Test"
        }
    }
}
"""
	var parser = AIParserBase.new()
	var roots = parser.parse(text)
	var tree_ast = null
	for r in roots:
		if r.type == "tree": tree_ast = r
		
	var root_node = Control.new()
	root_node.name = "Root"
	AILayoutExporter.apply_tree(root_node, tree_ast)
	
	if root_node.get_node_or_null("MyBtn"):
		print("✅ Layout Test Passed: Node created.")
	else:
		push_error("❌ Layout Test Failed: Node missing.")
		
	root_node.queue_free()

func _test_animation_format() -> void:
	print("\n--- Testing Animation Format ---")
	var text = """
animations {
	animation "intro" {
        length = 1.0
		track "Btn:modulate" {
            type = VALUE
            interp = LINEAR
            keyframe 0.0 = Color(1,1,1,0) ease(SINE, IN)
            keyframe 1.0 = Color(1,1,1,1) ease(SINE, IN)
        }
    }
}
"""
	var parser = AIParserBase.new()
	var roots = parser.parse(text)
	var anim_ast = null
	for r in roots:
		if r.type == "animations": anim_ast = r
		
	var anim_parser = AIAnimationParser.new()
	var anims = anim_parser.parse_animations(anim_ast)
	
	var root_node = Control.new()
	root_node.name = "Root"
	var player = AnimationPlayer.new()
	root_node.add_child(player)
	
	# FIX: Added the 3rd root_node argument
	AIAnimationExporter.apply_animations(player, anims, root_node)
	
	if player.has_animation(""):
		if player.get_animation_library("").has_animation("intro"):
			print("✅ Animation Test Passed: Animation created.")
		else:
			push_error("❌ Animation Test Failed: Animation 'intro' not found.")
	else:
		push_error("❌ Animation Test Failed: Library not found.")
		
	root_node.queue_free()

func _test_interaction_format() -> void:
	print("\n--- Testing Interaction Format ---")
	var text = """
interactivity {
	state("Btn", "hovered") {
		condition = "is_hovered == true"
        action {
			play("fade")
        }
    }
}
"""
	var parser = AIParserBase.new()
	var roots = parser.parse(text)
	var interact_ast = null
	for r in roots:
		if r.type == "interactivity": interact_ast = r
		
	var i_parser = AIInteractionParser.new()
	var interactions = i_parser.parse_interactions(interact_ast)
	
	var dummy_node = Node.new()
	AIInteractionExporter.apply_changes(dummy_node, interactions)
	
	if dummy_node.has_meta(AIInteractionImporter.META_KEY):
		print("✅ Interaction Test Passed: Metadata saved.")
	else:
		push_error("❌ Interaction Test Failed: Metadata not saved.")
		
	dummy_node.queue_free()
