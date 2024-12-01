function parse_media(fpath::String)::Tuple{Int64, Int64, Int64, Vector{Float64}}
    f = open(fpath, "r")
    s = read(f, String)

    s = replace(replace(s, "\n" => ""), "\t"=>"")

    # JOHN HAKC
    # this isn't brittle at all
    nx = parse(Int64, match(r"[0-9].*[0-9]", match(r"integer nx.*?integer", s).match).match)
    ny = parse(Int64, match(r"[0-9].*[0-9]", match(r"integer ny.*?integer", s).match).match)
    nz = parse(Int64, match(r"[0-9].*[0-9]", match(r"integer nz.*?point", s).match).match)
    
    d = Float64[parse(Float64, x) for x in split(strip(replace(split(match(r"density.*", s).match, "[")[2], "]"=>"")), " ")]

    @assert nx * ny * nz == length(d)

    return nx, ny, nz, d
end