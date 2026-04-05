function parse_uv_3dsmax_2011(line::AbstractString)::RayTracing.Pnt2
	parts = split(strip(line))[2:end]
	return RayTracing.Pnt2(parse(Float64, parts[1]), parse(Float64, parts[2]))
end

function parse_obj_3dsmax_2011(
    file_path::AbstractString,
    sc_dict::Dict{String,RayTracing.ShapeCore}, 
    alpha_mask_dict::Dict{String, Maybe{String}},
)
	vertices = RayTracing.Pnt3[]
    vertex_indices = Int[]

	uvs = RayTracing.Pnt2[]
    uv_indices = Int[]

	normals = RayTracing.Nml3[]
	normal_indices = Int[]

    idx_to_group_mapper = Dict{Int64, String}()
    idx = 1
    cmd2_prev = ""

    # JOHN TOOD
    # massive container of abstract shit
    FIN = []
    NFACE = -1
	
	open(file_path) do file
		for line in eachline(file)
            if length(line) >= 8
                cmd2 = line[1:8]
                if (cmd2 == "# object") && (idx == 1) && (length(vertices) == 0)
                    cmd2_prev = line
                end
            else
                cmd2 = "not set"
            end

			line = strip(line)
			if isempty(line) || (startswith(line, "#") && cmd2 != "# object")
				continue
			end
			
			parts = split(line)
			cmd = parts[1]
		
            if cmd == "v"
                push!(vertices, parse_vertex(line))
            elseif cmd == "vt"
                push!(uvs, parse_uv_3dsmax_2011(line))
            elseif cmd == "vn"
                push!(normals, parse_normal(line))
            elseif cmd == "f"
                NFACE = length(split(strip(line))[2:end])
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
                    # @warn """Publishing - $line\n\t# vertices - $(length(vertices))\n\t# uvs - $(length(uvs))\n\t# normals - $(length(normals))"""
                    ######################
                    # proceed to publish
                    ######################

                    sc = Base.get(sc_dict, cmd2_prev, ShapeCore())
                    alpha_mask = Base.get(alpha_mask_dict, cmd2_prev, nothing)
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

                    idx_to_group_mapper[idx] = cmd2_prev
                    cmd2_prev = line
                    idx += 1
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

    # @warn """Final Publishing\n\t# vertices - $(length(vertices))\n\t# uvs - $(length(uvs))\n\t# normals - $(length(normals))"""
    sc = Base.get(sc_dict, cmd2_prev, ShapeCore())
    alpha_mask = Base.get(alpha_mask_dict, cmd2_prev, nothing)
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

    idx_to_group_mapper[idx] = cmd2_prev

	return FIN, idx_to_group_mapper
end
