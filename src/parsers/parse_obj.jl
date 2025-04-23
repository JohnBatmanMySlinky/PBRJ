function parse_vertex(line::AbstractString)::RayTracing.Pnt3
	parts = split(strip(line))[2:end]
	if length(parts) != 3
		throw(ArgumentError("Invalid vertex format: $line"))
	end
	return RayTracing.Pnt3(parse(Float64, parts[1]), parse(Float64, parts[2]), parse(Float64, parts[3]))
end

function parse_normal(line::AbstractString)::RayTracing.Nml3
	parts = split(strip(line))[2:end]
	if length(parts) != 3
		throw(ArgumentError("Invalid vertex format: $line"))
	end
	return RayTracing.Nml3(parse(Float64, parts[1]), parse(Float64, parts[2]), parse(Float64, parts[3]))
end

function parse_uv(line::AbstractString)::RayTracing.Pnt2
	parts = split(strip(line))[2:end]
	if length(parts) != 2
		throw(ArgumentError("Invalid vertex format: $line"))
	end
	return RayTracing.Pnt2(parse(Float64, parts[1]), parse(Float64, parts[2]))
end

function parse_face!(
    line::AbstractString,
    vertex_indices::Vector{Int},
    uv_indices::Vector{Int},
    normal_indices::Vector{Int}
)
	parts = split(strip(line))[2:end]
	
	for part in parts
		indices = split(part, "/")
		push!(vertex_indices, parse(Int, indices[1]))
		
        if length(indices) > 1 && indices[2] != ""
            push!(uv_indices, parse(Int, indices[2]))
        end
		
		if length(indices) > 2 && indices[3] != ""
            push!(normal_indices, parse(Int, indices[3]))
        end
    end
end

function publish!(
    FIN::Vector{Any}, 
    NFACE::Int64,
    vertices::Vector{Pnt3},
    vertex_indices::Vector{Int},
    uvs::Vector{Pnt2},
    uv_indices::Vector{Int},
    normals::Vector{Nml3},
    normal_indices::Vector{Int},
    sc::ShapeCore,
    alpha_mask::Maybe{AbstractTexture{Float64}}
)
    # if face only specifies a single set of indices but we get normals
    # as seen in teapot.obj
    if (length(normals) > 0) & (length(normal_indices) == 0)
        @assert length(vertices) == length(normals)
        normal_indices = vertex_indices
    end

    # if face only specifies a single set of indices but we get uvs
    # as seen in teapot.obj
    if (length(uvs) > 0) & (length(uv_indices) == 0)
        @assert length(vertices) == length(uvs)
        uv_indices = vertex_indices
    end

    @assert mod(length(vertex_indices), NFACE) == 0
    @assert mod(length(uv_indices), NFACE) == 0
    @assert mod(length(normal_indices), NFACE) == 0

    normals = length(normals)>0 ? normals : nothing
    normal_indices = length(normal_indices)>0 ? normal_indices : nothing

    uvs = length(uvs)>0 ? uvs : nothing
    uv_indices = length(uv_indices)>0 ? uv_indices : nothing

    if NFACE == 3
        shapes = RayTracing.construct_triangle_mesh(
            sc,
            length(vertex_indices)÷3,
        
            vertices,
            vertex_indices,
        
            normals,
            normal_indices,
        
            uvs,
            uv_indices,
        
            alpha_mask
        )
    elseif NFACE == 4
        shapes = BilinearPatchGenerator(
            sc,
            length(vertex_indices) ÷ 4,

            vertices,
            vertex_indices,

            normals,
            normal_indices,

            uvs,
            uv_indices,

            alpha_mask
        )
    else
        @assert false
    end

    push!(FIN, shapes)
end

function parse_obj(
    file_path::AbstractString,
    object_to_world::RayTracing.Transformation, 
    reverse_orientation::Bool, 
    transform_swaps_handedness::Bool,
    alpha_mask::RayTracing.Maybe{RayTracing.AbstractTexture{Float64}},
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
        object_to_world,
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
			
            if cmd == "v"
                push!(vertices, parse_vertex(line))
            elseif cmd == "vt"
                push!(uvs, parse_uv(line))
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
