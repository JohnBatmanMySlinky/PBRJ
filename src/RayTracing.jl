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
using Printf
using Distributions
using Combinatorics
using Bumper
using Mmap
using GLMakie
using Colors

abstract type AbstractBSDF end
abstract type AbstractBSSRDF end
abstract type AbstractBxDF end
abstract type AbstractIntegrator end
abstract type AbstractLightDistribution end
abstract type AbstractMajorantIterator end
abstract type AbstractMedium end
abstract type AbstractPhaseFunction end
abstract type AbstractRay end
abstract type AbstractSampler end
abstract type AbstractTextureMapping2D end
abstract type BVHAccel end
abstract type Camera end
abstract type Filter end
abstract type Fresnel end
abstract type Light end
abstract type Material end
abstract type Medium end
abstract type Randomizer end
abstract type Shape end

abstract type ImplicitSurface <: Shape end

abstract type SDFOperation <: ImplicitSurface end
abstract type SDFPrimitive <: ImplicitSurface end


# Defining some global constants
const Radiance = Val{:Radiance}
const Importance = Val{:Importance}
const TransportMode = Union{Radiance, Importance}

const Reflectance = Val{:Reflectance}
const Illuminant = Val{:Illuminant}
const SpectrumType = Union{Reflectance, Illuminant}

const ShadowEpsilon::Float64 = 0.00001

######### Profiling ##############

const P_ON = "--profile-output" in ARGS
const P = P_ON ? Dict{String, Tuple{Int, Float64}}() : nothing
macro prof(n, e)
    P_ON ? quote
        Threads.nthreads() > 1 && error("@prof macro cannot be used with multiple threads (currently running with $(Threads.nthreads()) threads)")

        t = time_ns()
        r = $(esc(e))
        elapsed = (time_ns() - t) / 1e6
        count, total = Base.get($P, $n, (0, 0.0))
        $P[$n] = (count + 1, total + elapsed)
        r
    end : esc(e)
end

############## Imports #################

include("materials/fourier_bsdf_table.jl")
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

abstract type AbstractTexture{T <: Union{Float64, Spectrum}} end


include("mip_map.jl")
include("parsers/parse_media.jl")
include("medium2/common1.jl")
include("medium2/common2.jl")
include("medium2/sampled_grid.jl")
include("medium2/majorant_iterators.jl")
include("medium2/homogenous_medium.jl")
include("ray.jl")
include("primitive.jl")
include("interactions.jl")
include("medium2/common3.jl")
include("medium2/common4.jl")
include("textures/texture_mappings.jl")
include("image_utils.jl")
include("transformations.jl")
include("medium2/grid_medium.jl")
include("medium2/nanovdb.jl")
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
include("shapes/sdfs/sdf_concrete.jl")
include("accelerators/bvh_naive.jl")
include("accelerators/bvh_pbr_pxlth.jl")
include("shapes/implicit_surfaces/utils.jl")
include("shapes/implicit_surfaces/goursat.jl")
include("shapes/implicit_surfaces/metaballs_bvh.jl")
include("shapes/implicit_surfaces/metaballs_naive.jl")
include("filters/box.jl")
include("filters/guassian.jl")
include("filters/lanczos_sinc.jl")
include("filters/mitchell.jl")
include("filters/triangle.jl")
include("film.jl")
include("pass_film.jl")
include("distributions.jl")
include("cameras/camera.jl")
include("cameras/projective.jl")
include("samplers2/stratified.jl")
include("samplers2/independent.jl")
include("samplers2/low_discrepancy.jl")
include("samplers2/randomizers.jl")
include("samplers2/sobol.jl")
include("samplers2/zsobol.jl")
include("samplers2/dumb.jl")
include("samplers2/deterministic.jl")
include("samplers2/sampling.jl")
include("samplers2/sampler.jl")
include("reflection/flags.jl")
include("reflection/math.jl")
include("reflection/microfacet_distributions.jl")
include("reflection/fresnel.jl")
include("reflection/specular.jl")
include("reflection/lambertian.jl")
include("reflection/oren_nayar.jl")
include("reflection/microfacet.jl")
include("reflection/bxdf.jl")
include("reflection/hair.jl")
include("reflection/fourier.jl")
include("reflection/bssrdf.jl")
include("materials/registry.jl")
const MATERIAL_REGISTRY = Ref{MaterialRegistry}()

include("materials/bsdf.jl")
include("materials/bump.jl")
include("materials/matte.jl")
include("materials/plastic.jl")
include("materials/mirror.jl")
include("materials/substrate.jl")
include("materials/glass.jl")
include("materials/metal.jl")
include("materials/hair.jl")
include("materials/uber.jl")
include("materials/fourier.jl")
include("materials/kdsubsurface.jl")
include("materials/measured_subsurface.jl")
include("textures/constant.jl")
include("textures/image.jl")
include("textures/procedural.jl")
include("textures/mix.jl")
include("textures/noise.jl")
include("textures/uv.jl")
include("textures/registry.jl")
const ALPHA_TEXTURE_REGISTRY = Ref{AlphaTextureRegistry}()

