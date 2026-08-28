Here is a breakdown of the styling features currently available in the plugin, as well as what is not yet supported.

### ✅ Currently Available Styling Features

**1. Global Properties (via Inspector on the `Math` Node)**
These apply to the entire equation globally:
*   **Font**: You can assign any `FontFile` resource to change the typeface entirely.
*   **Base Size**: Scales the whole equation up or down.
*   **Color**: Changes the text and vector drawing color for the whole tree.
*   **Item Spacing**: Controls horizontal space between operators and symbols (`a + b`).
*   **Script Spacing**: Controls horizontal space *inside* limits and scripts (`i = 1`).
*   **Limit Gap**: Controls the vertical gap between the base and its super/subscripts.
*   **Script Scale**: The size ratio of scripts/limits relative to the base.
*   **Line Thickness**: Thickness of fraction bars, radical hooks, and matrix brackets.

**2. Inline LaTeX-like Styling (Local Overrides)**
These can be wrapped around any part of the formula to override the global styles:
*   **Color**: `\color{#FF0000}{x+y}` or `\color{red}{x+y}` (Changes the color of a specific block).
*   **Size**: `\size{1.5}{x+y}` (Scales the font size of a specific block by a multiplier).
*   **Bold**: `\bold{x+y}` (Fakes bold by slightly increasing the scale, since Godot draws single glyphs).

**3. Manual Godot Control Overrides**
Because the plugin generates actual Godot `Control` nodes, you can expand the `GeneratedRoot` in the Scene Tree and manually tweak individual nodes:
*   Change a specific node's `modulate` or `self_modulate` property.
*   Animate the position, scale, or rotation of individual symbols using Godot's AnimationPlayer.
*   Hide specific elements by toggling their `visible` property.

---

### ❌ Not Currently Available (Standard LaTeX Features)

**1. True Font Weights & Variations**
*   `\mathbf{...}`, `\textbf{...}`: True bold text. (Our `\bold` is a size hack).
*   `\mathit{...}`, `\textit{...}`: Italics.
*   `\mathcal{...}`: Calligraphic letters.
*   `\mathbb{...}`: Blackboard bold (e.g., $\mathbb{R}$).
*   *Reason*: Godot's `draw_string` uses a single font resource. Switching to bold/italics dynamically requires preloading multiple font variations and switching them in the `RenderContext`, which isn't implemented yet.

**2. Accents and Over/Under Lines**
*   `\overline{x}`, `\underline{x}`
*   `\vec{v}`, `\hat{x}`, `\dot{x}`, `\ddot{x}`
*   *Reason*: There are no AST nodes or vector drawing routines for accents yet.

**3. Background Colors / Highlights**
*   `\colorbox{yellow}{x}` 
*   *Reason*: The `StyleGroupControl` currently only intercepts text color, not background drawing.

**4. Advanced Spacing Commands**
*   `\quad`, `\qquad`, `\,`, `\;`, `\!`
*   *Reason*: The lexer doesn't map these to spacing tokens yet.

**5. Multi-Font Environments**
*   Standard LaTeX puts variables in italics and operators in standard text. Our plugin currently renders everything in the exact same font style.

---

### Want to add one of these?
Most of these can be added in about 10 minutes by extending the `StyleGroupControl`. For example, to add `\overline`:
1. Add `OVERLINE` to the `ElementType` enum.
2. Add a `_parse_overline()` function to `parser.gd`.
3. Create an `OverlineControl.gd` that arranges its child and calls `draw_line()` above it in `_draw()`.
