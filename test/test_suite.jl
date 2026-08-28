include("../src/RayTracing.jl")

using Printf, Dates

const RESULTS_FILE = joinpath(@__DIR__, "test_suite_results.txt")
const RENDER_DIR = joinpath(@__DIR__, "benchmark_renders")

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
    # SceneBenchmark(1, "indoor_office"),
    # SceneBenchmark(2, "caustic_glass"),
    # SceneBenchmark(3, "ao_dragon"),
    SceneBenchmark(4, "cornell_box"; extra_args=Dict{String,Any}("integrator" => "volpath")),
    # SceneBenchmark(5, "soft_bodies"),
    # SceneBenchmark(6, "goursat"),
    # SceneBenchmark(7, "julia_logo_teapots"),
    # SceneBenchmark(9, "lte_orb"),
    # SceneBenchmark(10, "cloud_v3_grid_medium"),
    # SceneBenchmark(11, "dragon_fun_materials"),
    # SceneBenchmark(12, "smoke_plume_v4_grid_medium"),
    # SceneBenchmark(100, "furry_bunny"),
    # SceneBenchmark(102, "party_blob"),
    # SceneBenchmark(105, "his_name_is_doug"),
    # SceneBenchmark(106, "fleshy_dragon"),
]

resolve_dims_spp(scene::SceneBenchmark, default_dims::Vector{Int}, default_spp::Int) =
    (isempty(scene.dims) ? default_dims : scene.dims, scene.spp == -1 ? default_spp : scene.spp)

function build_args(scene::SceneBenchmark, dims::Vector{Int}, spp::Int, seed::Int)
    parsed_args = RayTracing.parse_commandline()
    parsed_args["scene-number"] = scene.number
    parsed_args["image-dim"] = copy(dims)
    parsed_args["samples-per-pixel"] = spp
    parsed_args["seed"] = seed
    parsed_args["file-name"] = joinpath(RENDER_DIR, "$(scene.number)-$(scene.name).exr")
    for (k, v) in scene.extra_args
        parsed_args[k] = v
    end
    return parsed_args
end

function run_scene_benchmark(scene::SceneBenchmark, dims::Vector{Int}, spp::Int, seed::Int)
    parsed_args = build_args(scene, dims, spp, seed)
    RayTracing.Random.seed!(seed)
    stats = @timed RayTracing.render_scene(parsed_args)
    gc_pct = stats.time > 0 ? stats.gctime / stats.time * 100 : 0.0
    return (scene=scene, dims=dims, spp=spp, time_s=stats.time, bytes=stats.bytes,
            gctime_s=stats.gctime, gc_pct=gc_pct, error=nothing)
end

function failed_result(scene::SceneBenchmark, dims::Vector{Int}, spp::Int, e)
    return (scene=scene, dims=dims, spp=spp, time_s=NaN, bytes=NaN,
            gctime_s=NaN, gc_pct=NaN, error=sprint(showerror, e))
end

"""
Renders each scene in `suite` once and records wall-clock time and memory
allocation (via `@timed`, covering scene build + render + save) to `output`.
"""
function run_test_suite(; suite=DEFAULT_SUITE, dims=[64, 64], spp=4, seed=1234,
                         warmup=true, output=RESULTS_FILE)
    mkpath(RENDER_DIR)
    RayTracing.global_logger(RayTracing.setup_logging(false))

    if warmup
        println("Warming up (JIT compile)...")
        try
            run_scene_benchmark(suite[1], [8, 8], 1, seed)
        catch e
            @warn "Warmup failed, continuing anyway" exception = e
        end
    end

    results = []
    for scene in suite
        scene_dims, scene_spp = resolve_dims_spp(scene, dims, spp)
        println("Running scene $(scene.number): $(scene.name)...")
        try
            r = run_scene_benchmark(scene, scene_dims, scene_spp, seed)
            push!(results, r)
            @printf("  time=%.3fs  alloc=%.2f MiB  gc=%.1f%%\n", r.time_s, r.bytes / 2^20, r.gc_pct)
        catch e
            @warn "Scene $(scene.number) ($(scene.name)) failed" exception = (e, catch_backtrace())
            push!(results, failed_result(scene, scene_dims, scene_spp, e))
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
        @printf(io, "%-5s %-28s %-10s %6s %10s %12s %8s\n",
                "Scn", "Name", "Dims", "SPP", "Time(s)", "Alloc(MiB)", "GC%")
        println(io, "-"^90)

        for r in results
            dims_str = "$(r.dims[1])x$(r.dims[2])"
            if r.error === nothing
                @printf(io, "%-5d %-28s %-10s %6d %10.3f %12.2f %8.1f\n",
                        r.scene.number, r.scene.name, dims_str, r.spp, r.time_s, r.bytes / 2^20, r.gc_pct)
            else
                @printf(io, "%-5d %-28s %-10s %6d %10s\n",
                        r.scene.number, r.scene.name, dims_str, r.spp, "FAILED")
            end
        end
        println(io, "-"^90)

        ok = filter(r -> r.error === nothing, results)
        if !isempty(ok)
            total_time = sum(r.time_s for r in ok)
            total_alloc = sum(r.bytes for r in ok)
            @printf(io, "%-56s %10.3f %12.2f\n", "TOTAL ($(length(ok))/$(length(results)) succeeded)", total_time, total_alloc / 2^20)
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
    run_test_suite()
end
