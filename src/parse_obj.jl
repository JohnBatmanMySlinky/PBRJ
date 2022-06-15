using StaticArrays
const Vec3 = SVector{3, Float64}

function parse_obj(fname::String, material::Material)::Vector{Hittable}
    # instantiate list of vertices
    vertices = Vec3[]
    triangles = Hittable[]
    open(fname) do f
        while !eof(f)
            # read current line
            s = readline(f)

            # on non-empty lines
            if length(s)>1
                # first two letters tell ya what to do
                ident = s[1:2]

                # parse out vertices
                if ident == "v "
                    tmp = Float64[]
                    splitted = split(s, " ")
                    for each in splitted
                        if !(each in ["v", ""])
                            push!(tmp,parse(Float64, each))
                        end
                    end
                    v = Vec3(
                        tmp[1],
                        tmp[2],
                        tmp[3]
                    )
                    push!(vertices,v)

                elseif ident == "f "
                    tmp = Int64[]
                    splitted = split(s, " ")
                    for each in splitted
                        if !(each in ["f", ""])
                            push!(tmp,parse(Int64, each))
                        end
                    end
                    t = Triangle(
                        vertices[tmp[1]],
                        vertices[tmp[2]],
                        vertices[tmp[3]],
                        material
                    )
                    push!(triangles,t)
                end
            end
        end
    end
    return triangles
end