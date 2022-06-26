struct SpecularReflection{S <: Spectrum, F<:Fresnel} <: AbstractBxDF
    r::S
    fresnel::F
    type::UInt8
end