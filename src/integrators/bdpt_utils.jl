# prev.pdf_rev = convert_density(vertex, pdf_rev, prev)
function convert_density(curr::Vertex, pdf::Float64, nxt::Vertex)::Float64
    is_infinite_light(nxt) && return pdf
    
    w = p(nxt) - p(curr)
    inv_dist2 = 1 / (norm(w)^2)
    if is_on_surface(nxt)
        return pdf * abs(dot(ng(nxt), w*sqrt(inv_dist2))) * inv_dist2
    else
        return pdf * inv_dist2
    end
end

function print_nice(path::Vector{Vertex})
    for i in 1:length(path)
        if isassigned(path,i)
            print(path[i].type, " ")
        end
    end
end

function correct_shading_normal(isect::SurfaceInteraction, wo::Vec3, wi::Vec3, mode::Type{T})::Float64 where T <: TransportMode
    if mode == Importance
        num = abs(dot(wo, isect.shading.n)) * abs(dot(wi, isect.core.n))
        denom = abs(dot(wo, isect.core.n)) * abs(dot(wi, isect.shading.n))
        (denom == 0.0) && (return 0.0)
        return num / denom
    else
        return 1.0
    end
end