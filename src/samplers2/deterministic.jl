mutable struct DeterministicSampler <: AbstractSampler
    samples_per_pixel::Int64
    state::UInt32
    counter::Int64

    function DeterministicSampler(samples_per_pixel::Int64)
        return new(samples_per_pixel, 0x00000000, 0)
    end
end

function clone(sampler::DeterministicSampler, seed::Int64)::DeterministicSampler
    cloned = DeterministicSampler(sampler.samples_per_pixel)
    cloned.state = sampler.state + UInt32(seed)  # Perturb state for clone
    cloned.counter = 0
    return cloned
end

function start_pixel_sample!(sampler::DeterministicSampler, p::Pnt2i, ::Int64)
    # Use the same constants as C++: 374761393 and 668265263
    sampler.state = (UInt32(p.x) * 0x165667b1 + UInt32(p.y) * 0x27d4eb2f) ⊻ 0x12345678
end

function get_float(sampler::DeterministicSampler)::Float64
    # LCG: Numerical Recipes parameters (same as C++)
    sampler.state = sampler.state * 0x19660d + 0x3c6ef35f
    sampler.counter += 1
    @info "LCG: counter = $(sampler.counter), u = $((sampler.state >> 8) * (1.0 / 16777216.0))"
    return (sampler.state >> 8) * (1.0 / 16777216.0)
end

function get_1D!(sampler::DeterministicSampler)::Float64
    return get_float(sampler)
end

function get_2D!(sampler::DeterministicSampler)::Pnt2
    why = get_float(sampler)
    god = get_float(sampler)
    return Pnt2(why, god)
end

function get_pixel_2D!(sampler::DeterministicSampler)::Pnt2
    why = get_float(sampler)
    god = get_float(sampler)
    return Pnt2(why, god)
end