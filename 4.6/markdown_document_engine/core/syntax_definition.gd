class_name SyntaxDefinition extends RefCounted

enum Kind { INLINE, BLOCK }

var name: String
var kind: int = Kind.INLINE
var open_token: String
var close_token: String
var provider: String = ""

func _init(p_name: String = "", p_kind: int = Kind.INLINE, p_open: String = "", p_close: String = "", p_provider: String = "") -> void:
	name = p_name
	kind = p_kind
	open_token = p_open
	close_token = p_close
	provider = p_provider
