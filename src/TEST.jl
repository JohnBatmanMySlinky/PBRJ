using StaticArrays
using OpenEXR
using Logging
using Dates

abstract type AbstractRay end

const Reflectance = Val{:Reflectance}
const Illuminant = Val{:Illuminant}
const SpectrumType = Union{Reflectance, Illuminant}


include("objects.jl")

########################
### SPECTRUM HACKING ###
########################
include("spectrum/spectrum_constants.jl")   # constants for spectral <-> RGB <-> XYZ
include("spectrum/spectrum_macro.jl")       # the file to create the macro
include("spectrum/spectrum.jl")             # all of the 'constructors'
# tmp_parsed_args = parse_commandline() # ugh this is so messy TODO CELAN UP
const nSpectralSamples::Int64 = 3         # if it's 3 --> RGB if it's >3 --> spectral
const sampledLambdaStart::Int64 = 400
const sampledLambdaEnd::Int64 = 700
const nCIESamples::Int64 = 471
const CIE_Y_integral::Float64 = 106.856895
const nRGB2SpectSamples::Int64 = 32
@make_spectrum nSpectralSamples    # define the Spectrum struct
include("spectrum/spectrum_utils.jl")       # things that reference the Spectrum struct

include("math_utils.jl")
include("mip_map.jl")

io = open("log_$(now()).txt", "w+")
logger = SimpleLogger(io, Logging.Debug) # Error, Warn, Info, Debug        
global_logger(logger)

@info "Reading data\n"

function get_data()::Vector{Spectrum}
    raw = OpenEXR.load("/Users/johnmyslinski/Documents/PBRJ/scratch/mipmap/hello.exr")
    L, W = size(raw)
    data = zeros(Spectrum, L * W)
    i = 0
    for l in 1:L
        for w in 1:W
            i += 1
            c = raw[l,w]
            data[i] = Spectrum(c.r, c.g, c.b) * 3.0
        end
    end
    return data
end

data = get_data()

MIPMap(
    Pnt2(7,9), 
    data, 
    false, 
    8.0, 
    Int8(1)
)
