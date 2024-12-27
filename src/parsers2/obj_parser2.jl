module OBJParser

mutable struct Vertex
    x::Float64
    y::Float64
    z::Float64
end

struct TextureCoord
    u::Float64
    v::Float64
end

struct Normal
    x::Float64
    y::Float64
    z::Float64
end

struct Face
    vertex_indices::Vector{Int}
    texture_indices::Vector{Int}
    normal_indices::Vector{Int}
end

mutable struct Material
    name::String
    ambient::Vector{Float64}
    diffuse::Vector{Float64}
    specular::Vector{Float64}
    alpha::Float64
end

mutable struct OBJMesh
    vertices::Vector{Vertex}
    texture_coords::Vector{TextureCoord}
    normals::Vector{Normal}
    faces::Vector{Face}
    materials::Dict{String, Material}
    current_material::String
end

function OBJMesh()
    OBJMesh(
        Vertex[], 
        TextureCoord[], 
        Normal[], 
        Face[],
        Dict{String, Material}(),
        ""
    )
end

function parse_vertex(line::AbstractString)::Vertex
    parts = split(strip(line))[2:end]
    if length(parts) < 3
        throw(ArgumentError("Invalid vertex format: $line"))
    end
    Vertex(parse.(Float64, parts[1:3])...)
end

function parse_texture(line::AbstractString)::TextureCoord
    parts = split(strip(line))[2:end]
    if length(parts) < 2
        throw(ArgumentError("Invalid texture coordinate format: $line"))
    end
    TextureCoord(parse.(Float64, parts[1:2])...)
end

function parse_normal(line::AbstractString)::Normal
    parts = split(strip(line))[2:end]
    if length(parts) < 3
        throw(ArgumentError("Invalid normal format: $line"))
    end
    Normal(parse.(Float64, parts[1:3])...)
end

function parse_face(line::AbstractString)::Face
    parts = split(strip(line))[2:end]
    vertex_indices = Int[]
    texture_indices = Int[]
    normal_indices = Int[]
    
    for part in parts
        indices = split(part, "/")
        push!(vertex_indices, parse(Int, indices[1]))
        
        if length(indices) > 1 && indices[2] != ""
            push!(texture_indices, parse(Int, indices[2]))
        end
        
        if length(indices) > 2 && indices[3] != ""
            push!(normal_indices, parse(Int, indices[3]))
        end
    end
    
    Face(vertex_indices, texture_indices, normal_indices)
end

function parse_material(mtl_path::AbstractString)::Dict{String, Material}
    materials = Dict{String, Material}()
    current_material = nothing
    
    open(mtl_path) do file
        for line in eachline(file)
            line = strip(line)
            if isempty(line) || startswith(line, "#")
                continue
            end
            
            parts = split(line)
            cmd = parts[1]
            
            if cmd == "newmtl"
                name = join(parts[2:end], " ")
                current_material = Material(
                    name,
                    [0.0, 0.0, 0.0],  # ambient
                    [0.0, 0.0, 0.0],  # diffuse
                    [0.0, 0.0, 0.0],  # specular
                    1.0               # alpha
                )
                materials[name] = current_material
            elseif !isnothing(current_material)
                if cmd == "Ka"  # ambient
                    current_material.ambient .= parse.(Float64, parts[2:4])
                elseif cmd == "Kd"  # diffuse
                    current_material.diffuse .= parse.(Float64, parts[2:4])
                elseif cmd == "Ks"  # specular
                    current_material.specular .= parse.(Float64, parts[2:4])
                elseif cmd == "d" || cmd == "Tr"  # transparency
                    current_material.alpha = parse(Float64, parts[2])
                end
            end
        end
    end
    
    materials
end

function parse_obj(file_path::AbstractString)::OBJMesh
    mesh = OBJMesh()
    
    open(file_path) do file
        for line in eachline(file)
            line = strip(line)
            if isempty(line) || startswith(line, "#")
                continue
            end
            
            parts = split(line)
            cmd = parts[1]
            
            try
                if cmd == "v"
                    push!(mesh.vertices, parse_vertex(line))
                elseif cmd == "vt"
                    push!(mesh.texture_coords, parse_texture(line))
                elseif cmd == "vn"
                    push!(mesh.normals, parse_normal(line))
                elseif cmd == "f"
                    push!(mesh.faces, parse_face(line))
                elseif cmd == "mtllib"
                    mtl_path = joinpath(dirname(file_path), parts[2])
                    mesh.materials = parse_material(mtl_path)
                elseif cmd == "usemtl"
                    mesh.current_material = join(parts[2:end], " ")
                end
            catch e
                @warn "Error parsing line: $line"
                @warn "Error: $e"
            end
        end
    end
    
    mesh
end

function get_vertex_count(mesh::OBJMesh)::Int
    length(mesh.vertices)
end

function get_face_count(mesh::OBJMesh)::Int
    length(mesh.faces)
end

function get_material_names(mesh::OBJMesh)::Vector{String}
    collect(keys(mesh.materials))
end

function get_faces_by_material(mesh::OBJMesh, material_name::String)::Vector{Face}
    filter(face -> mesh.current_material == material_name, mesh.faces)
end

export OBJMesh, parse_obj, get_vertex_count, get_face_count, 
       get_material_names, get_faces_by_material

end # module