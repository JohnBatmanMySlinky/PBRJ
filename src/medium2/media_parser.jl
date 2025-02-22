function parse_media(fpath::String)::Tuple{Int64, Int64, Int64, Vector{Float64}, Maybe{Vector{Float64}}, Maybe{Vector{Float64}}, Pnt3, Pnt3}
    f = open(fpath, "r")
    s = read(f, String)

    # s = replace(replace(s, "\n" => ""), "\t"=>"")

    # JOHN HAKC
    # this isn't brittle at all
    nx = parse(Int64, match(r"[0-9].*[0-9]|[0-9]", match(r"integer nx.*?]", s).match).match)
    ny = parse(Int64, match(r"[0-9].*[0-9]|[0-9]", match(r"integer ny.*?]", s).match).match)
    nz = parse(Int64, match(r"[0-9].*[0-9]|[0-9]", match(r"integer nz.*?]", s).match).match)

    p0 = RayTracing.Pnt3(parse.(Float64, split(strip(split(split(match(r"point3 p0.*?]", s).match, "[")[2],"]")[1]))))
    p1 = RayTracing.Pnt3(parse.(Float64, split(strip(split(split(match(r"point3 p1.*?]", s).match, "[")[2],"]")[1]))))
    
    
    d = parse.(Float64, split(split(split(match(r"\"float density\"\s\[(.*)\]"s, s).match, "[ ")[2], " ]")[1]))

    le_grid = parse.(Float64, split(split(split(match(r"\"float Lescale\"\s\[(.*)\]"s, s).match, "[ ")[2], " ]")[1]))

    # temperature_grid = parse.(Float64, split(split(split(match(r"\"float Temperature\"\s\[(.*)\]"s, s).match, "[ ")[2], " ]")[1]))
    temperature_grid = nothing

    @assert nx * ny * nz == length(d)

    if !(le_grid isa Nothing)
        @assert length(d) == length(le_grid)
    end
    if !(temperature_grid isa Nothing)
        @assert length(d) == length(temperature_grid)
    end

    return nx, ny, nz, d, le_grid, temperature_grid, p0, p1
end