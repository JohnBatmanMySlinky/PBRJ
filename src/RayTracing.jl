module RayTracing

using StaticArrays
using LinearAlgebra
using FileIO
using Images
using Statistics
using ProgressMeter
using Random
using ArgParse
using Logging
using Dates
using OpenEXR

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
include("samplers2/stratified.jl")
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
include("materials/glass.jl")
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
include("integrators/ao.jl")
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

const PASSDICT = Dict{UInt8, String}(
    UInt(0) => "full pass",
    UInt(1) => "albedo pass",
    UInt(2) => "depth pass",
    UInt(3) => "normal pass",
    UInt(4) => "position pass",
)

# do MIS_weight or nah
const DO_MIS_WEIGHT = true

# specify (s,t) combinations to save off intermediate stages. 
# (-1,-1) should result in a normal full render
const BDPT_STAGES = [
    (-1,-1),
    # (0,2),

    # (0,3),
    # (1,2),
    # (2,1),

    # (0,4),
    # (1,3),
    # (2,2),
    # (3,1),
    
    # (0,5),
    # (1,4),
    # (2,3),
    # (3,2),
    # (4,1),

    # (0,6),
    # (1,5),
    # (2,4),
    # (3,3),
    # (4,2),
    # (5,1)
]

function render_scene()
    parsed_args = parse_commandline()

    if parsed_args["denoise"] == true
        passes = Vector{Array{Float64}}(undef, 5)
        for (i,render_pass_flag) in enumerate([UInt8(0), UInt8(1), UInt8(2), UInt8(3), UInt8(4)])
            I, scene = build_scene(parsed_args) # TODO get this outside the loop!
            current_pass = render(
                I, 
                scene, 
                render_pass_flag,
                parsed_args["light-distribution-strategy"], 
            )
            passes[i] = current_pass
            # FileIO.save("debug_$(i).png", clamp01nan.(current_pass)
        end
        image = denoise(passes, parsed_args["denoise-steps"])
        FileIO.save(I.camera.core.core.film.filename, image)
    elseif parsed_args["denoise"] == false
        for bdpt_pass in BDPT_STAGES
            (bdpt_pass != (-1,-1)) && (print("working on bdpt pass s=$(bdpt_pass[1]), t=$(bdpt_pass[2])\n"))
            I, scene = build_scene(parsed_args) # TODO get this outside the loop!
            image = render(
                I, 
                scene, 
                UInt8(0), # full pass
                bdpt_pass,
                parsed_args["light-distribution-strategy"], 
            )
            image = clamp01nan.(image)
            if bdpt_pass == (-1,-1)
                FileIO.save(I.camera.core.core.film.filename, image)
            else
                FileIO.save(replace(I.camera.core.core.film.filename, ".png"=>"")*"_s_"*string(bdpt_pass[1])*"_t_"*string(bdpt_pass[2])*".png", image)
            end
        end
    else
        @assert false
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    # set up logging
    if Sys.iswindows()
        logger = NullLogger()   # TODO how to log to file on Windows?
        # logger = SimpleLogger()
    else
        logger = NullLogger()
        # io = open("log_$(now()).txt", "w+")
        # logger = SimpleLogger(io, Logging.Error) # Error, Warn, Info, Debug        
    end
    global_logger(logger)

    @time render_scene()
end

end