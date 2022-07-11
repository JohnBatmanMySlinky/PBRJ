function parse_vertex(s::String)
    tmp = Float64[]
    splitted = split(s, " ")
    for each in splitted
        if !(each in ["v", ""])
            push!(tmp,parse(Float64, each))
        end
    end
    return Pnt3(tmp[1], tmp[2], tmp[3])
end

function push_vertices!(s::String, indices::Vector{Int64})
    splitted = split(s, " ")
    for each in splitted
        if !(each in ["f", ""])
            push!(indices, parse(Int64, each))
        end
    end
end


function parse_obj(fname::String, object_to_world::Transformation)
    vertices = Pnt3[]
    indices = Int64[]
    open(fname) do f
        while !eof(f)
            # read current line
            s = readline(f)

            # skip empty lines
            if length(s) < 2
                continue
            end

            # first two characters tell you what to do 
            key = s[1:2]

            # parse vertices
            if key == "v "
                v = parse_vertex(s)
                push!(vertices,v)
            # parse indices
            elseif key == "f "
                push_vertices!(s, indices)
            end
        end
    end
    @assert length(indices) % 3 == 0
    return construct_triangle_mesh(
        ShapeCore(object_to_world, Inv(object_to_world)), 
        length(indices)÷3,  # n_triangles
        length(vertices),   # n_vertices
        vertices,
        indices,
    )
end 