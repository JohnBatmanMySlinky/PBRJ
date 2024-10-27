function make_nice(input_text::String)::Array{String}

    # Split the input text into lines
    lines = split(input_text, '\n')

    # Resulting text, which we'll concatenate
    result_lines = []

    i = 1
    while i <= length(lines)
        line = lines[i]
        # Check if the current line is part of the last block (e.g., "point3 P") and spans multiple lines
        if occursin("point3 P", line)
            # Concatenate this line with the following lines until the closing bracket is found
            combined_line = line
            while !occursin("]", lines[i])
                i += 1
                combined_line *= " " * strip(lines[i])
            end
            push!(result_lines, combined_line)
        else
            push!(result_lines, line)
        end
        i += 1
    end
    return result_lines
end


function parse_width(s::String)::Float64
    number = parse(Float64, match(r"\d+\.\d+", s).match)
    return number
end

function parse_points(s::String)::SVector{4, Pnt3}
    s = replace(s, " -0 " => " -0.0 ")
    s = replace(s, " 0 " => " 0.0 ")

    matches = collect(eachmatch(r"[-+]?\d*\.\d+", s))

    # Convert the matched strings to Float64 and store them in an array
    ps = parse.(Float64, [m.match for m in matches])

    if length(ps) != 12
        print("$ps : $s")
        @assert false
    end

    return SVector(
        Pnt3(ps[1], ps[2], ps[3]), 
        Pnt3(ps[4], ps[5], ps[6]), 
        Pnt3(ps[7], ps[8], ps[9]), 
        Pnt3(ps[10], ps[11], ps[12])
    )
end

function parse_curves(fname::String, core::ShapeCore)::Array{Curve}
    # HARDCODING
    # SUPER ANEMIC
    # ONLY WORKS FOR BUNNY
    @assert occursin("bunny", fname)
    @assert occursin("v4", fname)

    # get those point3's to the same line
    file_content = read(fname, String)
    processed_content = make_nice(file_content)

    # Begin
    width = 1.0
    degree = 3
    curve_basis = "bezier"
    curve_type = "flat"
    n_segments = 4 - 3
    split_depth = 3
    curves = Curve[]
    widths = Float64[]
    N_widths = 0
    N_points = 0
    N_parsed = 0
    c = SVector(Pnt3(0), Pnt3(0), Pnt3(0), Pnt3(0))
    for s in processed_content
        # read current line
        if occursin("width", s)
            N_widths += 1
            push!(widths, parse_width(s))
        elseif occursin("point3", s)
            N_points += 1
            c = parse_points(s)
        else
            continue
        end

        # println("STATUS: $s --> $N_widths: $widths, $N_points: $c")


        if (N_widths == 2) & (N_points == 1)
            N_parsed += 1
            # print("$N_parsed ")
            curve = CreateCurve(core, c, widths[0+1], widths[1+1], curve_type, nothing, split_depth)
            # println(curve.common)
            # println("\n\n")
            append!(curves, curve)
            N_widths = 0
            N_points = 0
            widths = Float64[]               
        end
    end
    return curves
end