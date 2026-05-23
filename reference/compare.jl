using CairoMakie
using Colors
using FileIO
using MathTeXEngine
using Tar
using Test
using TOML

include("references.jl")

function download_refimages(tag = "refimages-v3")
    url = "https://github.com/Kolaru/MathTeXEngine.jl/releases/download/$tag/reference_images.tar"
    images_tar = joinpath(@__DIR__, "reference_images.tar")
    images = joinpath(@__DIR__, "reference_images")
    if isfile(images_tar)
        if Bool(parse(Int, get(ENV, "REUSE_IMAGES_TAR", "0")))
            @info "$images_tar already exists, skipping download as requested"
        else
            rm(images_tar)
        end
    end
    !isfile(images_tar) && download(url, images_tar)
    isdir(images) && rm(images, recursive = true, force = true)
    Tar.extract(images_tar, images)
    return images
end

function image_paths(references)
    paths = String[]
    for (group, data) in references
        if data isa AbstractDict
            append!(paths, joinpath.(Ref(group), image_paths(data)))
        else
            push!(paths, "$group.png")
        end
    end

    return paths
end

n_bad_pixels(img1, img2) = count(>(0.5), image_difference(img1, img2))
image_difference(img1, img2) = colordiff.(img1, img2) ./ 100

@testset "Reference images" begin
    @info "Reference test started"

    @info "Downloading reference images"
    reference_images = download_refimages()
    @info "Reference images downloaded in $reference_images"
    
    @info "Generating comparison images"
    comparison_images = joinpath(@__DIR__, "comparison_images")
    rm(comparison_images, recursive = true, force = true)
    generate(comparison_images)
    @info "Comparison images generated in $comparison_images"
    
    # Compare
    reference_comparison_images = joinpath(@__DIR__, "reference_comparison_images")
    rm(reference_comparison_images, recursive = true, force = true)
    path = mkpath(reference_comparison_images)

    @info "Comparing images"
    for image_path in image_paths(REFERENCES)
        @info "Comparing $image_path"

        refimg = rotr90(load(joinpath(reference_images, image_path)))
        img = rotr90(load(joinpath(comparison_images, image_path)))

        if (failed = n_bad_pixels(img, refimg) >= 10)
            @info "Saving the reference comparison for '$image_path' (image difference $(n_bad_pixels(img, refimg)))"
            fig = Figure(size = (3*size(img, 1), size(img, 2)))
            Label(fig[1, 1], "Reference $(size(refimg))", tellwidth=false)
            axref = Axis(fig[2, 1], aspect = DataAspect())
            hidedecorations!(axref)
            image!(axref, refimg)

            Label(fig[1, 2], "Current $(size(img))", tellwidth=false)
            axcurrent = Axis(fig[2, 2], aspect = DataAspect())
            hidedecorations!(axcurrent)
            image!(axcurrent, img)

            if size(img) == size(refimg)
                Label(fig[1, 3], "Difference ($(n_bad_pixels(img, refimg)) bad pixels). Blue: reference. Orange: current.", tellwidth=false)
                axdiff = Axis(fig[2, 3], aspect = DataAspect())
                hidedecorations!(axdiff)
                diff = Gray.(img) - Gray.(refimg)
                overlay = RGB.(Gray.(refimg), Gray.(img)./2 .+ Gray.(refimg)./2, Gray.(img))

                image!(axdiff, overlay)
            end

            comparison_path = joinpath(path, image_path)
            mkpath(dirname(comparison_path))
            @info "Saving the reference plot at $comparison_path"
            save(comparison_path, fig)
        end
        @test !failed
    end
end
