using CairoMakie
using FileIO
using LaTeXStrings

using MathTeXEngine

const SPACING_VISUAL_FONT_NAMES =
    ["NewComputerModern", "TeXGyreHeros", "TeXGyrePagella", "LucioleMath"]

const SPACING_VISUAL_CASES = Pair{String, Vector{String}}[
    "Issue #142: italic/roman boundaries" => [
        raw"f(t)",
        raw"g(x)",
        raw"(f)x",
        raw"(t)",
        raw"\eta(t)",
        raw"\alpha(t)",
        raw"g(f(x))",
        raw"\mathrm{y}(x)",
        raw"\mathrm{g}t",
    ],
    "Issue #95: lower-case Greek and subscript spacing" => [
        raw"\eta(t)",
        raw"\alpha_k",
        raw"\omega_k",
        raw"\nu(k)",
        raw"N_\nu L_\nu A_\nu J_\nu",
        raw"x_{\alpha(k)}",
        raw"v_{(a + b)_k}^i",
        raw"\partial_i u_j",
        raw"\phi_\varphi \rho_\sigma",
    ],
    "Subscript and superscript combinations" => [
        raw"x_i",
        raw"x^i",
        raw"x_i^j",
        raw"V^i_j",
        raw"x_{i_j}",
        raw"x^{i^j}",
        raw"x_{(a+b)_k}^i",
        raw"T_{\alpha\beta}^{ij}",
        raw"\Gamma^\mu_{\nu\rho}",
        raw"\psi^\dagger_i\psi_i",
    ],
    "PR #151: primes and deep scripts" => [
        raw"x' f'",
        raw"x'' f''",
        raw"x′ f′",
        raw"x\prime f\prime",
        raw"x^\prime f^\prime",
        raw"x'_y f_g'",
        raw"A^{B^{C^{D^E}}}_{F_{G_{H_I}}}",
        raw"f^{A'}",
    ],
    "Roman/upright and capital boundaries" => [
        raw"\mathrm{d}x",
        raw"\mathrm{e}^{-x}",
        raw"\mathrm{Re}\,z",
        raw"\mathrm{Im}\,z",
        raw"\mathrm{Tr}\,A_i^j",
        raw"\mathrm{Cov}(X,Y)",
        raw"A_\nu B_\nu C_\nu D_\nu",
        raw"M\mathrm{M}M",
    ],
    "Issue #129: math operator spacing" => [
        raw"\log x",
        raw"\log(x)",
        raw"\sin x",
        raw"\sin(x)",
        raw"\exp t",
        raw"\exp(t)",
        raw"\max_{t \in \{1,...,5\}}",
    ],
    "Operators, delimiters, and fractions" => [
        raw"-1,\ 2-1,\ (-1)",
        raw"\alpha^*",
        raw"\psi^* \psi",
        raw"\frac{1}{2}\pm\sqrt{3}",
        raw"\frac{1}{2}{}\pm\sqrt{3}",
        raw"\left(\frac{1}{2}\right)f(t)",
        raw"\sqrt{x_i^2+y_i^2}",
        raw"\sum_{k=0}^n a_k x^k",
        raw"\int_0^{2\pi}\sin(x)\,dx",
    ],
    "Script layout issues #93, #105, #110, #126" => [
        raw"\left(\frac{dy}{dx}\right)_0",
        raw"\left(\frac{A^{xy}}{B}\right)^{1/4}",
        raw"(\frac{A^{xy}}{B})^{1/4}",
        raw"\left\langle\left|\int\right|\right\rangle",
        raw"\left\langle\left|\left\langle\left|\int\right|\right\rangle\right|\right\rangle",
        raw"x^{\frac{1}{1+2}}",
        raw"x_{\frac{1}{1+2}}",
    ],
    "Nested expressions" => [
        raw"\frac{\alpha_i+\beta_i}{\gamma_i+\delta_i}",
        raw"\sqrt{\frac{1+\alpha_k}{1+\beta_k}}",
        raw"F_{\mu\nu}F^{\mu\nu}",
        raw"\overline{z}_i",
        raw"\left(\alpha_{(i+j)_k}\right)^2",
        raw"\frac{\partial^2 f}{\partial x_i\partial x_j}",
    ],
]

repo_root() = dirname(@__DIR__)
reference_project_dir() = @__DIR__

function spacing_visual_output_path()
    return get(
        ENV,
        "MTE_SPACING_VISUAL_PATH",
        joinpath(@__DIR__, "spacing_visual_inspection.png"),
    )
end

spacing_baseline_ref() = get(ENV, "MTE_SPACING_BASELINE_REF", "HEAD")

font_latex(font_name, expr) = latexstring("\\fontfamily{$font_name}$expr")

