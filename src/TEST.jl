include("RayTracing.jl")

@info "Reading data\n"

io = open("log_$(RayTracing.now()).txt", "w+")
logger = RayTracing.SimpleLogger(io, RayTracing.Logging.Debug) # Error, Warn, Info, Debug        
RayTracing.global_logger(logger)

l_2_w = RayTracing.Translate(RayTracing.Pnt3(0,0,0,))
b = RayTracing.Bounds3(RayTracing.Pnt3(-5, -5, -5), RayTracing.Pnt3(5, 5, 5))
light = RayTracing.InfiniteLight(b, l_2_w, RayTracing.Spectrum(3.0, 3.0, 3.0), "/home/jmyslinski/random_stuff/PBRJ/scratch/mipmap/hello.exr")