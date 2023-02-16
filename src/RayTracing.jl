module RayTracing

using StaticArrays
using LinearAlgebra
using FileIO
using Images
using Statistics
using ProgressMeter
using Random
using ArgParse

abstract type Aggregate end
abstract type AbstractBxDF end
abstract type AbstractBSDF end
abstract type AbstractLightDistribution end
abstract type AbstractRay end
abstract type BVHAccel end
abstract type Camera end
abstract type Filter end
abstract type Fresnel end
abstract type AbstractIntegrator end
abstract type Light end
abstract type Material end
abstract type Medium end
abstract type AbstractSampler end
abstract type Shape end
abstract type Texture end
abstract type MicrofacetDistribution end

const Radiance = Val{:Radiance}
const Importance = Val{:Importance}
const TransportMode = Union{Radiance, Importance}

include("objects.jl")
include("primitive.jl")
include("interactions.jl")
include("transformations.jl")
include("shapes/shape.jl")
include("shapes/sphere.jl")
include("shapes/triangle.jl")
include("shapes/rectangles.jl")
include("shapes/disk.jl")
include("shapes/cylindar.jl")
include("shapes/box.jl")
include("math_utils.jl")
include("rand_utils.jl")
include("accelerators/bvh_naive.jl")
include("accelerators/bvh_pbr_pxlth.jl")
include("filters/box.jl")
include("filters/lanczos_sinc.jl")
include("film.jl")
include("distributions.jl")
include("cameras/camera.jl")
include("cameras/projective.jl")
include("samplers/sampler.jl")
include("samplers/random.jl")
include("samplers/stratified.jl")
include("samplers/halton.jl")
include("samplers/primes.jl")
include("reflection/flags.jl")
include("reflection/math.jl")
include("reflection/fresnel.jl")
include("reflection/specular.jl")
include("reflection/lambertian.jl")
include("reflection/oren_nayar.jl")
include("reflection/microfacet_distributions.jl")
include("reflection/microfacet.jl")
include("reflection/bxdf.jl")
include("materials/bsdf.jl")
include("materials/matte.jl")
include("materials/plastic.jl")
include("materials/mirror.jl")
include("materials/substrate.jl")
include("textures/constant.jl")
include("textures/image.jl")
include("textures/procedural.jl")
include("textures/mix.jl")
include("textures/noise.jl")
include("lights/light.jl")
include("lights/visibility.jl")
include("lights/area.jl")
include("lights/point.jl")
include("lights/infinite.jl")
include("lights/distant.jl")
include("scene.jl")
include("light_distributions.jl")
include("integrators/whitted.jl")
include("integrators/path.jl")
include("integrators/integrator.jl")
include("integrators/bdpt_vertex.jl")
include("cameras/projective_sampling.jl")
include("integrators/bdpt.jl")
include("integrators/bdpt_utils.jl")
include("handy_prints.jl")
include("obj_reader.jl")
include("args.jl")
include("scene_builder.jl")
include("denoising/edge_avoiding_a_trous.jl")

const PASSDICT = Dict{UInt8, String}(UInt(0) => "full pass", UInt(1) => "albedo pass", UInt(2) => "depth pass", UInt(3) => "normal pass")

function render_scene()
    parsed_args = parse_commandline()

    I, scene = build_scene(parsed_args)

    
    x,y = I.camera.core.core.film.full_resolution
    passes = zeros(Int(x), Int(y), 3, 4)
    for render_pass_flag in [UInt8(0), UInt8(1), UInt8(2), UInt8(3)]
        current_pass = render(
            I, 
            scene, 
            render_pass_flag,
            parsed_args["light-distribution-strategy"], 
        )
        passes[:, :, :, render_pass_flag+1] = current_pass
    end
    image = denoise(passes, 10)
    FileIO.save("yeehaw_denoise.png", image[end:-1:begin, :, :])
end

if abspath(PROGRAM_FILE) == @__FILE__
    @time render_scene()
end

end