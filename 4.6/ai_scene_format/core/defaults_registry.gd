@tool
class_name AIDefaultsRegistry
extends RefCounted

## Strict, deterministic default values interface.
## This acts purely as an interface to Godot's internal ClassDB and property revert system.
## It completely handles inheritance (Control -> CanvasItem -> Node) automatically.

# Cache for pristine objects to compare defaults for editor-injected properties
static var _pristine_cache: Dictionary = {}

static func is_default(target: Object, prop_name: String, value: Variant) -> bool:
	if not target: return false
	
	var class_name_val = target.get_class()
	
	# 1. Query Godot's internal compiled class database (ClassDB)
	# This covers 95% of properties (position, modulate, text, visible, etc.)
	var default_val = ClassDB.class_get_property_default_value(class_name_val, prop_name)
	if default_val != null:
		return _are_values_equal(value, default_val)
			
	# 2. Fallback to Object.property_get_revert (Handles editor-specific defaults like Theme overrides)
	if target.property_can_revert(prop_name):
		var revert_val = target.property_get_revert(prop_name)
		return _are_values_equal(value, revert_val)
		
	# 3. Fallback to comparing against a pristine instance of the class
	# This catches dynamic or script-injected properties.
	var pristine = _get_pristine(class_name_val)
	if pristine:
		var pristine_val = pristine.get(prop_name)
		return _are_values_equal(value, pristine_val)
		
	# If Godot doesn't know the default, assume it's not a default (serialize it)
	return false

static func _get_pristine(p_class_name: String) -> Object:
	if _pristine_cache.has(p_class_name):
		return _pristine_cache[p_class_name]
		
	if ClassDB.class_exists(p_class_name) and ClassDB.can_instantiate(p_class_name):
		var obj = ClassDB.instantiate(p_class_name)
		_pristine_cache[p_class_name] = obj
		return obj
		
	return null

static func _are_values_equal(val1: Variant, val2: Variant) -> bool:
	if typeof(val1) != typeof(val2):
		# Handle null vs object null
		if val1 == null and val2 == null: return true
		return false
		
	match typeof(val1):
		TYPE_COLOR:
			return val1.is_equal_approx(val2)
		TYPE_VECTOR2, TYPE_VECTOR2I, TYPE_VECTOR3, TYPE_VECTOR3I:
			return val1.is_equal_approx(val2)
		TYPE_FLOAT:
			return abs(val1 - val2) < 0.001
		TYPE_OBJECT:
			return val1 == val2
		TYPE_ARRAY:
			if val1.size() != val2.size(): return false
			for i in range(val1.size()):
				if not _are_values_equal(val1[i], val2[i]): return false
			return true
		TYPE_DICTIONARY:
			if val1.size() != val2.size(): return false
			for key in val1.keys():
				if not val2.has(key) or not _are_values_equal(val1[key], val2[key]): return false
			return true
		_:
			return val1 == val2