function spacing_label_sheet(
        cases = SPACING_VISUAL_CASES;
        font_names = SPACING_VISUAL_FONT_NAMES,
    )
    row_height = 68
    row_gap = 7
    nrows = sum(length(last(group)) + 1 for group in cases) + 1
    fig_height = row_height * nrows + row_gap * (nrows - 1)
    fig = Figure(size = (2200, max(900, fig_height)), fontsize = 18)

    Label(fig[1, 1], "case"; tellwidth = false, halign = :left, font = :bold)
    for (col, font_name) in enumerate(font_names)
        Label(fig[1, col + 1], font_name; tellwidth = false, halign = :left, font = :bold)
    end

    row = 2
    for (group, exprs) in cases
        Label(
            fig[row, 1:(length(font_names) + 1)],
            group;
            tellwidth = false,
            halign = :left,
            font = :bold,
            fontsize = 17,
        )
        row += 1

        for expr in exprs
            Label(fig[row, 1], expr; tellwidth = false, halign = :left, fontsize = 13)
            for (col, font_name) in enumerate(font_names)
                Label(
                    fig[row, col + 1],
                    font_latex(font_name, expr);
                    tellwidth = false,
                    halign = :left,
                    fontsize = 24,
                )
            end
            row += 1
        end
    end

    colsize!(fig.layout, 1, Relative(0.22))
    for col in 2:(length(font_names) + 1)
        colsize!(fig.layout, col, Relative(0.78 / length(font_names)))
    end
    for row in 1:nrows
        rowsize!(fig.layout, row, Fixed(row_height))
    end
    rowgap!(fig.layout, row_gap)
    return fig
end

function save_spacing_label_sheet(path)
    fig = spacing_label_sheet()
    save(path, fig, px_per_unit = 2)
    return path
end

function render_spacing_sheet_in_subprocess(package_path, output_path)
    julia_executable = joinpath(Sys.BINDIR, Base.julia_exename())
    project_dir = mktempdir()
    cp(
        joinpath(reference_project_dir(), "Project.toml"),
        joinpath(project_dir, "Project.toml"),
    )
    cp(
        joinpath(reference_project_dir(), "Manifest.toml"),
        joinpath(project_dir, "Manifest.toml"),
    )
    script = """
    import Pkg
    Pkg.develop(path=$(repr(package_path)))
    Pkg.instantiate()
    include($(repr(@__FILE__)))
    save_spacing_label_sheet($(repr(output_path)))
    """
    run(`$julia_executable --project=$project_dir -e $script`)
    return output_path
end

function with_baseline_checkout(f)
    if haskey(ENV, "MTE_SPACING_BASELINE_PATH")
        return f(
            ENV["MTE_SPACING_BASELINE_PATH"],
            get(ENV, "MTE_SPACING_BASELINE_LABEL", "baseline"),
        )
    end

    return mktempdir() do dir
        checkout_path = joinpath(dir, "MathTeXEngine-baseline")
        ref = spacing_baseline_ref()
        run(`git -C $(repo_root()) worktree add --detach $checkout_path $ref`)
        try
            return f(checkout_path, ref)
        finally
            run(`git -C $(repo_root()) worktree remove --force $checkout_path`)
        end
    end
end

function add_image_panel!(figpos, image_path, title)
    img = rotr90(load(image_path))
    ax = Axis(figpos; title, aspect = DataAspect())
    hidedecorations!(ax)
    hidespines!(ax)
    image!(ax, img)
    return ax
end

function pixel_darkness(c)
    return clamp(1 - (Float32(c.r) + Float32(c.g) + Float32(c.b)) / 3, 0, 1)
end

function spacing_overlay_image(after_path, before_path)
    after_img = load(after_path)
    before_img = load(before_path)
    height = min(size(after_img, 1), size(before_img, 1))
    width = min(size(after_img, 2), size(before_img, 2))
    overlay = Matrix{RGBAf}(undef, height, width)

    for y in 1:height, x in 1:width
        after_dark = pixel_darkness(after_img[y, x])
        before_dark = pixel_darkness(before_img[y, x])

        # Blue ink is the current checkout, red ink is the baseline. Matching
        # ink becomes dark, while spacing changes leave visible colored fringes.
        overlay[y, x] =
            RGBAf(1 - after_dark, (1 - after_dark) * (1 - before_dark), 1 - before_dark, 1)
    end

    return overlay
end

function spacing_visual_figure()
    return with_baseline_checkout() do baseline_path, baseline_label
        mktempdir() do dir
            before_path = joinpath(dir, "spacing_before.png")
            after_path = joinpath(dir, "spacing_after.png")
            overlay_path = joinpath(dir, "spacing_overlay.png")

            render_spacing_sheet_in_subprocess(baseline_path, before_path)
            render_spacing_sheet_in_subprocess(repo_root(), after_path)
            save(overlay_path, spacing_overlay_image(after_path, before_path))

            fig = Figure(size = (3000, 1800), fontsize = 24)
            Label(
                fig[1, 1:3],
                "Spacing regression visual inspection";
                tellwidth = false,
                halign = :left,
                font = :bold,
            )
            add_image_panel!(fig[2, 1], before_path, "before: $(baseline_label)")
            add_image_panel!(fig[2, 2], after_path, "after: current checkout")
            add_image_panel!(fig[2, 3], overlay_path, "overlay: after blue, before red")
            colsize!(fig.layout, 1, Relative(0.34))
            colsize!(fig.layout, 2, Relative(0.34))
            colsize!(fig.layout, 3, Relative(0.32))
            return fig
        end
    end
end

function generate_spacing_visuals(path = spacing_visual_output_path())
    fig = spacing_visual_figure()
    mkpath(dirname(path))
    save(path, fig, px_per_unit = 2)
    return path
end

if abspath(PROGRAM_FILE) == @__FILE__
    path = generate_spacing_visuals()
    @info "Wrote spacing visual inspection sheet" path
end
