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
using Roots
using IterTools

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
abstract type ImplicitSurface <: Shape end
abstract type Texture end
abstract type MicrofacetDistribution end
abstract type Randomizer end
abstract type AbstractMedium end
abstract type AbstractPhaseFunction end
abstract type AbstractTextureMapping2D end

# Defining some global constants
const Radiance = Val{:Radiance}
const Importance = Val{:Importance}
const TransportMode = Union{Radiance, Importance}

const Reflectance = Val{:Reflectance}
const Illuminant = Val{:Illuminant}
const SpectrumType = Union{Reflectance, Illuminant}

const ShadowEpsilon::Float64 = 0.00001

include("utils.jl")
include("nanovdb/julia_part.jl")
include("primes.jl")
include("samplers2/sobol_matrics.jl")
include("objects.jl")
include("args.jl")
include("math_utils.jl")

########################
### SPECTRUM HACKING ###
########################
include("spectrum/spectrum_constants.jl")   # constants for spectral <-> RGB <-> XYZ
include("spectrum/spectrum_macro.jl")       # the file to create the macro
include("spectrum/spectrum.jl")             # all of the 'constructors'
tmp_parsed_args = parse_commandline() # ugh this is so messy TODO CELAN UP
const nSpectralSamples::Int64 = tmp_parsed_args["n-spectral-samples"]         # if it's 3 --> RGB if it's >3 --> spectral
const sampledLambdaStart::Int64 = 400
const sampledLambdaEnd::Int64 = 700
const nCIESamples::Int64 = 471
const CIE_Y_integral::Float64 = 106.856895
const nRGB2SpectSamples::Int64 = 32
@make_spectrum nSpectralSamples    # define the Spectrum struct
include("spectrum/spectrum_utils.jl")       # things that reference the Spectrum struct

# instantiate these at global level to be used for spectral 
const XXX::Spectrum, YYY::Spectrum, ZZZ::Spectrum, rgbRefl2SpectWhite::Spectrum, rgbRefl2SpectCyan::Spectrum, 
    rgbRefl2SpectMagenta::Spectrum, rgbRefl2SpectYellow::Spectrum, rgbRefl2SpectRed::Spectrum,
    rgbRefl2SpectGreen::Spectrum, rgbRefl2SpectBlue::Spectrum, rgbIllum2SpectWhite::Spectrum, 
    rgbIllum2SpectCyan::Spectrum, rgbIllum2SpectMagenta::Spectrum, rgbIllum2SpectYellow::Spectrum, 
    rgbIllum2SpectRed::Spectrum, rgbIllum2SpectGreen::Spectrum, rgbIllum2SpectBlue::Spectrum = make_spectral_constants()

include("mip_map.jl")
include("medium/media_parser.jl")
include("medium/media1.jl")
include("ray.jl")
include("primitive.jl")
include("interactions.jl")
include("textures/texture_mappings.jl")
include("image_utils.jl")
include("textures/texture.jl")
include("transformations.jl")
include("medium/media2.jl")
include("medium/media3.jl")
include("rand_utils.jl")
include("shapes/shape.jl")
include("shapes/sphere.jl")
include("shapes/basic_sphere.jl")
include("shapes/triangle.jl")
include("shapes/rectangles.jl")
include("shapes/disk.jl")
include("shapes/cylindar.jl")
include("shapes/box.jl")
include("shapes/lsystem.jl")
include("shapes/bilinear_patch.jl")
include("accelerators/bvh_naive.jl")
include("accelerators/bvh_pbr_pxlth.jl")
include("shapes/implicit_surfaces/utils.jl")
include("shapes/implicit_surfaces/goursat.jl")
include("shapes/implicit_surfaces/metaballs_bvh.jl")
include("shapes/implicit_surfaces/metaballs_naive.jl")
include("filters/box.jl")
include("filters/lanczos_sinc.jl")
include("film.jl")
include("distributions.jl")
include("cameras/camera.jl")
include("cameras/projective.jl")
include("samplers2/stratified.jl")
include("samplers2/independent.jl")
include("samplers2/low_discrepancy.jl")
include("samplers2/randomizers.jl")
include("samplers2/sobol.jl")
include("samplers2/zsobol.jl")
include("samplers2/sampling.jl")
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
include("materials/metal.jl")
include("textures/constant.jl")
include("textures/image.jl")
include("textures/procedural.jl")
include("textures/mix.jl")
include("textures/noise.jl")
include("lights/light.jl")
include("lights/visibility.jl")
include("lights/area.jl")
include("lights/point.jl")
include("lights/image_infinite.jl")
include("lights/uniform_infinite.jl")
include("lights/distant.jl")
include("lights/spot.jl")
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
include("parsers/parse_obj.jl")
include("parsers/parse_curves.jl")
include("shapes/curve.jl")
include("scene_builder.jl")
include("denoising/edge_avoiding_a_trous.jl")
include("medium/media_funcs.jl")
include("medium/phase_functions.jl")
include("scene_utils.jl")

# do MIS_weight or nah
const DO_MIS_WEIGHT::Bool = true

# specify (s,t) combinations to save off intermediate stages. 
# (-1,-1) should result in a normal full render
const BDPT_STAGES::Vector{Tuple{Int64, Int64}} = [
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

function render_scene(parsed_args::Dict)
    for bdpt_pass in BDPT_STAGES
        (bdpt_pass != (-1,-1)) && (print("working on bdpt pass s=$(bdpt_pass[1]), t=$(bdpt_pass[2])\n"))
        I, scene = build_scene(parsed_args) # TODO get this outside the loop!
        image = render(
            I, 
            scene, 
            parsed_args,
            bdpt_pass
        )
        if I.camera.core.core.film isa PassFilm
            for i in 1:5
                OpenEXR.save(replace(I.camera.core.core.film.filename, ".exr"=>"")*"_"*string(i)*".exr", image[i, :, :, :])
            end
            
            image = denoise(image, 1)
        end
        
        if bdpt_pass == (-1,-1)
            OpenEXR.save(I.camera.core.core.film.filename, image)
        else
            OpenEXR.save(replace(I.camera.core.core.film.filename, ".exr"=>"")*"_s_"*string(bdpt_pass[1])*"_t_"*string(bdpt_pass[2])*".exr", image)
        end
    end
end

function setup_logging(debug::Bool)
    if Sys.iswindows()
        if debug
            io = open("windows_log_softy.txt", "w+")
            logger = SimpleLogger(io, Logging.Info) # Error, Warn, Info, Debug        
        else
            logger = NullLogger()
        end
    else
        if debug
            io = open("log_$(now()).txt", "w+")
            logger = SimpleLogger(io, Logging.Debug) # Error, Warn, Info, Debug        
        else
            logger = NullLogger()
        end
    end
    return logger
end

if abspath(PROGRAM_FILE) == @__FILE__
    # parse args
    parsed_args = parse_commandline()
    
    # set up logging
    logger = setup_logging(parsed_args["debug"])
    global_logger(logger)

    # set random seed
    Random.seed!(parsed_args["seed"])

    @time render_scene(parsed_args)
end

end
