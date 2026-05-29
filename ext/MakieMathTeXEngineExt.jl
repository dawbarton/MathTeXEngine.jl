# MakieMathTeXEngineExt — add Makie.compile_text / place_text! methods for
# MathTeXEngine.DefaultLaTeXHandler, wiring the MathTeXEngine layout engine
# into the Makie text_handler protocol.
#
# DefaultLaTeXHandler is defined in the main MathTeXEngine module so users can
# reference it without needing to name this extension directly.  This extension
# fills in the Makie-protocol methods once Makie is loaded.
#
# MathTeXEngine has fixed bundled fonts, so the `font` / `fonts` plot attributes
# are accepted but not used for layout; each formula is cached by content only.
#
# Loaded automatically when both MathTeXEngine and Makie are in the same session.

module MakieMathTeXEngineExt

import MathTeXEngine
import Makie
using GeometryBasics: Point2f, Rect2f
using LaTeXStrings: LaTeXString

# ── compile_text ──────────────────────────────────────────────────────────────

function Makie.compile_text(
        h::MathTeXEngine.DefaultLaTeXHandler,
        src::LaTeXString,
        font, fonts, fontsize, lineheight, justification, word_wrap_width,
    )
    # Strip surrounding $ delimiters that LaTeXStrings adds automatically.
    key = _strip_math_delimiters(String(src))
    # The cache stores Any to avoid a compile-time dependency on CompiledText
    # in the main module; cast on retrieval.
    return get!(h._cache, key) do
        _compile(key)
    end::Makie.CompiledText
end

# ── Internal helpers ──────────────────────────────────────────────────────────

function _strip_math_delimiters(s::AbstractString)
    str = String(s)
    length(str) >= 2 && str[1] == '$' && str[end] == '$' && return str[2:(end - 1)]
    return str
end

function _compile(src::String)::Makie.CompiledText
    all_els = MathTeXEngine.generate_tex_elements(src)

    glyphs = Makie.PlacedGlyph[]
    rules = Makie.PlacedRule[]
    has_bounds = false
    bounds = Rect2f(0.0f0, 0.0f0, 0.0f0, 0.0f0)

    for (el, pos, scale) in all_els
        if el isa MathTeXEngine.TeXChar
            ext = Makie.GlyphExtent(el)
            push!(
                glyphs, Makie.PlacedGlyph(
                    UInt64(el.glyph_id),
                    el.font,
                    Point2f(pos),
                    ext,
                    Float32(scale),
                    nothing,   # inherit block color
                )
            )

            # Accumulate em-unit formula bounds using the height-insensitive box
            # (advance width × font ascender/descender), matching Makie's existing
            # texelems_and_glyph_collection alignment convention.
            # Origin of the height-insensitive box: (0, descender); width: hadvance.
            el_bounds = Rect2f(
                (pos[1], pos[2] + ext.descender * scale),
                (ext.hadvance * scale, (ext.ascender - ext.descender) * scale),
            )
            bounds = has_bounds ? union(bounds, el_bounds) : el_bounds
            has_bounds = true

        elseif el isa MathTeXEngine.HLine
            # MTE HLine position (x, y) is the left endpoint of the centerline.
            push!(
                rules, Makie.PlacedRule(
                    Point2f(pos[1], pos[2]),
                    Point2f(pos[1] + Float32(el.width), pos[2]),
                    Float32(el.thickness),
                )
            )

        elseif el isa MathTeXEngine.VLine
            # MTE VLine position is the bottom endpoint of the centerline.
            push!(
                rules, Makie.PlacedRule(
                    Point2f(pos[1], pos[2]),
                    Point2f(pos[1], pos[2] + Float32(el.height)),
                    Float32(el.thickness),
                )
            )
        end
    end

    return Makie.CompiledText(glyphs, rules, bounds)
end

end # module MakieMathTeXEngineExt
