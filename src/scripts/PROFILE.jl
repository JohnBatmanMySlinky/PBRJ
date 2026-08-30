include("../RayTracing.jl")

using BenchmarkTools, Profile, ProfileCanvas

# Set up
println("SET UP")
parsed_args = RayTracing.parse_commandline()
parsed_args["scene-number"] = 4
parsed_args["image-dim"] = Int[250, 250]
parsed_args["samples-per-pixel"] = 16
parsed_args["integrator"] = "volpath"
    
logger = RayTracing.setup_logging(parsed_args["debug"])
RayTracing.global_logger(logger)
RayTracing.Random.seed!(parsed_args["seed"])
I, scene = RayTracing.build_scene(parsed_args)

# run once for compile
println("Run once for compile")
image = RayTracing.render(
    I, 
    scene, 
    parsed_args
)

# reset
println("clear profile")
Profile.clear()

# collect
println("collecting")
@profile RayTracing.render(
    I, 
    scene, 
    parsed_args
)

# profile
println("Profiling")
ProfileCanvas.html_file("flamegraph.html")
println("Saved flamegraph.html")