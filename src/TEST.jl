include("RayTracing.jl")

@info "Reading data\n"

l_2_w = RayTracing.Translate(RayTracing.Pnt3(0,0,0,))
b = RayTracing.Bounds3(RayTracing.Pnt3(-5, -5, -5), RayTracing.Pnt3(5, 5, 5))
light = RayTracing.InfiniteLight(b, l_2_w, RayTracing.Spectrum(2.0, 2.0, 2.0), "/Users/johnmyslinski/Documents/PBRJ/scratch/mipmap/hello.exr")