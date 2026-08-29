# Pull --run-name out of ARGS *before* including RayTracing.jl, since that
# include triggers RayTracing's own ArgParse-based parse_commandline() against
# the global ARGS, which would choke on a flag it doesn't know about.
function extract_flag!(args::Vector{String}, flag::String)
    idx = findfirst(==(flag), args)
    idx === nothing && return nothing
    idx == length(args) && error("$flag requires a value")
    value = args[idx + 1]
    deleteat!(args, idx:idx + 1)
    return value
end

const _run_name_from_args = extract_flag!(ARGS, "--run-name")

include("../src/RayTracing.jl")

using Printf, Dates

# Set per call in run_test_suite (depends on run_name); placeholder until then.
RENDER_DIR = joinpath(@__DIR__, "benchmark_renders")

struct SceneBenchmark
    number::Int
    name::String
    dims::Vector{Int}   # per-scene override; falls back to suite default when unset (nothing)
    spp::Int
    extra_args::Dict{String,Any}   # any other parsed_args overrides, e.g. Dict("max-depth"=>30)
end

# Convenience constructor: dims/spp default to `nothing`/`-1` sentinels meaning
# "use the suite-level default passed to run_test_suite".
SceneBenchmark(number, name; dims=nothing, spp=-1, extra_args=Dict{String,Any}()) =
    SceneBenchmark(number, name, dims === nothing ? Int[] : dims, spp, extra_args)

# Scenes marked ✅ in scene_builder.jl. Broken/WIP (🟨/🔴) scenes are left out
# by default since they're expected to fail or produce garbage.
# Tune dims/spp/extra_args per scene here as needed (e.g. volumetric scenes
# often want higher spp, heavy-mesh scenes want smaller dims to stay fast).
const DEFAULT_SUITE = [
    SceneBenchmark(4, "cornell_box"; extra_args=Dict(
        "integrator" => "volpath", 
        "image-dim" => [500, 500], 
        "samples-per-pixel" => 32
    )),
    SceneBenchmark(4, "cornell_box"; extra_args=Dict(
        "integrator" => "bdpt", 
        "image-dim" => [500, 500], 
        "samples-per-pixel" => 16
    )),
    SceneBenchmark(4, "cornell_box"; extra_args=Dict(
        "integrator" => "sppm", 
        "image-dim" => [500, 500]
    )),
    SceneBenchmark(10, "plume"; extra_args=Dict(
        "integrator" => "volpath", 
        "image-dim" => [500, 500], 
        "samples-per-pixel" => 8
    )),
    SceneBenchmark(12, "smoke_plume"; extra_args=Dict(
        "integrator" => "volpath", 
        "image-dim" => [500, 500], 
        "samples-per-pixel" => 2
    )),
    SceneBenchmark(13, "disney_cloud"; extra_args=Dict(
        "integrator" => "volpath", 
        "image-dim" => [500, 500], 
        "samples-per-pixel" => 2
    )),
    SceneBenchmark(17, "barcelona_pavillion"; extra_args=Dict(
        "integrator" => "volpath", 
        "image-dim" => [500, 500], 
        "samples-per-pixel" => 8
    )),
    SceneBenchmark(105, "doug"; extra_args=Dict(
        "integrator" => "volpath", 
        "image-dim" => [500, 500], 
        "samples-per-pixel" => 2
    )),
]

resolve_dims_spp(scene::SceneBenchmark, default_dims::Vector{Int}, default_spp::Int) =
    (isempty(scene.dims) ? default_dims : scene.dims, scene.spp == -1 ? default_spp : scene.spp)

# Builds a filesystem-safe, deterministic suffix from a scene's extra_args so
# that e.g. running the same scene number twice with different integrators
# doesn't have one render silently overwrite the other's .exr.
function args_suffix(extra_args::Dict{String,Any})
    isempty(extra_args) && return ""
    parts = String[]
    for k in sort(collect(keys(extra_args)))
        v = extra_args[k]
        vstr = v isa AbstractVector ? join(v, "x") : string(v)
        vstr = replace(vstr, "/" => "-", " " => "-")
        push!(parts, "$(k)-$(vstr)")
    end
    return "_" * join(parts, "_")
end

function build_args(scene::SceneBenchmark, dims::Vector{Int}, spp::Int, seed::Int)
    parsed_args = RayTracing.parse_commandline()
    parsed_args["scene-number"] = scene.number
    parsed_args["image-dim"] = copy(dims)
    parsed_args["samples-per-pixel"] = spp
    parsed_args["seed"] = seed
    for (k, v) in scene.extra_args
        parsed_args[k] = v
    end
    parsed_args["file-name"] = joinpath(RENDER_DIR, "$(scene.number)-$(scene.name)$(args_suffix(scene.extra_args)).exr")
    return parsed_args
end

