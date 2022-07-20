# 7.2.2
# Basic Sampler Interface
mutable struct Sampler <: AbstractSampler
    samples_per_pixel::Int64
    current_pixel::Pnt2
    current_pixel_sample_index::Int64
    sample_1d_array_sizes::Vector{Int64}
    sample_2d_array_sizes::Vector{Int64}
    sample_1d_array::Vector{Vector{Float64}}
    sample_2d_array::Vector{Vector{Pnt2}}
    array_1d_offset::UInt64
    array_2d_offset::UInt64
end


# "The first five dimensions generate:d by Samplers are generally used by the Camera. 
# In this case, the first two are specifically used to choose a point on the image inside the current pixel area; 
# the third is used to compute the time at which the sample should be taken; 
# and the fourth and fifth dimensions give a  lens position for depth of field.
function get_camera_sample(sampler::AbstractSampler, p_raster::Pnt2)
    p_film = p_raster .+ get_2D(sampler) # 1,2
    time = get_1D(sampler)               # 3
    p_lens = get_2D(sampler)             # 4,5
    return CameraSample(
        p_film,
        p_lens,
        time
    )
end
