struct ConstantTexture{T} where {T <: Union{Float64, Spectrum}}
    value::T
end

function (t::ConstantTexture{T})(si::SurfaceInteraction)::T where {T <: Union{Float64, Spectrum}}
    return t.value
end
