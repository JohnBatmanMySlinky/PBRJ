using StaticArrays

abstract type AbstractBxDF end
abstract type BSDF end
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

const Radiance = Val{:Radiance}
const Importance = Val{:Importance}
const TransportMode = Union{Radiance, Importance}

const Reflectance = Val{:Reflectance}
const Illuminant = Val{:Illuminant}
const SpectrumType = Union{Reflectance, Illuminant}

const ShadowEpsilon::Float64 = 0.00001 

include("../src/objects.jl")

include("../src/spectrum/spectrum_constants.jl")   # constants for spectral <-> RGB <-> XYZ
include("../src/spectrum/spectrum_macro.jl")       # the file to create the macro
include("../src/spectrum/spectrum.jl")             # all of the 'constructors'
const nSpectralSamples::Int64 = 3         # if it's 3 --> RGB if it's >3 --> spectral
const sampledLambdaStart::Int64 = 400
const sampledLambdaEnd::Int64 = 700
const nCIESamples::Int64 = 471
const CIE_Y_integral::Float64 = 106.856895
const nRGB2SpectSamples::Int64 = 32
@make_spectrum nSpectralSamples    # define the Spectrum struct
include("../src/spectrum/spectrum_utils.jl")       # things that reference the Spectrum struct

# instantiate these at global level to be used for spectral 
const XXX::Spectrum, YYY::Spectrum, ZZZ::Spectrum, rgbRefl2SpectWhite::Spectrum, rgbRefl2SpectCyan::Spectrum, 
    rgbRefl2SpectMagenta::Spectrum, rgbRefl2SpectYellow::Spectrum, rgbRefl2SpectRed::Spectrum,
    rgbRefl2SpectGreen::Spectrum, rgbRefl2SpectBlue::Spectrum, rgbIllum2SpectWhite::Spectrum, 
    rgbIllum2SpectCyan::Spectrum, rgbIllum2SpectMagenta::Spectrum, rgbIllum2SpectYellow::Spectrum, 
    rgbIllum2SpectRed::Spectrum, rgbIllum2SpectGreen::Spectrum, rgbIllum2SpectBlue::Spectrum = make_spectral_constants()

include("../src/medium/media1.jl")
include("../src/ray.jl")
include("../src/primitive.jl")
include("../src/interactions.jl")
include("../src/transformations.jl")

function fun()::Pnt3
    t1 = Translate(Pnt3(1.0, 2.0, 3.0))
    p = Pnt3(0.0, 0.0, 0.0)
    
    return t1(p)
end



print(fun())