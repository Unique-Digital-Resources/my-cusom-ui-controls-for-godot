@tool
class_name ControlFactory
extends RefCounted

const SymbolControlScript = preload("res://addons/math_editor/controls/symbol.gd")
const SequenceControlScript = preload("res://addons/math_editor/controls/sequence.gd")
const ScriptControlScript = preload("res://addons/math_editor/controls/script.gd")
const FractionControlScript = preload("res://addons/math_editor/controls/fraction.gd")
const RootControlScript = preload("res://addons/math_editor/controls/root.gd")
const FencedControlScript = preload("res://addons/math_editor/controls/fenced.gd")
const MatrixControlScript = preload("res://addons/math_editor/controls/matrix.gd")
const UnderOverControlScript = preload("res://addons/math_editor/controls/under_over.gd")
const StyleGroupControlScript = preload("res://addons/math_editor/controls/style_group.gd")
const AccentControlScript = preload("res://addons/math_editor/controls/accent.gd")
const SpacerControlScript = preload("res://addons/math_editor/controls/spacer.gd")

static func create_control(ast_node: MathAST) -> Control:
	match ast_node.type:
		MathConstants.ElementType.SEQUENCE:
			var node = SequenceControlScript.new()
			node.name = "Sequence"
			return node
		MathConstants.ElementType.SCRIPT:
			var node = ScriptControlScript.new()
			node.name = "Script"
			return node
		MathConstants.ElementType.FRACTION:
			var node = FractionControlScript.new()
			node.name = "Fraction"
			return node
		MathConstants.ElementType.ROOT:
			var node = RootControlScript.new()
			node.name = "Root"
			return node
		MathConstants.ElementType.FENCED:
			var node = FencedControlScript.new(ast_node.open_fence, ast_node.close_fence)
			node.name = "Fenced_" + ast_node.open_fence + ast_node.close_fence
			return node
		MathConstants.ElementType.MATRIX:
			var node = MatrixControlScript.new()
			node.name = "Matrix"
			return node
		MathConstants.ElementType.UNDER_OVER:
			var node = UnderOverControlScript.new()
			node.name = "UnderOver"
			return node
		MathConstants.ElementType.STYLE_GROUP:
			var node = StyleGroupControlScript.new()
			node.style_type = String(ast_node.get_meta("style_type", ""))
			node.style_value = String(ast_node.get_meta("style_value", ""))
			node.name = "Style_" + node.style_type
			return node
		MathConstants.ElementType.ACCENT:
			var node = AccentControlScript.new()
			node.accent_type = String(ast_node.get_meta("accent_type", ""))
			node.name = "Accent_" + node.accent_type.substr(1)
			return node
		MathConstants.ElementType.SPACER:
			var node = SpacerControlScript.new()
			node.em_width = float(ast_node.get_meta("em_width", 0.0))
			node.name = "Spacer_" + str(node.em_width)
			return node
		MathConstants.ElementType.SYMBOL, MathConstants.ElementType.NUMBER:
			var v_ast = ast_node as ValueAST
			var display_text = v_ast.value
			var orig_latex = ""
			var is_op = false
			var is_large = false
			
			if v_ast.type == MathConstants.ElementType.SYMBOL:
				orig_latex = v_ast.value
				match v_ast.value:
					"\\sum": display_text = "∑"; is_large = true
					"\\int": display_text = "∫"; is_large = true
					"\\prod": display_text = "∏"; is_large = true
					"\\lim": display_text = "lim"
					"\\to": display_text = "→"
					"\\infty": display_text = "∞"
					"\\alpha": display_text = "α"
					"\\beta": display_text = "β"
					"\\gamma": display_text = "γ"
					"\\delta": display_text = "δ"
					"\\epsilon": display_text = "ε"
					"\\varepsilon": display_text = "ε"
					"\\zeta": display_text = "ζ"      # FIX: Added missing zeta
					"\\eta": display_text = "η"       # FIX: Added missing eta
					"\\theta": display_text = "θ"
					"\\vartheta": display_text = "ϑ"
					"\\iota": display_text = "ι"      # FIX: Added missing iota
					"\\kappa": display_text = "κ"     # FIX: Added missing kappa
					"\\lambda": display_text = "λ"
					"\\mu": display_text = "μ"
					"\\nu": display_text = "ν"        # FIX: Added missing nu
					"\\xi": display_text = "ξ"        # FIX: Added missing xi
					"\\pi": display_text = "π"
					"\\varpi": display_text = "ϖ"
					"\\rho": display_text = "ρ"
					"\\varrho": display_text = "ϱ"
					"\\sigma": display_text = "σ"
					"\\varsigma": display_text = "ς"
					"\\tau": display_text = "τ"
					"\\upsilon": display_text = "υ"   # FIX: Added missing upsilon
					"\\phi": display_text = "φ"
					"\\varphi": display_text = "ϕ"
					"\\chi": display_text = "χ"       # FIX: Added missing chi
					"\\psi": display_text = "ψ"
					"\\omega": display_text = "ω"
					"\\Delta": display_text = "Δ"
					"\\Theta": display_text = "Θ"
					"\\Lambda": display_text = "Λ"
					"\\Xi": display_text = "Ξ"
					"\\Pi": display_text = "Π"
					"\\Sigma": display_text = "Σ"
					"\\Upsilon": display_text = "Υ"
					"\\Phi": display_text = "Φ"
					"\\Psi": display_text = "Ψ"
					"\\Omega": display_text = "Ω"
					"\\in": display_text = "∈"
					"\\notin": display_text = "∉"
					"\\leq": display_text = "≤"
					"\\geq": display_text = "≥"
					"\\neq": display_text = "≠"
					"\\cdot": display_text = "·"
					"\\times": display_text = "×"
					"\\div": display_text = "÷"
					"\\pm": display_text = "±"
					"\\partial": display_text = "∂"
					"\\nabla": display_text = "∇"
					"\\rightarrow": display_text = "→"
					"\\leftarrow": display_text = "←"
					"\\Rightarrow": display_text = "⇒"
					"\\Leftarrow": display_text = "⇐"
					_: display_text = v_ast.value
					
				if display_text in ["∑", "∫", "∏", "±", "·", "×", "÷", "+", "-", "*", "/", "=", "<", ">", "≤", "≥", "≠", "→", "←"]:
					is_op = true
					
			var node = SymbolControlScript.new(display_text, orig_latex, is_op, is_large)
			node.name = "Symbol_" + display_text
			return node
		MathConstants.ElementType.OPERATOR:
			var o_ast = ast_node as OperatorAST
			var node = SymbolControlScript.new(o_ast.operator, "", true, false)
			node.name = "Operator_" + o_ast.operator
			return node
		_:
			var node = Control.new()
			node.name = "Unknown"
			return node
