# prev.pdf_rev = convert_density(vertex, pdf_rev, prev)
function convert_density(curr::Vertex, pdf::Float64, nxt::Vertex)::Float64
    is_infinite_light(nxt) && return pdf
    
    w = p(nxt) - p(curr)
    (dot(w,w) == 0.0) && (return 0.0)
    inv_dist2 = 1 / dot(w,w)
    if is_on_surface(nxt)
        return pdf * abs(dot(ng(nxt), w*sqrt(inv_dist2))) * inv_dist2
    else
        return pdf * inv_dist2
    end
end

function infinite_light_density(lights::Vector{Light}, light_distr::Distribution1D, w::Vec3)::Float64
    pdf = 0.0
    @assert length(lights) == length(light_distr.func)
    for i in 1:length(lights)
        light = lights[i]
        if is_infinite_light(light)
            pdf += pdf_li(light, empty_surface_interation(), -w) * light_distr.func[i]
            @info "MISWEIGHT <<a4>> SHENANIGANS: pdf $(pdf)"
        end
    end
    @info "MISWEIGHT <<a4>> SHENANIGANS: func_int $(light_distr.func_int) count $(length(light_distr.func))"
    return pdf / (light_distr.func_int * length(light_distr.func))
end

function print_nice(path::Vector{Vertex})
    for i in 1:length(path)
        if isassigned(path,i)
            print("  $(i): $(path[i].type)\n    p: $(p(path[i]))\n    beta: $(path[i].beta)\n")
        end
    end
end

function print_nice(v::Vertex)
    print("    $(v.type)\n      p: $(p(v))\n      beta: $(v.beta)\n")
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