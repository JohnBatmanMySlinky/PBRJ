# Blindly following PBRT because apparently I am having trouble thinking for myself
struct Distribution1D
    func::Vector{Float64}
    cdf::Vector{Float64}
    func_int::Float64

    function Distribution1D(func::Vector{Float64})
        N = length(func)
        cdf = Array{Float64, 1}(undef, N+1)
        cdf[1] = 0
        for i = 2:(N+1)
            cdf[i] = cdf[i-1] + func[i-1] / N
        end
        func_int = cdf[N+1]
        if func_int == 0
            for i = 1:(N+1)
                cdf[i] = i / (N+1)
            end
        else
            for i = 1:(N+1)
                cdf[i] /= func_int
            end
        end
        return new(func,cdf,func_int)
    end
end

function sample_continuous(d::Distribution1D, u::Float64)::Tuple{Float64, Float64, Int64} # (val, pdf, offset)
    offset = min(sum(d.cdf .<= u),length(d.cdf)-1) # John hack to avoid index error when u=1.0
    du = u - d.cdf[offset]
    if d.cdf[offset+1] - d.cdf[offset] > 0
        du /= (d.cdf[offset+1] - d.cdf[offset])
    end
    pdf_val = (d.func_int > 0) ? d.func[offset] / d.func_int : 0 
    return (offset-1 + du) / length(d.func), pdf_val, offset
end

function sample_discrete(d::Distribution1D, u::Float64)::Tuple{Int64, Float64, Float64}
    offset = min(sum(d.cdf .<= u),length(d.cdf)-1) # John hack to avoid index error when u=1.0
    pdf_val = (d.func_int > 0) ? d.func[offset] / (d.func_int * length(d.func)) : 0
    val = (u - d.cdf[offset]) / (d.cdf[offset + 1] - d.cdf[offset])
    return offset, pdf_val, val
end

function discrete_pdf(d::Distribution1D, u::Int64)::Float64
    return d.func[u] / (d.func_int * length(d.func))
end

struct Distribution2D
    conditional::Vector{Distribution1D}
    marginal::Distribution1D

    function Distribution2D(dat::Matrix)
        # if matrix of floats, proceed, else, convert image to floats
        if dat[1,1] isa Float64
            bw = dat
            nv, nu = size(bw)
        else
            bw = ones(Float64, size(dat))
            nv, nu = size(bw)
            for row = 1:nv
                for col = 1:nu
                    r = convert(Float64, dat[row,col].r)
                    g = convert(Float64, dat[row,col].g)
                    b = convert(Float64, dat[row,col].b)
                    bw[row,col] = max(mean([r,g,b]), .01)
                end
            end
        end

        conditional = Distribution1D[]
        marginal_func = Float64[]
        for i = 1:nv
            push!(conditional, Distribution1D(bw[i,:]))
            push!(marginal_func, conditional[i].func_int)
        end
        return new(
            conditional,
            Distribution1D(marginal_func)
        )
    end
end

function sample_continuous(d::Distribution2D, uv::Pnt2)::Tuple{Pnt2, Float64}
    d1, pdf_val1, offset1 = sample_continuous(d.marginal, uv.y)
    d0, pdf_val0, _ = sample_continuous(d.conditional[offset1], uv.x)
    @assert (d0 < 1) && (d1 < 1)
    return Pnt2(d0, d1), pdf_val0 * pdf_val1

end

function pdf(d::Distribution2D, p::Pnt2)::Float64   
    iu = max(1, Int(floor(p.x * length(d.conditional[1].func)))+1) # as opposed to PBRT's clamp
    iv = max(1, Int(floor(p.y * length(d.marginal.func)))+1) # as opposed to PBRT's clamp
    return d.conditional[iv].func[iu] / d.marginal.func_int
end