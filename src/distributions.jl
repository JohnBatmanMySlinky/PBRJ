# Optimized distribution sampling with performance improvements

struct Distribution1D
    func::Vector{Float64}
    cdf::Vector{Float64}
    func_int::Float64

    function Distribution1D(func::AbstractVector{Float64})
        N = length(func)
        
        # Pre-allocate and compute CDF in single pass
        cdf = Vector{Float64}(undef, N+1)
        cdf[1] = 0.0
        inv_N = 1.0 / N
        
        @inbounds for i in 2:(N+1)
            cdf[i] = cdf[i-1] + func[i-1] * inv_N
        end
        
        func_int = cdf[N+1]
        
        # Normalize CDF
        if func_int == 0.0
            inv_N_plus_1 = 1.0 / (N + 1)
            @inbounds for i in 1:(N+1)
                cdf[i] = i * inv_N_plus_1
            end
        else
            inv_func_int = 1.0 / func_int
            @inbounds for i in 1:(N+1)
                cdf[i] *= inv_func_int
            end
        end
        
        return new(func, cdf, func_int)
    end
end

# Use binary search instead of linear search for better O(log n) performance
function find_interval(cdf::Vector{Float64}, u::Float64)::Int
    # Binary search with bounds checking
    left, right = 1, length(cdf) - 1
    
    @inbounds while left < right
        mid = (left + right) >> 1  # Faster than div(left + right, 2)
        if cdf[mid + 1] <= u
            left = mid + 1
        else
            right = mid
        end
    end
    
    return left
end

function sample_continuous(d::Distribution1D, u::Float64)::Tuple{Float64, Float64, Int64}
    offset = find_interval(d.cdf, u)
    
    @inbounds begin
        du = u - d.cdf[offset]
        cdf_diff = d.cdf[offset + 1] - d.cdf[offset]
        
        if cdf_diff > 0.0
            du /= cdf_diff
        end
        
        pdf_val = d.func_int > 0.0 ? d.func[offset] / d.func_int : 0.0
        continuous_val = (offset - 1 + du) / length(d.func)
    end
    
    return continuous_val, pdf_val, offset
end

function sample_discrete(d::Distribution1D, u::Float64)::Tuple{Int64, Float64, Float64}
    offset = find_interval(d.cdf, u)
    
    @inbounds begin
        pdf_val = if d.func_int > 0.0
            d.func[offset] / (d.func_int * length(d.func))
        else
            0.0
        end
        
        val = (u - d.cdf[offset]) / (d.cdf[offset + 1] - d.cdf[offset])
    end
    
    return offset, pdf_val, val
end

@inline function discrete_pdf(d::Distribution1D, u::Int64)::Float64
    # Remove bounds check hack with proper clamping
    idx = clamp(u, 1, length(d.func))
    @inbounds return d.func[idx] / (d.func_int * length(d.func))
end

struct Distribution2D
    conditional::Vector{Distribution1D}
    marginal::Distribution1D

    function Distribution2D(dat::Matrix{Float64})
        nv, nu = size(dat)
        
        # Pre-allocate vectors
        conditional = Vector{Distribution1D}(undef, nu)
        marginal_func = Vector{Float64}(undef, nu)
        
        # Process columns in parallel if beneficial
        @inbounds for i in 1:nu
            conditional[i] = Distribution1D(view(dat, :, i))  # Use view to avoid copying
            marginal_func[i] = conditional[i].func_int
        end
        
        return new(conditional, Distribution1D(marginal_func))
    end
    
    # Constructor for non-Float64 matrices (if needed)
    function Distribution2D(dat::Matrix{T}) where T
        nv, nu = size(dat)
        bw = Matrix{Float64}(undef, nv, nu)
        
        @inbounds for j in 1:nu, i in 1:nv
            # Assuming dat elements have .r, .g, .b fields
            pixel = dat[i, j]
            r, g, b = Float64(pixel.r), Float64(pixel.g), Float64(pixel.b)
            bw[i, j] = max((r + g + b) / 3.0, 0.01)  # Faster than mean([r,g,b])
        end
        
        return Distribution2D(bw)
    end
end

function sample_continuous(d::Distribution2D, uv::Pnt2)::Tuple{Pnt2, Float64}
    d1, pdf_val1, offset1 = sample_continuous(d.marginal, uv.y)
    d0, pdf_val0, _ = sample_continuous(d.conditional[offset1], uv.x)
    
    return Pnt2(d0, d1), pdf_val0 * pdf_val1
end

@inline function pdf(d::Distribution2D, p::Pnt2)::Float64
    # More efficient indexing with proper bounds
    @inbounds begin
        iu = clamp(Int(floor(p.x * length(d.conditional[1].func))) + 1, 
                  1, length(d.conditional[1].func))
        iv = clamp(Int(floor(p.y * length(d.marginal.func))) + 1, 
                  1, length(d.marginal.func))
        
        return d.conditional[iv].func[iu] / d.marginal.func_int
    end
end