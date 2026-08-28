class_name MathConstants

enum ElementType {
	SYMBOL,
	NUMBER,
	OPERATOR,
	SEQUENCE,
	FRACTION,
	SCRIPT,
	ROOT,
	FENCED,
	MATRIX,
	UNDER_OVER,
	STYLE_GROUP,
	ACCENT,
	SPACER             # NEW: For \quad, \,, \;, etc.
}

const DEFAULT_BASE_SIZE        := 32.0
const DEFAULT_SCRIPT_SCALE     := 0.7
const DEFAULT_OPERATOR_SPACING := 0.15
const DEFAULT_LINE_THICKNESS   := 0.06

const PLUGIN_NAME    := "Math Editor"
const PLUGIN_VERSION := "0.1.0"
