import plyfile
from pathlib import Path
import os

# PATH = '/Users/johnmyslinski/Documents/pbrt-v3-scenes/sanmiguel/geometry'
# PATH = "/home/jmyslinski/random_stuff/pbrt-v3-scenes/sanmiguel/geometry/"
# PATH = "/Users/johnmyslinski/Documents/PBRJ/ref/caustic-glass/geometry/"
# PATH = "/home/jmyslinski/random_stuff/pbrt-v3-scenes/dragon/geometry/"
# PATH = "/home/jmyslinski/random_stuff/pbrt-v4-scenes/lte-orb/geometry/"
# PATH = "/home/jmyslinski/random_stuff/pbrt-v3-scenes/head/geometry/"
# PATH = "/Users/johnmyslinski/Documents/pbrt-v3-scenes/head/geometry/"
PATH = "/Users/johnmyslinski/Documents/PBRJ/ref"

# Convert binary PLY to ASCII PLY
for root, _, fnames in os.walk(PATH):
    for fname in fnames:
        if fname.endswith(".ply") and "ascii" not in fname and "bannister" in fname:
            path = Path(root, fname)
            new_fname = fname.replace(".ply", "_ascii.ply")
            if new_fname not in fnames: 
                print(f"converting to ascii: {fname}")
                data = plyfile.PlyData.read(path)
                data.text = True
                data.write(Path(root, new_fname))
                print(f"wrote: {new_fname}")
            else:
                print(f"ascii file already exists: {new_fname}")

