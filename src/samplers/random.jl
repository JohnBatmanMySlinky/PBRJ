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

function get_1D!(u::UniformSampler)
    return rand()
end

function get_2D!(u::UniformSampler)
    return Pnt2(rand(), rand())
end

function has_next_sample(u::UniformSampler)::Bool
    u.current_pixel ≤ u.samples_per_pixel
end

function start_next_sample!(u::UniformSampler)
    u.current_pixel += 1
end

function start_pixel!(u::UniformSampler, ::Pnt2)
    u.current_pixel = 1
end

# "The first five dimensions generate:d by Samplers are generally used by the Camera. 
# In this case, the first two are specifically used to choose a point on the image inside the current pixel area; 
# the third is used to compute the time at which the sample should be taken; 
# and the fourth and fifth dimensions give a  lens position for depth of field.
function get_camera_sample!(sampler::UniformSampler, p_raster::Pnt2)
    p_film = p_raster .+ get_2D!(sampler) # 1,2
    time = get_1D!(sampler)               # 3
    p_lens = get_2D!(sampler)             # 4,5
    return CameraSample(
        p_film,
        p_lens,
        time
    )
end