include("lights/light.jl")
include("lights/visibility.jl")
include("lights/area.jl")
include("lights/point.jl")
include("lights/image_infinite.jl")
include("lights/uniform_infinite.jl")
include("lights/distant.jl")
include("lights/spot.jl")
include("lights/particle_emitter.jl")
include("scene.jl")
include("reflection/bssrdf2.jl")
include("light_distributions.jl")
include("integrators/ao.jl")
include("integrators/simple.jl")
include("integrators/simple_vol_path_v4.jl")
include("integrators/vol_path_v3.jl")
include("integrators/sppm.jl")
include("integrators/render_viz.jl")
include("integrators/integrator.jl")
include("integrators/bdpt_vertex.jl")
include("cameras/projective_sampling.jl")
include("integrators/bdpt.jl")
include("integrators/bdpt_utils.jl")
include("handy_prints.jl")
include("parsers/parse_obj.jl")
include("parsers/parse_obj_3dsmax_2011.jl")
include("parsers/parse_curves.jl")
include("medium2/cloud_medium.jl")
include("shapes/curve.jl")
include("scenes/scene1.jl")
include("scenes/scene2.jl")
include("scenes/scene3.jl")
include("scenes/scene4.jl")
include("scenes/scene5.jl")
include("scenes/scene6.jl")
include("scenes/scene7.jl")
include("scenes/scene8.jl")
include("scenes/scene9.jl")
include("scenes/scene10.jl")
include("scenes/scene11.jl")
include("scenes/scene12.jl")
include("scenes/scene13.jl")
include("scenes/scene14.jl")
include("scenes/scene15.jl")
include("scenes/scene16.jl")
include("scenes/scene17.jl")
include("scenes/scene18.jl")
include("scenes/scene19.jl")
include("scenes/scene20.jl")
include("scenes/scene21.jl")
include("scenes/scene22.jl")
include("scenes/scene23.jl")
include("scenes/scene99.jl")
include("scenes/scene100.jl")
include("scenes/scene101.jl")
include("scenes/scene102.jl")
include("scenes/scene103.jl")
include("scenes/scene104.jl")
include("scenes/scene105.jl")
include("scenes/scene106.jl")
include("scenes/scene107.jl")
include("scenes/scene108.jl")
include("scenes/scene109.jl")
include("scenes/scene110.jl")
include("scenes/scene111.jl")
include("scenes/scene112.jl")
include("scenes/scene113.jl")
include("scenes/scene_builder.jl")
include("denoising/edge_avoiding_a_trous.jl")
include("medium2/phase_functions.jl")
include("shapes/sphere_packing.jl")
include("shapes/voxelization.jl")
include("scene_utils.jl")

const NO_MEDIUM_INTERFACE = MediumInterface(nothing)

function render_scene(parsed_args::Dict)
    @prof "scene_build" I, scene = build_scene(parsed_args) # TODO get this outside the loop!
    if parsed_args["render-viz"]
        image = render_viz(I, scene, parsed_args)
    else
        image = render(I, scene, parsed_args)
    end
    if I.camera.core.core.film isa PassFilm
        for i in 1:5
            OpenEXR.save(replace(I.camera.core.core.film.filename, ".exr"=>"")*"_"*string(i)*".exr", image[i, :, :, :])
        end
        
        image = denoise(image, 1)
    end
    
    # gamma correct out
    image = map(v -> gamma_correct(v), image)

    # save
    OpenEXR.save(I.camera.core.core.film.filename, image)
end

function write_profiling(parsed_args, time_stats=nothing)
    if P_ON
        open(parsed_args["profile-output"], "w") do io
            # Headers
            println(io, "="^70)
            println(io, "PBRJ Performance Profile")
            println(io, "="^70)
            println(io)
            
            # Scene info
            spp = parsed_args["samples-per-pixel"]
            dims = parsed_args["image-dim"]
            total_pixels = dims[1] * dims[2]
            total_samples = total_pixels * spp
            println(io, "Image: $(dims[1])×$(dims[2]) pixels, $spp samples/pixel")
            println(io, "Total samples: $total_samples")
            println(io)
            
            println(io, "Function                     Calls    Total(ms)   Avg(ms)  Calls/sample")
            println(io, "-"^75)
            
            # Data rows
            for (name, (count, total)) in sort!(collect(P), by=x->x[2][2], rev=true)
                calls_per_sample = count / total_samples
                @printf(io, "%-25s %10d  %10.2f  %8.4f    %10.4f\n", 
                        name, count, total, total/count, calls_per_sample)
            end
            
            # Footer with summary
            println(io, "-"^75)
            total_ms = sum(x -> x[2], values(P))
            total_calls = sum(x -> x[1], values(P))
            avg_calls_per_sample = total_calls / total_samples
            @printf(io, "%-25s %10d  %10.2f              %10.4f\n", 
                    "TOTAL", total_calls, total_ms, avg_calls_per_sample)
            
            # Add @time stats if available
            if time_stats !== nothing
                println(io)
                println(io, "="^70)
                println(io, "Overall Render Statistics (@time)")
                println(io, "-"^70)
                @printf(io, "Total time:        %.3f seconds\n", time_stats.time)
                @printf(io, "Memory allocated:  %.2f MiB\n", time_stats.bytes / 2^20)
                @printf(io, "GC time:           %.1f%% (%.3f seconds)\n", 
                        time_stats.gctime/time_stats.time*100, time_stats.gctime)
                
                # Compare profiled vs actual time
                profiled_time = total_ms / 1000  # Convert to seconds
                @printf(io, "Profiled time:     %.3f seconds (%.1f%% of total)\n", 
                        profiled_time, profiled_time/time_stats.time*100)
                @printf(io, "Unprofiled time:   %.3f seconds (%.1f%%)\n", 
                        time_stats.time - profiled_time, 
                        (time_stats.time - profiled_time)/time_stats.time*100)
            end
        end
        
        println("Profile saved to $(parsed_args["profile-output"])")
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

    # render
    stats = @timed render_scene(parsed_args)

    # write profiling results
    write_profiling(parsed_args, stats)
end

end
