using Test

using MathTeXEngine

import MathTeXEngine: manual_texexpr, texparse
import MathTeXEngine: TeXParseError

import MathTeXEngine: tex_layout, generate_tex_elements
import MathTeXEngine: Space, TeXElement
import MathTeXEngine: load_font
import MathTeXEngine: hadvance, inkheight, inkwidth, xheight
import MathTeXEngine: bottominkbound, leftinkbound, rightinkbound, topinkbound

include("texexpr.jl")
include("parser.jl")
include("fonts.jl")
include("layout.jl")

if get(ENV, "MTE_GENERATE_SPACING_VISUALS", "false") in ("1", "true", "yes")
    @testset "Spacing visual inspection sheet" begin
        include(joinpath(@__DIR__, "..", "reference", "spacing_visuals.jl"))
        path = generate_spacing_visuals()
        @info "Wrote spacing visual inspection sheet" path
        @test isfile(path)
    end
end
