mutable struct UniformSampler <: AbstractSampler
    current_pixel::Int64
    samples_per_pixel::Int64
end

function UniformSampler(samples_per_pixel::Int64)
    return UniformSampler(
        1,
        samples_per_pixel
    )
end

function get_1D(u::UniformSampler)
    return rand()
end

function get_2D(u::UniformSampler)
    return Pnt2(rand(), rand())
end

function has_next_sample(u::UniformSampler)::Bool
    u.current_sample ≤ u.samples_per_pixel
end

function start_next_sample(u::UniformSampler)
    u.current_sample += 1
end