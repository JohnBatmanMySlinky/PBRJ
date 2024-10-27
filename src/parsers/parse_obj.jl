##############################
##############################
######## WARNING #############
##############################
##############################
# This parser is really lazy. 
# It only uses one index for verticies, normals and UVs. 


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
            if occursin("/", each)
                push!(indices, parse(Float64, split(each,"/")[1]))
            else
                push!(indices, parse(Float64, each))
            end
        end
    end
end

function parse_normals(s::String)
    tmp = Float64[]
    splitted = split(s, " ")
    for each in splitted
        if !(each in ["vn", ""])
            push!(tmp,parse(Float64, each))
        end
    end
    return Nml3(tmp[1], tmp[2], tmp[3])
end

function parse_uvs(s::String)
    tmp = Float64[]
    splitted = split(s, " ")
    for each in splitted
        if !(each in ["vt", ""])
            push!(tmp, parse(Float64, each))
        end
    end
    return Pnt2(tmp[1], tmp[2])
end


function parse_obj(
    fname::String, 
    object_to_world::Transformation, 
    reverse_orientation::Bool, 
    transform_swaps_handedness::Bool,
    alpha_mask::Maybe{Texture},
)
    vertices = Pnt3[]
    indices = Int64[]
    normals = Nml3[]
    uvs = Pnt2[]
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
            elseif key == "vn"
                n = parse_normals(s)
                push!(normals, n)
            elseif key == "vt"
                vt = parse_uvs(s)
                push!(uvs, vt)
            end
            # parse UV
        end
    end
    @assert length(indices) % 3 == 0

    # if no UVs found, add dummy UVs
    if length(uvs) == 0
        for i in 1:length(vertices)
            push!(uvs, Pnt2(1,1))
        end
    end

    # if no Normals found, add dummy UVs
    if length(normals) == 0
        for i in 1:length(vertices)
            push!(normals, Nml3(0,1,0))
        end
    end

    return construct_triangle_mesh(
        ShapeCore(object_to_world, Inv(object_to_world), reverse_orientation, transform_swaps_handedness), 
        length(indices)÷3,  # n_triangles
        length(vertices),   # n_vertices
        vertices,
        indices,
        normals,
        uvs,
        alpha_mask
    )
end 