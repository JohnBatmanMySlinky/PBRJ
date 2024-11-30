struct IndependentSampler <: AbstractSampler
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