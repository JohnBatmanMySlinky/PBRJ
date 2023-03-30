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
            print("  $(i): $(path[i].type) p: $(p(path[i])), beta: $(path[i].beta)\n")
        end
    end
end

function print_nice(v::Vertex)
    print("    $(v.type) at $(p(v)) beta $(v.beta) t $(time(v))\n")
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

function remap0(f::Float64)::Float64
    return f == 0.0 ? 1.0 : f
end

struct VertexLog
    delta::Bool
    pdf_fwd::Float64
    pdf_rev::Float64
end