def convert_ply_to_obj(ply_file, obj_file):
    """
    Convert a PLY file to OBJ format, handling files with or without UV coordinates
    and face normals embedded in face data
    
    Args:
        ply_file (str): Path to the input PLY file
        obj_file (str): Path to the output OBJ file
    """
    # Lists to store vertex data and face data
    vertices = []  # (x, y, z)
    vertex_normals = []   # (nx, ny, nz) - per vertex
    texcoords = [] # (u, v)
    faces = []
    face_normals = []  # (nx, ny, nz) - per face
    
    # Properties tracking
    has_vertex_normals = False
    has_texcoords = False
    has_face_normals = False
    
    # Parse the header to identify available properties
    vertex_property_indices = {}
    face_property_indices = {}
    current_vertex_property_index = 0
    current_face_property_index = 0
    
    # Read the PLY file
    with open(ply_file, 'r') as f:
        lines = f.readlines()
    
    # Parse header and data
    line_index = 0
    vertex_count = 0
    face_count = 0
    in_vertex_properties = False
    in_face_properties = False
    
    # First pass: analyze header
    while line_index < len(lines):
        line = lines[line_index].strip()
        line_index += 1
        
        if line.startswith("element vertex"):
            vertex_count = int(line.split()[-1])
            in_vertex_properties = True
            in_face_properties = False
            current_vertex_property_index = 0
        elif line.startswith("element face"):
            face_count = int(line.split()[-1])
            in_vertex_properties = False
            in_face_properties = True
            current_face_property_index = 0
        elif line.startswith("property") and in_vertex_properties:
            # Track vertex property indices
            parts = line.split()
            property_name = parts[-1]
            
            if property_name in ["x", "y", "z"]:
                vertex_property_indices[property_name] = current_vertex_property_index
            elif property_name in ["nx", "ny", "nz"]:
                vertex_property_indices[property_name] = current_vertex_property_index
                has_vertex_normals = True
            elif property_name in ["u", "s", "v", "t"]:
                vertex_property_indices[property_name] = current_vertex_property_index
                has_texcoords = True
                
            current_vertex_property_index += 1
        elif line.startswith("property") and in_face_properties:
            # Check if face has normal properties (less common)
            parts = line.split()
            if len(parts) > 2 and parts[1] == "list":
                # This is the vertex_indices property (list format)
                continue
            else:
                # Individual face properties like normals
                property_name = parts[-1]
                if property_name in ["nx", "ny", "nz"]:
                    face_property_indices[property_name] = current_face_property_index
                    has_face_normals = True
                current_face_property_index += 1
        elif line == "end_header":
            break
    
    # Second pass: read vertex data
    for _ in range(vertex_count):
        if line_index >= len(lines):
            break
            
        line = lines[line_index].strip()
        line_index += 1
        values = line.split()
        
        # Extract vertex coordinates (always present)
        x = float(values[vertex_property_indices.get("x", 0)])
        y = float(values[vertex_property_indices.get("y", 1)])
        z = float(values[vertex_property_indices.get("z", 2)])
        vertices.append((x, y, z))
        
        # Extract vertex normals if present
        if has_vertex_normals and all(key in vertex_property_indices for key in ["nx", "ny", "nz"]):
            nx = float(values[vertex_property_indices["nx"]])
            ny = float(values[vertex_property_indices["ny"]])
            nz = float(values[vertex_property_indices["nz"]])
            vertex_normals.append((nx, ny, nz))
        
        # Extract texture coordinates if present
        if has_texcoords:
            u_index = vertex_property_indices.get("u", vertex_property_indices.get("s", -1))
            v_index = vertex_property_indices.get("v", vertex_property_indices.get("t", -1))
            
            if u_index >= 0 and v_index >= 0 and u_index < len(values) and v_index < len(values):
                u = float(values[u_index])
                v = float(values[v_index])
                texcoords.append((u, v))
    
    # Third pass: read face data
    for _ in range(face_count):
        if line_index >= len(lines):
            break
            
        line = lines[line_index].strip()
        line_index += 1
        values = line.split()
        
        if len(values) >= 4:  # First value is count of vertices per face
            vertex_count_in_face = int(values[0])
            
            # Extract vertex indices
            face_indices = []
            for i in range(1, vertex_count_in_face + 1):
                if i < len(values):
                    # PLY uses 0-based indices, OBJ uses 1-based
                    face_indices.append(int(values[i]) + 1)
            
            faces.append(face_indices)
            
            # Check if there are additional values after vertex indices (likely face normals)
            remaining_values = values[vertex_count_in_face + 1:]
            if len(remaining_values) >= 3:
                # Assume these are face normals
                try:
                    nx = float(remaining_values[0])
                    ny = float(remaining_values[1])
                    nz = float(remaining_values[2])
                    face_normals.append((nx, ny, nz))
                    has_face_normals = True
                except ValueError:
                    # Not valid floats, skip
                    pass
    
    # Write to OBJ file
    with open(obj_file, 'w') as f:
        f.write("# Converted from PLY to OBJ\n")
        f.write(f"# Vertices: {len(vertices)}, Faces: {len(faces)}\n")
        
        # Write vertices (always present)
        for v in vertices:
            f.write(f"v {v[0]} {v[1]} {v[2]}\n")
        
        # Write texture coordinates if present
        if has_texcoords and texcoords:
            for vt in texcoords:
                f.write(f"vt {vt[0]} {vt[1]}\n")
        
        # Write vertex normals if present
        if has_vertex_normals and vertex_normals:
            for vn in vertex_normals:
                f.write(f"vn {vn[0]} {vn[1]} {vn[2]}\n")
        
        # If we have face normals but no vertex normals, we need to handle this differently
        # For now, we'll just use the vertex indices without normals
        # (OBJ format doesn't directly support per-face normals the way PLY does)
        
        # Write faces
        for i, face in enumerate(faces):
            if has_texcoords and has_vertex_normals and texcoords and vertex_normals:
                # Full data: v/vt/vn
                face_str = " ".join([f"{idx}/{idx}/{idx}" for idx in face])
            elif has_texcoords and texcoords:
                # Vertex and texture: v/vt
                face_str = " ".join([f"{idx}/{idx}" for idx in face])
            elif has_vertex_normals and vertex_normals:
                # Vertex and normal: v//vn
                face_str = " ".join([f"{idx}//{idx}" for idx in face])
            else:
                # Only vertex: v
                face_str = " ".join([f"{idx}" for idx in face])
            
            f.write(f"f {face_str}\n")
        
        # If we have face normals, add them as comments for reference
        if has_face_normals and face_normals:
            f.write("\n# Face normals (as comments, OBJ doesn't support per-face normals directly):\n")
            for i, fn in enumerate(face_normals):
                f.write(f"# Face {i+1} normal: {fn[0]} {fn[1]} {fn[2]}\n")

    print(f"Converted {ply_file} to {obj_file}")
    print(f"  Vertices: {len(vertices)}")
    print(f"  Faces: {len(faces)}")
    print(f"  Has vertex normals: {has_vertex_normals and len(vertex_normals) > 0}")
    print(f"  Has face normals: {has_face_normals and len(face_normals) > 0}")
    print(f"  Has texture coords: {has_texcoords and len(texcoords) > 0}")

# Convert all ASCII PLY files to OBJ
for root, _, fnames in os.walk(PATH):
    for fname in fnames:
        if fname.endswith("_ascii.ply"):
            if fname.replace("_ascii.ply", "_ascii.obj") not in fnames:
                ply_path = Path(root, fname)
                obj_path = Path(root, fname.replace("_ascii.ply", "_ascii.obj"))
                print(f"converting {fname} to obj")
                convert_ply_to_obj(ply_path, obj_path)
            else:
                print(f"Skipping {fname} because obj already exists")