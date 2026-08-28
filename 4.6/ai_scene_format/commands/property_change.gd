@tool
class_name AICommandPropertyChange
extends RefCounted

## Applies property/resource modifications to Godot Objects.

static func execute(target: Object, prop) -> void:
	if not target: return
	
	# FIX: Handle both V1 AIPropertyModel and V2 direct values
	if prop is AIPropertyModel:
		AIPropertyUtils.apply_property_to_target(target, prop.name, prop.value)
	elif prop is Dictionary and prop.has("name"):
		AIPropertyUtils.apply_property_to_target(target, prop.name, prop.value)
	else:
		# If it's just a raw value, we can't apply it without a name, so skip.
		pass
