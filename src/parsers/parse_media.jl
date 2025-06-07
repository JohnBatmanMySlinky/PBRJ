function parse_media(fpath::String)
    content = read(fpath, String)

    # Remove leading/trailing whitespace and split into tokens
    tokens = split(strip(content))
    
    # Initialize return values
    nx = nothing
    ny = nothing
    nz = nothing
    p0 = nothing
    p1 = nothing
    density = nothing
    Lescale = nothing
    i = 3 # Start after command and name
    
    while i <= length(tokens)
        if tokens[i] == "\"string" && i + 2 <= length(tokens)
            param_name = strip(tokens[i+1], '"')
            i += 2
            # Handle both formats: with and without brackets
            if i <= length(tokens) && tokens[i] == "["
                i += 1
                # Read until closing bracket (but ignore the value for now)
                while i <= length(tokens) && tokens[i] != "]"
                    i += 1
                end
                if i <= length(tokens) && tokens[i] == "]"
                    i += 1
                end
            else
                # Old format without brackets
                i += 1
            end
        elseif tokens[i] == "\"integer" && i + 2 <= length(tokens)
            param_name = strip(tokens[i+1], '"')
            i += 2
            
            # Handle both formats: with and without brackets
            value = nothing
            if i <= length(tokens) && tokens[i] == "["
                i += 1
                if i <= length(tokens) && tokens[i] != "]"
                    value = RayTracing.parse(Int, tokens[i])
                    i += 1
                end
                # Skip to closing bracket
                while i <= length(tokens) && tokens[i] != "]"
                    i += 1
                end
                if i <= length(tokens) && tokens[i] == "]"
                    i += 1
                end
            else
                # Old format without brackets
                value = RayTracing.parse(Int, tokens[i])
                i += 1
            end
            
            if param_name == "nx"
                nx = value
            elseif param_name == "ny"
                ny = value
            elseif param_name == "nz"
                nz = value
            end
            
        elseif (tokens[i] == "\"point" || tokens[i] == "\"point3") && i + 1 <= length(tokens)
            param_name = strip(tokens[i+1], '"')
            i += 2
            
            # Expect opening bracket
            if i <= length(tokens) && tokens[i] == "["
                i += 1
                coords = Float64[]
                # Read coordinates until closing bracket
                while i <= length(tokens) && tokens[i] != "]"
                    push!(coords, RayTracing.parse(Float64, tokens[i]))
                    i += 1
                end
                if i <= length(tokens) && tokens[i] == "]"
                    i += 1
                end
                
                if param_name == "p0"
                    p0 = coords
                elseif param_name == "p1"
                    p1 = coords
                end
            end
            
        elseif tokens[i] == "\"float" && i + 2 <= length(tokens)
            param_name = strip(tokens[i+1], '"')
            i += 2
            
            # Expect opening bracket
            if i <= length(tokens) && tokens[i] == "["
                i += 1
                if param_name == "density"
                    # Fast parsing for large density array
                    density = parse_float_array_fast(tokens, i)
                    # Skip to after the closing bracket
                    while i <= length(tokens) && tokens[i] != "]"
                        i += 1
                    end
                    if i <= length(tokens) && tokens[i] == "]"
                        i += 1
                    end
                elseif param_name == "Lescale"
                    # Fast parsing for large Lescale array
                    Lescale = parse_float_array_fast(tokens, i)
                    # Skip to after the closing bracket
                    while i <= length(tokens) && tokens[i] != "]"
                        i += 1
                    end
                    if i <= length(tokens) && tokens[i] == "]"
                        i += 1
                    end
                else
                    # Regular float array parsing
                    values = Float64[]
                    while i <= length(tokens) && tokens[i] != "]"
                        push!(values, RayTracing.parse(Float64, tokens[i]))
                        i += 1
                    end
                    if i <= length(tokens) && tokens[i] == "]"
                        i += 1
                    end
                end
            end
        else
            # Skip unrecognized tokens
            i += 1
        end
    end
    return nx, ny, nz, density, Lescale, nothing, p0, p1
end

function parse_float_array_fast(tokens, start_idx)
    # Pre-allocate with reasonable size
    result = Float64[]
    sizehint!(result, 1_000_000) # Hint for large arrays
    i = start_idx
    while i <= length(tokens) && tokens[i] != "]"
        push!(result, RayTracing.parse(Float64, tokens[i]))
        i += 1
    end
    return result
end