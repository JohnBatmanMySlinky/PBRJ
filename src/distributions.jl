struct Distribution1D
    pdf::Vector{Float64}
    cdf::Vector{Float64}
    len::Int64

    function Distribution1D(dat::Vector{Float64})
        tmp=dat/sum(dat)
        return new(
            tmp,
            vcat([0.0], cumsum(tmp)),
            length(tmp)
        )
    end
end

function sample_continuous(d::Distribution1D, u::Float64)::Tuple{Float64, Float64}
    offset = sum(d.cdf .<= u)
    du = u - d.cdf[offset]
    du /= (d.cdf[offset+1] - d.cdf[offset])
    return (offset-1+du)/d.len, d.pdf[offset] # return tuple(value, prob)
end

function sample_discrete(d::Distribution1D, u::Float64)::Tuple{Float64, Float64}
    offset = sum(d.cdf .< u)
    return offset, d.pdf[offset] / d.len # return tuple(value, prob)
end


struct Distribution2D
    col_pdf::Vector{Float64}
    col_cdf::Vector{Float64}
    row_pdf::Matrix{Float64}
    row_cdf::Matrix{Float64}

    function Distribution2D(dat::Matrix)
        bw = ones(Float64, size(dat))
        for col = 1:size(bw)[1]
            for row = 1:size(bw)[2]
                r = convert(Float64, dat[col,row].r)
                g = convert(Float64, dat[col,row].g)
                b = convert(Float64, dat[col,row].b)
                bw[col,row] = mean([r,g,b]) + .01
            end
        end

        # column pdf and cdf
        col_pdf = sum(bw, dims=1)[:]
        col_pdf /= sum(col_pdf)
        col_cdf = cumsum(col_pdf)

        # row pdf and cdf
        row_pdf = bw ./ sum(bw, dims=1)
        row_cdf = cumsum(row_pdf, dims=1)

        return new(
            col_pdf,
            col_cdf,
            row_pdf,
            row_cdf
        )
    end
end

function sample_pdf_2d(pdf::Distribution2D, uv::Pnt2)::Tuple{Int64, Int64}
    u, v = uv
    u_idx = max(1,sum(pdf.col_cdf .<= u))
    v_idx = max(1,sum(pdf.row_cdf[:,u_idx][:] .<= v))
    return u_idx, v_idx
end