class_name AIRegistry
extends RefCounted

## Registers formats, node/property adapters and serializers.
## Upgraded in Phase 9 to cache default resource instances for fast default-filtering.

var registered_formats: Dictionary = {}
var node_adapters: Dictionary = {}
var property_adapters: Dictionary = {}

# Cache for default resource instances to check if properties are default
var _default_resource_cache: Dictionary = {} 

func register_format(format_id: String, format_class) -> void:
    registered_formats[format_id] = format_class

func get_format(format_id: String):
    return registered_formats.get(format_id)

func register_node_adapter(node_type: String, adapter) -> void:
    node_adapters[node_type] = adapter

func register_property_adapter(prop_type: String, adapter) -> void:
    property_adapters[prop_type] = adapter

# Creates a pristine instance of a resource to compare default values
func get_default_resource(type: String, script_path: String = "") -> Resource:
    var cache_key = type + "|" + script_path
    if _default_resource_cache.has(cache_key):
        return _default_resource_cache[cache_key]
        
    var res: Resource = null
    if script_path != "":
        var script = load(script_path)
        if script:
            res = script.new()
    
    if not res and ClassDB.class_exists(type):
        if ClassDB.is_parent_class(type, "Resource"):
            res = ClassDB.instantiate(type)
            
    if res:
        _default_resource_cache[cache_key] = res
        
    return res