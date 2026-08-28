Here is a structured plan to implement the remaining styling and typographic features. I have organized them into three new phases, keeping the modular, decoupled architecture of the plugin intact.

---

# Phase 14 — Advanced Typography & Multi-Font Support

**Goal:** Introduce true font weight variations (bold, italic) and automatic italicization of mathematical variables.

### Features
*   True bold (`\mathbf`, `\textbf`) using actual bold font files instead of scaling hacks.
*   Italic text (`\mathit`, `\textit`).
*   Multi-font environment: Single-letter variables automatically render in italic, while numbers and operators remain upright (standard LaTeX behavior).
*   Expose font variation properties in the Inspector.

### Files
```text
nodes/
	math.gd                      # Add export vars for italic_font, bold_font, bold_italic_font

layout/
	render_context.gd            # Carry all 4 font references down the tree

controls/
	symbol.gd                    # Logic to select correct font based on text type (var vs op)
	style_group.gd               # Update \bold to use true bold font, add \mathit

parser/
	parser.gd                    # Parse \mathbf, \mathit, \textbf commands

generator/
	control_factory.gd           # Map new style types
```

---

# Phase 15 — Accents & Over/Under Lines

**Goal:** Support drawing lines and vector arrows over or under mathematical elements.

### Features
*   Overlines (`\overline{x}`)
*   Underlines (`\underline{x}`)
*   Vector arrows (`\vec{v}`)
*   Hats (`\hat{x}`)
*   Custom vector drawing for accents that scales perfectly with content.

### Files
```text
utils/
	constants.gd                 # Add OVERLINE, UNDERLINE, VEC, HAT to ElementType

controls/
	accent.gd                    # NEW: Container that measures child, draws above/below, shifts child down if needed

drawing/
	operator_drawer.gd           # Add draw_vec_arrow(), draw_hat() vector routines

parser/
	parser.gd                    # Parse \overline{}, \vec{}, etc. as ACCENT nodes

generator/
	control_factory.gd           # Map ACCENT to AccentControl
	control_generator.gd         # Assign child to AccentControl
```

---

# Phase 16 — Advanced Spacing & Backgrounds

**Goal:** Support manual whitespace commands and background highlighting.

### Features
*   Manual spacing commands (`\quad`, `\qquad`, `\,`, `\;`)
*   Background colors (`\colorbox{yellow}{x+y}`)
*   Spacers integrate seamlessly into the `SequenceControl` measurement logic.

### Files
```text
utils/
	constants.gd                 # Add SPACER to ElementType

controls/
	spacer.gd                    # NEW: Empty control that just returns a width based on em-size
	style_group.gd               # Update to support "bgcolor" type, drawing a rect behind content

parser/
	lexer.gd                     # Tokenize \quad, \, as single commands
	parser.gd                    # Parse spacers into SPACER nodes, parse \colorbox

generator/
	control_factory.gd           # Map SPACER to SpacerControl
```

---

## Development Dependency Graph

```text
Phase 14 (Typography)
	↓
Phase 15 (Accents)
	↓
Phase 16 (Spacing & Backgrounds)
```

### Why this order?
**Phase 14** must come first because Accents (Phase 15) and Backgrounds (Phase 16) need to know the exact true height of the text, which is only accurate once multiple fonts (italic/bold) are properly supported. **Phase 16** comes last because manual spacing is a minor polish feature compared to the structural importance of fonts and accents. 

Let me know if you want to start implementing Phase 14!
