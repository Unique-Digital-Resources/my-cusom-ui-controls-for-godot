class_name LatexSymbols
extends RefCounted

static var _symbol_map: Dictionary = {
	"\\sum": "∑", "\\int": "∫", "\\prod": "∏", "\\coprod": "∐", "\\lim": "lim",
	"\\to": "→", "\\rightarrow": "→", "\\leftarrow": "←", "\\Rightarrow": "⇒", "\\Leftarrow": "⇐",
	"\\leftrightarrow": "↔", "\\Leftrightarrow": "⇔", "\\mapsto": "↦", "\\uparrow": "↑", "\\downarrow": "↓",
	"\\infty": "∞", "\\leq": "≤", "\\geq": "≥", "\\neq": "≠", "\\approx": "≈", "\\equiv": "≡",
	"\\sim": "∼", "\\propto": "∝", "\\perp": "⊥", "\\parallel": "∥",
	"\\in": "∈", "\\notin": "∉", "\\subset": "⊂", "\\supset": "⊃", "\\subseteq": "⊆", "\\supseteq": "⊇",
	"\\cup": "∪", "\\cap": "∩", "\\emptyset": "∅", "\\forall": "∀", "\\exists": "∃",
	"\\alpha": "α", "\\beta": "β", "\\gamma": "γ", "\\delta": "δ", "\\epsilon": "ε", "\\varepsilon": "ε",
	"\\zeta": "ζ", "\\eta": "η", "\\theta": "θ", "\\vartheta": "ϑ", "\\iota": "ι", "\\kappa": "κ",
	"\\lambda": "λ", "\\mu": "μ", "\\nu": "ν", "\\xi": "ξ", "\\pi": "π", "\\varpi": "ϖ", "\\rho": "ρ",
	"\\varrho": "ϱ", "\\sigma": "σ", "\\varsigma": "ς", "\\tau": "τ", "\\upsilon": "υ", "\\phi": "φ",
	"\\varphi": "ϕ", "\\chi": "χ", "\\psi": "ψ", "\\omega": "ω",
	"\\Gamma": "Γ", "\\Delta": "Δ", "\\Theta": "Θ", "\\Lambda": "Λ", "\\Xi": "Ξ", "\\Pi": "Π",
	"\\Sigma": "Σ", "\\Upsilon": "Υ", "\\Phi": "Φ", "\\Psi": "Ψ", "\\Omega": "Ω",
	"\\cdot": "·", "\\times": "×", "\\div": "÷", "\\pm": "±", "\\mp": "∓", "\\partial": "∂",
	"\\nabla": "∇", "\\sqrt": "√", "\\angle": "∠", "\\circ": "∘", "\\bullet": "•", "\\star": "⋆",
	"\\dagger": "†", "\\ddagger": "‡", "\\ell": "ℓ", "\\hbar": "ℏ", "\\Re": "ℜ", "\\Im": "ℑ",
	"\\aleph": "ℵ", "\\prime": "′"
}

static func get_symbol(latex_cmd: String) -> String:
	if _symbol_map.has(latex_cmd):
		return _symbol_map[latex_cmd]
	return latex_cmd
