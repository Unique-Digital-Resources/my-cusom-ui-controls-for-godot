Before we plan the next phases, I want to clarify a quick status update: we **already implemented** many of the features on your "Not Supported" list in Phases 14, 15, and 16!

*   ✅ **Greek Letters & Symbols**: Fixed! We added a full Unicode mapping in Phase 13/14. `\alpha` now renders as `α`.
*   ✅ **Spacing Commands**: Fixed! Phase 16 added `\quad`, `\qquad`, `\,`, `\;`, and `\!`.
*   ✅ **Overlines & Accents**: Fixed! Phase 15 added `\overline`, `\underline`, `\vec`, and `\hat`.
*   ✅ **Font Styling (Partial)**: Fixed! Phase 14 added true `\mathbf` and `\mathit`.

Here is the plan for the **remaining** missing features from your list. I have organized them into three new phases (17, 18, and 19).

---

# Phase 17 — Special Font Styles (`\mathbb`, `\mathcal`)

**Goal:** Support blackboard bold (e.g., $\mathbb{R}$, $\mathbb{N}$) and calligraphic (e.g., $\mathcal{F}$) fonts.

### Features
*   Parse `\mathbb{...}` and `\mathcal{...}` commands.
*   Map standard alphabets to their Unicode equivalents (e.g., `A` → `𝔸`, `F` → `ℱ`) so they render correctly even without specialized font files.
*   Allow users to assign dedicated `FontFile` resources for these styles in the Inspector if they prefer real font glyphs over Unicode mappings.

### Files
```text
utils/
	constants.gd                 # Add MATHBB, MATHCAL to ElementType (or handle as STYLE_GROUP)

nodes/
	math.gd                      # Add export vars for font_blackboard, font_caligraphic

layout/
	render_context.gd            # Carry the new font references

parser/
	parser.gd                    # Parse \mathbb and \mathcal as STYLE_GROUP nodes

generator/
	control_factory.gd           # Map A-Z to 𝔸-𝕫 or ℬ-𝒵, or assign the dedicated font

controls/
	symbol.gd                    # Logic to select the correct font based on context
	style_group.gd               # Apply the blackboard/caligraphic font to children
```

---

# Phase 18 — Complex Environments (`align`, `array`)

**Goal:** Support multi-line aligned equations and matrices with vertical bars.

### Features
*   **`\begin{align}`**: Aligns multiple equations at the `&` symbol (e.g., `x &= y \\ 2x &= 2y`).
*   **`\begin{array}{c|c}`**: Renders matrices with vertical dividing lines between columns.
*   Update the `MatrixControl` to handle alignment markers (`&`) differently based on the environment type.

### Files
```text
controls/
	matrix.gd                    # Update measure/arrange to handle 'align' (right-align left side, left-align right side)
								 # Update _draw() to draw vertical lines for 'array' based on column definitions (c|c)

parser/
	parser.gd                    # Parse column alignment definitions (e.g., {c|c}) and store as metadata
```

---

# Phase 19 — Custom Macros & Preprocessing

**Goal:** Allow users to define their own shorthand commands to keep formulas clean.

### Features
*   Parse `\newcommand{\name}{definition}` and `\def\name{definition}`.
*   Pre-process the formula string *before* lexing: replace all instances of `\name` with the `definition` string.
*   Support macro arguments (e.g., `\newcommand{\plus}[2]{#1 + #2}`).

### Files
```text
parser/
	latex_importer.gd            # NEW: Add a regex/string-replacement preprocessing step to expand macros
	plain_math_importer.gd       # Update to support macro expansion
	macro_processor.gd           # NEW: Utility class dedicated to extracting and replacing \newcommand definitions
```

---

## Development Dependency Graph

```text
Phase 17 (Special Fonts)
	↓
Phase 18 (Complex Environments)
	↓
Phase 19 (Custom Macros)
```

### Why this order?
**Phase 17** is quickest and finishes the font/styling engine. **Phase 18** updates the existing `MatrixControl` to be much more powerful. **Phase 19** comes last because macro preprocessing happens entirely at the string level before the AST is even built, making it an independent wrapper around the existing parser.

Let me know if you want to start implementing Phase 17!