function run_scene_benchmark(parsed_args::Dict, scene::SceneBenchmark, dims::Vector{Int}, spp::Int, integrator::String, seed::Int)
    RayTracing.Random.seed!(seed)
    stats = @timed RayTracing.render_scene(parsed_args)
    gc_pct = stats.time > 0 ? stats.gctime / stats.time * 100 : 0.0
    return (scene=scene, dims=dims, spp=spp, integrator=integrator, time_s=stats.time, bytes=stats.bytes,
            gctime_s=stats.gctime, gc_pct=gc_pct, error=nothing)
end

function failed_result(scene::SceneBenchmark, dims::Vector{Int}, spp::Int, integrator::String, e)
    return (scene=scene, dims=dims, spp=spp, integrator=integrator, time_s=NaN, bytes=NaN,
            gctime_s=NaN, gc_pct=NaN, error=sprint(showerror, e))
end

"""
Renders each scene in `suite` once and records wall-clock time and memory
allocation (via `@timed`, covering scene build + render + save) to `output`.

`run_name` is required and namespaces both the results file
(`test_suite_results_<run_name>.txt`) and the rendered images
(`benchmark_renders/<run_name>/`), so separate runs never clobber each other.
"""
function run_test_suite(; run_name, suite=DEFAULT_SUITE, dims=[64, 64], spp=4, seed=1234,
                         warmup=true, output=nothing)
    run_name = replace(run_name, "/" => "-", " " => "_")
    global RENDER_DIR = joinpath(@__DIR__, "benchmark_renders", run_name)
    output = output === nothing ? joinpath(@__DIR__, "test_suite_results_$(run_name).txt") : output

    mkpath(RENDER_DIR)
    RayTracing.global_logger(RayTracing.setup_logging(false))

    if warmup
        println("Warming up (JIT compile)...")
        try
            warmup_args = build_args(suite[1], [8, 8], 1, seed)
            run_scene_benchmark(warmup_args, suite[1], warmup_args["image-dim"], warmup_args["samples-per-pixel"],
                                 warmup_args["integrator"], seed)
        catch e
            @warn "Warmup failed, continuing anyway" exception = e
        end
    end

    results = []
    for scene in suite
        scene_dims, scene_spp = resolve_dims_spp(scene, dims, spp)
        # extra_args may itself override image-dim/samples-per-pixel, so read
        # the effective values back off parsed_args rather than trusting
        # scene_dims/scene_spp directly — keeps the report honest.
        parsed_args = build_args(scene, scene_dims, scene_spp, seed)
        effective_dims = parsed_args["image-dim"]
        effective_spp = parsed_args["samples-per-pixel"]
        effective_integrator = parsed_args["integrator"]

        println("Running scene $(scene.number): $(scene.name) [$effective_integrator]...")
        try
            r = run_scene_benchmark(parsed_args, scene, effective_dims, effective_spp, effective_integrator, seed)
            push!(results, r)
            @printf("  time=%.3fs  alloc=%.2f MiB  gc=%.1f%%\n", r.time_s, r.bytes / 2^20, r.gc_pct)
        catch e
            @warn "Scene $(scene.number) ($(scene.name)) failed" exception = (e, catch_backtrace())
            push!(results, failed_result(scene, effective_dims, effective_spp, effective_integrator, e))
        end
    end

    write_results(results, output)
    println("\nResults written to $output")
    return results
end

function write_results(results, output)
    open(output, "w") do io
        println(io, "="^90)
        println(io, "PBRJ Test Suite Results — $(now())")
        println(io, "Threads: $(Threads.nthreads())   Julia: $(VERSION)   nSpectralSamples: $(RayTracing.nSpectralSamples)")
        println(io, "="^90)
        println(io)
        @printf(io, "%-5s %-28s %-10s %6s %-10s %10s %12s %8s\n",
                "Scn", "Name", "Dims", "SPP", "Integrator", "Time(s)", "Alloc(MiB)", "GC%")
        println(io, "-"^100)

        for r in results
            dims_str = "$(r.dims[1])x$(r.dims[2])"
            if r.error === nothing
                @printf(io, "%-5d %-28s %-10s %6d %-10s %10.3f %12.2f %8.1f\n",
                        r.scene.number, r.scene.name, dims_str, r.spp, r.integrator, r.time_s, r.bytes / 2^20, r.gc_pct)
            else
                @printf(io, "%-5d %-28s %-10s %6d %-10s %10s\n",
                        r.scene.number, r.scene.name, dims_str, r.spp, r.integrator, "FAILED")
            end
        end
        println(io, "-"^100)

        ok = filter(r -> r.error === nothing, results)
        if !isempty(ok)
            total_time = sum(r.time_s for r in ok)
            total_alloc = sum(r.bytes for r in ok)
            @printf(io, "%-64s %10.3f %12.2f\n", "TOTAL ($(length(ok))/$(length(results)) succeeded)", total_time, total_alloc / 2^20)
        end

        failed = filter(r -> r.error !== nothing, results)
        if !isempty(failed)
            println(io)
            println(io, "Failures:")
            for r in failed
                println(io, "  Scene $(r.scene.number) ($(r.scene.name)): $(r.error)")
            end
        end
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    _run_name_from_args === nothing && error("Usage: julia test/test_suite.jl --run-name <name>")
    run_test_suite(run_name=_run_name_from_args)
end
