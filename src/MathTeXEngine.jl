module MathTeXEngine
# Adapted from matplotlib mathtext engine
# https://github.com/matplotlib/matplotlib/blob/master/lib/matplotlib/_mathtext.py

using AbstractTrees
using Automa
using FreeTypeAbstraction
using LaTeXStrings
using UnicodeFun

using DataStructures: Stack
using GeometryBasics: Point2f, Rect2f
using REPL.REPLCompletions: latex_symbols
using RelocatableFolders

import FreeTypeAbstraction:
    ascender, boundingbox, descender, get_extent, glyph_index,
    hadvance, inkheight, inkwidth,
    height_insensitive_boundingbox, leftinkbound, rightinkbound,
    topinkbound, bottominkbound

export TeXToken, tokenize
export TeXExpr, texparse, TeXParseError, manual_texexpr
export TeXElement, TeXChar, VLine, HLine, generate_tex_elements
export texfont, FontFamily, set_texfont_family!, get_texfont_family
export glyph_index
export DefaultLaTeXHandler

# Reexport from LaTeXStrings
export @L_str

# Advanced layout/parser knobs. These are intentionally not exported, but may
# be toggled by qualified access when debugging regressions.
const italic_correction_enabled = Ref(true)
const unspace_binary_operators_heuristic_enabled = Ref(true)

"""
    DefaultLaTeXHandler()

Text handler for Makie's `text_handler` plot attribute that routes `LaTeXString`
inputs through MathTeXEngine's layout engine.

Requires Makie to be loaded (triggers the `MakieMathTeXEngineExt` extension).
A per-instance content cache avoids re-running the layout engine when only
display attributes (colour, rotation, offset) change.

# Example
```julia
using MathTeXEngine, CairoMakie
fig = Figure()
ax  = Axis(fig[1, 1])
text!(ax, L"\\int_0^\\infty e^{-x}\\,dx", position = (0.5, 0.5),
      text_handler = DefaultLaTeXHandler())
```
"""
struct DefaultLaTeXHandler
    _cache::Dict{String, Any}   # Any: CompiledText is only available once Makie is loaded
end

DefaultLaTeXHandler() = DefaultLaTeXHandler(Dict{String, Any}())

include("parser/tokenizer.jl")
include("parser/texexpr.jl")
include("parser/commands_data.jl")
include("parser/commands_registration.jl")
include("parser/parser.jl")

include("engine/computer_modern_data.jl")
include("engine/new_computer_modern_data.jl")
include("engine/fonts.jl")
include("engine/layout_context.jl")
include("engine/texelements.jl")
include("engine/layout.jl")

end # module
