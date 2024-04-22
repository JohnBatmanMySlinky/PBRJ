include("RayTracing.jl")

@info "Reading data\n"

function get_data()::Vector{RayTracing.Spectrum}
    raw = RayTracing.OpenEXR.load("/Users/johnmyslinski/Documents/PBRJ/scratch/mipmap/hello.exr")
    L, W = size(raw)
    data = zeros(RayTracing.Spectrum, L * W)
    i = 0
    for l in 1:L
        for w in 1:W
            i += 1
            c = raw[l,w]
            data[i] = RayTracing.Spectrum(c.r, c.g, c.b) * 3.0
        end
    end
    return data
end

data = get_data()

# RayTracing.MIPMap(
#     RayTracing.Pnt2(7,9), 
#     data, 
#     false, 
#     8.0, 
#     Int8(1)
# )


immy_t = ImageTexture(
    mapping::AbstractTextureMapping2D, 
    filename::String,
    do_trilinear::Bool,
    max_anisotropy::Float64,
    wrap_mode::Int8,
    scale::Float64,
    do_gamma::Bool
)
