function parse_transform(transform_string)
    # Match "Transform" followed by brackets containing numbers
    pattern = r"Transform\s*\[\s*((?:-?\d+\.?\d*\s*)+)\s*\]"
    match_result = match(pattern, transform_string)
    
    if match_result !== nothing
        # Extract the numbers from the captured group
        numbers_str = match_result.captures[1]
        # Find all individual numbers and join them
        numbers = eachmatch(r"-?\d+\.?\d*", numbers_str)
        return join([m.match for m in numbers], " ")
    else
        return nothing
    end
end

function parse_sanmiguel(fpath, START, END)
    data = readlines(fpath)
    transforms = String[]
    nlines = length(data)
    
    for i in 1:nlines
        if (i < START) || (i > END)
            continue
        end
        
        transform = parse_transform(data[i])
        if transform !== nothing
            push!(transforms, transform)
        end
    end
    
    return transforms
end

# Main execution (Julia equivalent of if __name__ == "__main__")
if abspath(PROGRAM_FILE) == @__FILE__
    fpath = "/Users/johnmyslinski/Documents/pbrt-v3-scenes/sanmiguel/geometry/sanmiguel-geom.pbrt"
    START = 215
    END = 234
    transforms = parse_sanmiguel(fpath, START, END)
    
    open("out.txt", "w") do f
        write(f, join(transforms, "\n"))
    end
end