class_name SpecialFonts
extends RefCounted

## Maps standard characters to their Blackboard Bold and Caligraphic Unicode equivalents.

const BB_MAP = {
	"A": "𝔸", "B": "𝔹", "C": "ℂ", "D": "𝔻", "E": "𝔼", "F": "𝔽", "G": "𝔾", "H": "ℍ",
	"I": "𝕀", "J": "𝕁", "K": "𝕂", "L": "𝕃", "M": "𝕄", "N": "ℕ", "O": "𝕆", "P": "ℙ",
	"Q": "ℚ", "R": "ℝ", "S": "𝕊", "T": "𝕋", "U": "𝕌", "V": "𝕍", "W": "𝕎", "X": "𝕏",
	"Y": "𝕐", "Z": "ℤ",
	"a": "𝕒", "b": "𝕓", "c": "𝕔", "d": "𝕕", "e": "𝕖", "f": "𝕗", "g": "𝕘", "h": "𝕙",
	"i": "𝕚", "j": "𝕛", "k": "𝕜", "l": "𝕝", "m": "𝕞", "n": "𝕟", "o": "𝕠", "p": "𝕡",
	"q": "𝕢", "r": "𝕣", "s": "𝕤", "t": "𝕥", "u": "𝕦", "v": "𝕧", "w": "𝕨", "x": "𝕩",
	"y": "𝕪", "z": "𝕫"
}

const CAL_MAP = {
	"A": "𝒜", "B": "ℬ", "C": "𝒞", "D": "𝒟", "E": "ℰ", "F": "ℱ", "G": "𝒢", "H": "ℋ",
	"I": "ℐ", "J": "𝒥", "K": "𝒦", "L": "ℒ", "M": "ℳ", "N": "𝒩", "O": "𝒪", "P": "𝒫",
	"Q": "𝒬", "R": "ℛ", "S": "𝒮", "T": "𝒯", "U": "𝒰", "V": "𝒱", "W": "𝒲", "X": "𝒳",
	"Y": "𝒴", "Z": "𝒵"
}

static func get_blackboard(text: String) -> String:
	var res = ""
	for ch in text:
		if BB_MAP.has(ch):
			res += BB_MAP[ch]
		else:
			res += ch
	return res

static func get_caligraphic(text: String) -> String:
	var res = ""
	for ch in text:
		if CAL_MAP.has(ch):
			res += CAL_MAP[ch]
		else:
			res += ch
	return res
