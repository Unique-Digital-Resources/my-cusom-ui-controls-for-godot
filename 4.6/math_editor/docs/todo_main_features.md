The plugin currently supports a **very large subset** of standard mathematical LaTeX, but it is **not a 100% complete LaTeX engine**. By design (as outlined in the PRD), it focuses on generating an editable Control tree for formulas rather than compiling full TeX documents.

Here is a breakdown of exactly what it supports right now, and what it doesn't.

### ✅ What is Fully Supported (Visually & Structurally)

1. **Basic Operations & Alignments**
   * Symbols, Numbers, Variables
   * Operators: `+`, `-`, `*`, `/`, `=`, `<`, `>`
   * Automatic spacing around operators
   * Baseline alignment for sequences (`a + b = c`)

2. **Scripts (Super/Sub)**
   * `x^2`, `a_{ij}`, `x^{ab}`, `a^{b^c}` (nested scripts)

3. **Fractions**
   * LaTeX fractions: `\frac{a}{b}`
   * Inline fractions: `a/b`
   * Nested fractions

4. **Roots (Radicals)**
   * Square roots: `\sqrt{x}`
   * Nth roots: `\sqrt[3]{y}`
   * Nested roots

5. **Fences (Delimiters)**
   * Stretchable parentheses `()`, brackets `[]`, braces `\{\}`, and pipes `||`
   * Auto-stretching to fit content height

6. **Matrices & Cases**
   * Standard matrices: `\begin{matrix} a & b \\ c & d \end{matrix}`
   * Cases (with left curly brace and left-alignment): `\begin{cases} ... \end{cases}`
   * Row (`\\`) and column (`&`) separators

7. **Large Operators (Under/Over)**
   * Summations: `\sum_{i=1}^{n}`
   * Products: `\prod`
   * Integrals: `\int`
   * Limits: `\lim_{x \to \infty}`
   * Limits are perfectly centered above and below the operator.

8. **Text inside math**
   * `\text{if } x > 0` (preserves spaces)

9. **Serialization**
   * Export back to clean LaTeX, JSON, or MathML.

---

### ⚠️ What is NOT Supported (Yet)

If you try to use these, they will either render as raw text (e.g., literally showing `\alpha`) or throw a parser error.

1. **Greek Letters & Special Symbols as Vector Graphics**
   * If you type `\alpha` or `\infty`, the lexer treats it as a symbol. It will try to look up the glyph in your assigned font. If the font lacks the glyph, it won't render correctly. (It does not currently map LaTeX commands to Unicode equivalents).

2. **Spacing Commands**
   * `\quad`, `\qquad`, `\,`, `\;` are not parsed to add custom whitespace.

3. **Overlines & Accents**
   * `\overline{x}`, `\vec{v}`, `\hat{x}` are not supported (no AST node or drawer for them yet).

4. **Font Styling Commands**
   * `\mathbb{R}`, `\mathcal{F}`, `\mathbf{v}` (blackboard bold, calligraphic, bold) are not mapped.

5. **Complex Environments**
   * `\begin{align}` for multi-line aligned equations is not supported (only `matrix` and `cases`).
   * `\begin{array}{c|c}` (matrices with vertical bars) is not supported.

6. **Custom Macros**
   * `\newcommand` or `\def` is not supported.

---

### Can it be extended to support these?
**Absolutely.** The architecture was specifically built for extensibility (Phase 18 of the PRD). 

For example, if you wanted to add `\overline{x}`:
1. Add an `OVERLINE` enum to `MathConstants`.
2. Tell the Parser to look for `\overline` and generate an `OVERLINE` AST node.
3. Add an `OverlineControl` to `controls/` that draws a line above its child.
4. Map it in `control_factory.gd`.

Because the layout engine and tree generation are decoupled from the parser, you can add new visual math constructs without breaking existing ones!
