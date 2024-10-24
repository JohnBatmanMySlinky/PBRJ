function parse_width(s::String)::Float64
end

function parse_points(s::String)::FieldVector{4, Pnt3}
end

function parse_curve(fname::String, core::ShapeCore)
    curves = Curve[]
    open(fname) do f
        while !eof(f)
            # read current line
            s = readline(f)
            N_widths = 0
            N_points = 0

            if occursin("width", s)
                N_widths += 1
            elseif occursin("point3", s)
                N_points += 1
            else
            end
            if (N_widths == 2) & (n_points == 1)
                N_widths = 0
                N_points = 0
                push!(curves, CreateCurve())
            end
        end
    end
end