include("obj_parser2.jl")
using .OBJParser

# Parse an OBJ file
mesh = parse_obj("/Users/johnmyslinski/Documents/PBRJ/ref/lte-orb/mesh-0.obj")

# Get basic statistics
println("Vertices: ", get_vertex_count(mesh))
println("Faces: ", get_face_count(mesh))

# Access materials
for material in get_material_names(mesh)
    faces = get_faces_by_material(mesh, material)
    println("Material $material has $(length(faces)) faces")
end