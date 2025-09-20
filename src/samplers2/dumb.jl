struct DumbSampler <: AbstractSampler
    samples_per_pixel::Int64
end

function start_pixel_sample!(ss::DumbSampler, pixel::Pnt2i, sample_index::Int64, dim::Int64=0)
end

function get_1D!(is::DumbSampler)::Float64
    return 0.8
end

function get_2D!(is::DumbSampler)::Pnt2
    return Pnt2(0.8, 0.8)
end

function get_pixel_2D!(is::DumbSampler)::Pnt2
    return get_2D!(is)
end