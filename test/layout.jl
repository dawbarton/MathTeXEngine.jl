function test_same_layout(layout1, layout2)
    @test all(layout1.positions .== layout2.positions)
    @test all(layout1.scales .== layout2.scales)

    for (elem1, elem2) in zip(layout1.elements, layout2.elements)
        if elem1 isa TeXElement
            @test elem1 == elem2
        else
            test_same_layout(elem1, elem2)
        end
    end
end

@testset "Layout" begin
    @testset "Decorated" begin
        expr = manual_texexpr((:decorated, 'x', 'b', 't'))
        layout = tex_layout(expr, FontFamily())
        @test length(layout.elements) == 3
        @test layout.positions[2][2] < layout.positions[3][2]
        @test layout.scales[1] == 1
        @test layout.scales[2] < 1
        @test layout.scales[3] < 1

        expr = manual_texexpr((:decorated, 'y', nothing, 't'))
        layout = tex_layout(expr, FontFamily())
        @test layout.elements[2] == Space(0)

        expr = manual_texexpr((:decorated, 'z', 'b', nothing))
        layout = tex_layout(expr, FontFamily())
        @test layout.elements[3] == Space(0)

        @test length(generate_tex_elements(L"a_b^c")) == 3
        @test length(generate_tex_elements(L"_b^c")) == 2
    end

    @testset "Delimited" begin
        expr = manual_texexpr((:delimited, '(', L"\sum_a^b", ')'))
        layout = tex_layout(expr, FontFamily())

        hs = inkheight.(layout.elements) .* layout.scales
        @test hs[1] >= hs[2]
        @test hs[3] >= hs[2]
    end

    @testset "Font" begin
        expr = manual_texexpr((:char, 'u'))
        texchar = tex_layout(expr, FontFamily())
        @test isa(texchar, TeXChar)

        expr = manual_texexpr((:font, :rm, 'u'))
        texchar = tex_layout(expr, FontFamily())
        @test isa(texchar, TeXChar)
    end

    @testset "Group" begin
        expr = manual_texexpr((:group, 'a', 'b', 'c'))
        layout = tex_layout(expr, FontFamily())
        @test length(layout.elements) == 3
        @test length(layout.positions) == 3
        @test length(layout.scales) == 3
        @test all([pos[2] == 0 for pos in layout.positions])
        @test all(layout.scales .== 1)

        expr = manual_texexpr((:group, 'x', (:group, 'y')))
        layout = tex_layout(expr, FontFamily())
        subexpr = manual_texexpr((:group, 'y'))
        sublayout = tex_layout(subexpr, FontFamily())
        @test length(layout.elements) == 2
        @test length(layout.positions) == 2
        @test length(layout.scales) == 2
        test_same_layout(sublayout, layout.elements[2])

        @test isempty(generate_tex_elements(L"{}"))
        @test isempty(generate_tex_elements(L""))
    end

    @testset "Space" begin
        elems = generate_tex_elements(L"\quad a")
        @test length(elems) == 1
        char, pos, size = first(elems)
        @test pos[1] == 1

        elems = generate_tex_elements(L"\qquad b")
        @test length(elems) == 1
        char, pos, size = first(elems)
        @test pos[1] == 2
    end

    @testset "Italic boundary correction" begin
        old = MathTeXEngine._italic_correction_enabled[]
        try
            MathTeXEngine._italic_correction_enabled[] = false
            without = generate_tex_elements(L"(f)x η(t)")

            MathTeXEngine._italic_correction_enabled[] = true
            with = generate_tex_elements(L"(f)x η(t)")

            xpos(elems, i) = elems[i][2][1]

            # Issue #142: roman delimiters next to italic glyphs should not
            # inherit an asymmetric font-side gap.
            @test xpos(with, 2) > xpos(without, 2)
            @test xpos(with, 3) > xpos(without, 3)

            # Issue #95: the same boundary correction also applies to lower
            # case Greek followed by roman delimiters in subscripts/labels.
            @test MathTeXEngine.is_slanted(with[5][1])
            @test xpos(with, 7) - xpos(with, 6) < xpos(without, 7) - xpos(without, 6)
            @test xpos(with, 8) - xpos(with, 7) > xpos(without, 8) - xpos(without, 7)
        finally
            MathTeXEngine._italic_correction_enabled[] = old
        end
    end

    @testset "Function spacing" begin
        xpos(elems, i) = elems[i][2][1]

        # Issue #129: LaTeX inserts a thin space after math operators when
        # the argument is not parenthesized.
        @test xpos(generate_tex_elements(L"\log x"), 4) >
              xpos(generate_tex_elements(L"\mathrm{log}x"), 4) + 0.1
        @test xpos(generate_tex_elements(L"\sin\alpha"), 4) >
              xpos(generate_tex_elements(L"\mathrm{sin}\alpha"), 4) + 0.1

        # No operator space is inserted before an opening delimiter.
        @test xpos(generate_tex_elements(L"\log(x)"), 4) ≈
              xpos(generate_tex_elements(L"\mathrm{log}(x)"), 4)
    end

    @testset "Subscript spacing respects italic overhangs" begin
        ink_start(element) = element[2][1] + element[3] * leftinkbound(element[1])
        ink_end(element) = element[2][1] + element[3] * rightinkbound(element[1])

        font_names = sort(collect(keys(MathTeXEngine.default_font_families)))
        cases = (L"N_\nu", L"J_\nu", L"x_{\alpha(k)}")

        for font_name in font_names, tex in cases
            elems = generate_tex_elements(tex, MathTeXEngine.FontFamily(font_name))
            @test ink_start(elems[2]) + 0.002 >= ink_end(elems[1])
        end

        elems = generate_tex_elements(L"N_\nu L_\nu A_\nu J_\nu")
        @test ink_start(elems[2]) >= ink_end(elems[1])
        @test ink_start(elems[8]) >= ink_end(elems[7])

        # Issue #95 includes a nested subscript case where the inner `(k)`
        # should stay inside the lower script instead of being squeezed left.
        for font_name in font_names
            elems = generate_tex_elements(
                L"v_{(a + b)_k}^i",
                MathTeXEngine.FontFamily(font_name),
            )
            @test ink_start(elems[7]) + 0.002 >= ink_end(elems[6])
        end
    end
end

@testset "Generate elements" begin
    elems = generate_tex_elements(L"a + b")
    @test length(elems) == 3

    elems = generate_tex_elements(L"{{a + b} - {c * d}}")
    @test length(elems) == 7

    # Check the following does not error
    tex =
        L"\lim_{α →\infty} A^j v_{(a + b)_k}^i \sqrt{2} x!= \sqrt{\frac{1+2}{4+a+x}}\int_{0}^{2π} \sin(x) dx"
    generate_tex_elements(tex)

    tex = L"Momentum $p_x$ (a.u.)"
    generate_tex_elements(tex)

    tex = L"Average $\overline{an}_i$"
    @test length(generate_tex_elements(tex)) == 12

    elems = generate_tex_elements(L"Time $t_0$")
    @test length(elems) == 7
end
