# Sample input text
sample = """
Shape "curve"
    "float width1" [ 0.000007 ]
    "float width0" [ 0.00008 ]
    "point3 P" [ 0.015324 0.092942 -0.002831 0.013578 0.089427 -0.000629 0.012352
                 0.085382 0.000916 0.011462 0.081116 0.002038 ]
"""

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

result = make_nice(sample)
println(result)