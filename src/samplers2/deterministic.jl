mutable struct DeterministicSampler <: AbstractSampler
    samples_per_pixel::Int64
    state::UInt32

    function DeterministicSampler(samples_per_pixel::Int64)
        return new(samples_per_pixel, 0x00000000)
    end
end

function clone(sampler::DeterministicSampler, seed::Int)::DeterministicSampler
    cloned = DeterministicSampler(sampler.samples_per_pixel)
    cloned.state = sampler.state + UInt32(seed)  # Perturb state for clone
    return cloned
end

function start_pixel!(sampler::DeterministicSampler, px::Int64, py::Int64)
    sampler.state = (UInt32(px) * 0x16493c79 + UInt32(py) * 0x27d4eb2f) ⊻ 0x12345678
end

function get_float(sampler::DeterministicSampler)::Float64
    sampler.state = sampler.state * 0x19660d + 0x3c6ef35f
    return (sampler.state >> 8) * (1.0 / 16777216.0)
end

function get_1d!(sampler::DeterministicSampler)::Float64
    return get_float(sampler)
end

function get_2d!(sampler::DeterministicSampler)::Pnt2
    return Pnt2(get_floar(sampler), get_floar(sampler))
end