# PBR 8.3 LambertianReflection  
struct LambertianReflection{S <: Spectrum} <: AbstractBxDF
    r::S
    type::UInt8

    function LambertianReflection(r::S) where S <: Spectrum
        new{S}(r, BSDF_DIFFUSE | BSDF_REFLECTION)
    end
end


# The reflection distribution function for LambertianReflection is quite straightforward, since its value is constant. 
# However, the value  must be returned, rather than the reflectance  supplied to the constructor. 
# This can be seen by equating  to Equation (8.1), which defined , and solving for the BRDF’s value.
function (l::LambertianReflection{S})(::Vec3, ::Vec3)::Spectrum where S <: Spectrum
    return l.r / pi
end

function rho(l::LambertianReflection{S}, ::Vec3, ::Int64, ::Vector{Pnt2},) where S <: Spectrum
    return l.r
end

function rho(l::LambertianReflection{S}, ::Vector{Pnt2}, ::Vector{Pnt2},) where S <: Spectrum
    return l.r
end


# LambertianTransmission
# TODO