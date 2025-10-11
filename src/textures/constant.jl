struct ConstantTexture{T <: Union{Float64, Spectrum}} <: AbstractTexture{T}
    value::T
    name::Maybe{String}

    function ConstantTexture(
        value::T, 
        name::Maybe{String}=nothing
    )::ConstantTexture{T} where T <: Union{Float64, Spectrum}
        return new{T}(value, name)
    end
end

function (t::ConstantTexture{T})(si::SurfaceInteraction)::T where {T <: Union{Float64, Spectrum}}
    return t.value
end
