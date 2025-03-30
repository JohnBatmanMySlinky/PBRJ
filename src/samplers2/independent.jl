struct IndependentSampler <: AbstractSampler
    samples_per_pixel::Int64
end

function start_pixel_sample!(ss::IndependentSampler, pixel::Pnt2, sample_index::Int64, dim::Int64=0)
end

function get_1D!(is::IndependentSampler)::Float64
    return rand()
end

function get_2D!(is::IndependentSampler)::Pnt2
    return Pnt2(rand(), rand())
end

function get_pixel_2D!(is::IndependentSampler)::Pnt2
    return get_2D!(is)
end