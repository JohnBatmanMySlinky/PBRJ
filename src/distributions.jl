struct PDF_2D
    col_pdf::Vector{Float64}
    col_cdf::Vector{Float64}
    row_pdf::Matrix{Float64}
    row_cdf::Matrix{Float64}
end

function sample_pdf_2d(pdf::PDF_2D, uv::Pnt2)
    u, v = uv
    u_idx = max(1,sum(pdf.col_cdf .<= u))
    v_idx = max(1,sum(pdf.row_cdf[:,u_idx][:] .<= v))
    return u_idx, v_idx
end

function construct_pdf_2d(dat::Matrix)
    bw = ones(Float64, size(dat))
    for col = 1:size(bw)[1]
        for row = 1:size(bw)[2]
            r = convert(Float64, dat[col,row].r)
            g = convert(Float64, dat[col,row].g)
            b = convert(Float64, dat[col,row].b)
            bw[col,row] = mean([r,g,b])
        end
    end

    # column pdf and cdf
    col_pdf = sum(bw, dims=1)[:]
    col_pdf /= sum(col_pdf)
    col_cdf = cumsum(col_pdf)

    # row pdf and cdf
    row_pdf = bw ./ sum(bw, dims=1)
    row_cdf = cumsum(row_pdf, dims=1)

    return PDF_2D(
        col_pdf,
        col_cdf,
        row_pdf,
        row_cdf
    )
end