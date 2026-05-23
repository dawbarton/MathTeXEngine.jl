using CairoMakie
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

        refimg = load(joinpath(reference_images, image_path))
        img = load(joinpath(comparison_images, image_path))

        if img != refimg
            @info "Saving the reference comparison for '$image_path'."
            fig = Figure()
            fig[1, 1] = Label(fig, "Reference", tellwidth=false)
            axref = fig[2, 1] = Axis(fig, aspect=DataAspect())
            image!(axref, rotr90(refimg))

            fig[1, 2] = Label(fig, "Current", tellwidth=false)
            axcurrent = fig[2, 2] = Axis(fig, aspect=DataAspect())
            image!(axcurrent, rotr90(img))

            comparison_path = joinpath(path, image_path)
            mkpath(dirname(comparison_path))
            save(comparison_path, fig)
        end
        @test img == refimg
    end
end
