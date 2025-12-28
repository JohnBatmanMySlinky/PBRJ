function parse_uv_3dsmax_2011(line::AbstractString)::RayTracing.Pnt2
	parts = split(strip(line))[2:end]
	return RayTracing.Pnt2(parse(Float64, parts[1]), parse(Float64, parts[2]))
end

function parse_obj_3dsmax_2011(
    file_path::AbstractString,
    object_to_world::RayTracing.Transformation, 
    reverse_orientation::Bool, 
    transform_swaps_handedness::Bool,
    alpha_mask::RayTracing.Maybe{String},
)
	vertices = RayTracing.Pnt3[]
    vertex_indices = Int[]

	uvs = RayTracing.Pnt2[]
    uv_indices = Int[]

	normals = RayTracing.Nml3[]
	normal_indices = Int[]

    # JOHN TOOD
    # massive container of abstract shit
    FIN = []
    global NFACE = -1

    sc = ShapeCore(
        object_to_world, 
        Inv(object_to_world),
        reverse_orientation, 
        transform_swaps_handedness
    )

	
	open(file_path) do file
		for line in eachline(file)
			line = strip(line)
			if isempty(line) || startswith(line, "#")
				continue
			end
			
			parts = split(line)
			cmd = parts[1]
            cmd2 = length(line) >= 8 ? line[1:8] : "not set"
			
            if cmd == "v"
                push!(vertices, parse_vertex(line))
            elseif cmd == "vt"
                push!(uvs, parse_uv_3dsmax_2011(line))
            elseif cmd == "vn"
                push!(normals, parse_normal(line))
            elseif cmd == "f"
                global NFACE = length(split(strip(line))[2:end])
                if !((NFACE == 3) || (NFACE == 4))
                    throw(ArgumentError("Invalid face format on line: $line - NFACE: $NFACE"))
                end
                parse_face!(line, vertex_indices, uv_indices, normal_indices)
            elseif cmd == "mtllib"
                @warn "Skipping material: $line"
                continue
            elseif cmd == "usemtl"
                @warn "Skipping material: $line"
                continue
            elseif cmd == "g"
                @warn "Skipping group: $line"
                continue
            elseif cmd == "o"
                @warn "Skipping group: $line"
                continue
            elseif cmd2 == "# object"
                # as seen in barcelona_pavillion mesh_00001.obj...
                # multiple objects in one OBJ & mixed tris and quads :(

                if length(vertices) == 0
                    @assert NFACE == -1 # shouldn't be set yet
                    #################################################
                    # if we haven;t gotten any vertices yet, continue
                    #################################################
                    continue
                else
                    ######################
                    # proceed to publish
                    ######################
                    publish!(
                        FIN, 
                        NFACE,
                        vertices,
                        vertex_indices,
                        uvs,
                        uv_indices,
                        normals,
                        normal_indices,
                        sc,
                        alpha_mask
                    )

                    # RESET THE INDICES
                    vertex_indices = Int[]
                    uv_indices = Int[]
                    normal_indices = Int[]

                end
            elseif cmd == "s"
                @warn "Skipping something: $line"
                continue
            elseif cmd == "l"
                @warn "Skipping line: $line"
                continue
            else
                @assert false
            end
		end
	end

    publish!(
        FIN, 
        NFACE,
        vertices,
        vertex_indices,
        uvs,
        uv_indices,
        normals,
        normal_indices,
        sc,
        alpha_mask
    )

	return FIN
end
