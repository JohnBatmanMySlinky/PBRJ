import plyfile
from pathlib import Path
import os

for root, _, fnames in os.walk('/Users/johnmyslinski/Documents/pbrt-v3-scenes/barcelona-pavilion/geometry'):
    for fname in fnames:
        if fname.endswith(".ply"):
            path = Path(root, fname)
            data = plyfile.PlyData.read(path)
            data.text = True
            data.write(Path(root, fname.replace(".ply", "_ascii.ply")))

def convert_ply_to_obj(ply_file, obj_file):
    """
    Convert a PLY file to OBJ format, handling files with or without UV coordinates
    
    Args:
        ply_file (str): Path to the input PLY file
        obj_file (str): Path to the output OBJ file
    """
    # Lists to store vertex data and face data
    vertices = []  # (x, y, z)
    normals = []   # (nx, ny, nz)
    texcoords = [] # (u, v)
    faces = []
    
    # Properties tracking
    has_normals = False
    has_texcoords = False
    
    # Parse the header to identify available properties
    property_indices = {}
    current_property_index = 0
    
    # Read the PLY file
    with open(ply_file, 'r') as f:
        lines = f.readlines()
    
    # Parse header and data
    line_index = 0
    vertex_count = 0
    face_count = 0
    
    # First pass: analyze header
    while line_index < len(lines):
        line = lines[line_index].strip()
        line_index += 1
        
        if line.startswith("element vertex"):
            vertex_count = int(line.split()[-1])
        elif line.startswith("element face"):
            face_count = int(line.split()[-1])
        elif line.startswith("property") and "vertex" not in line:
            # Track property indices
            property_name = line.split()[-1]
            
            if property_name == "x" or property_name == "y" or property_name == "z":
                property_indices[property_name] = current_property_index
            elif property_name == "nx" or property_name == "ny" or property_name == "nz":
                property_indices[property_name] = current_property_index
                has_normals = True
            elif property_name == "u" or property_name == "s" or property_name == "v" or property_name == "t":
                property_indices[property_name] = current_property_index
                has_texcoords = True
                
            current_property_index += 1
        elif line == "end_header":
            break
    
    # Second pass: read vertex and face data
    for _ in range(vertex_count):
        if line_index >= len(lines):
            break
            
        line = lines[line_index].strip()
        line_index += 1
        values = line.split()
        
        # Extract vertex coordinates (always present)
        x = float(values[property_indices.get("x", 0)])
        y = float(values[property_indices.get("y", 1)])
        z = float(values[property_indices.get("z", 2)])
        vertices.append((x, y, z))
        
        # Extract normals if present
        if has_normals and "nx" in property_indices and "ny" in property_indices and "nz" in property_indices:
            nx = float(values[property_indices["nx"]])
            ny = float(values[property_indices["ny"]])
            nz = float(values[property_indices["nz"]])
            normals.append((nx, ny, nz))
        
        # Extract texture coordinates if present
        if has_texcoords:
            u_index = property_indices.get("u", property_indices.get("s", -1))
            v_index = property_indices.get("v", property_indices.get("t", -1))
            
            if u_index >= 0 and v_index >= 0 and u_index < len(values) and v_index < len(values):
                u = float(values[u_index])
                v = float(values[v_index])
                texcoords.append((u, v))
    
    # Read face data
    for _ in range(face_count):
        if line_index >= len(lines):
            break
            
        line = lines[line_index].strip()
        line_index += 1
        values = line.split()
        
        if len(values) >= 4:  # First value is count of vertices per face
            # PLY uses 0-based indices, OBJ uses 1-based
            face_indices = [int(idx) + 1 for idx in values[1:]]
            faces.append(face_indices)
    
    # Write to OBJ file
    with open(obj_file, 'w') as f:
        f.write("# Converted from PLY to OBJ\n")
        
        # Write vertices (always present)
        for v in vertices:
            f.write(f"v {v[0]} {v[1]} {v[2]}\n")
        
        # Write texture coordinates if present
        if has_texcoords:
            for vt in texcoords:
                f.write(f"vt {vt[0]} {vt[1]}\n")
        
        # Write normals if present
        if has_normals:
            for vn in normals:
                f.write(f"vn {vn[0]} {vn[1]} {vn[2]}\n")
        
        # Write faces
        for face in faces:
            if has_texcoords and has_normals:
                # Full data: v/vt/vn
                face_str = " ".join([f"{idx}/{idx}/{idx}" for idx in face])
            elif has_texcoords:
                # Vertex and texture: v/vt
                face_str = " ".join([f"{idx}/{idx}" for idx in face])
            elif has_normals:
                # Vertex and normal: v//vn
                face_str = " ".join([f"{idx}//{idx}" for idx in face])
            else:
                # Only vertex: v
                face_str = " ".join([f"{idx}" for idx in face])
            
            f.write(f"f {face_str}\n")


for root, _, fnames in os.walk('/Users/johnmyslinski/Documents/pbrt-v3-scenes/barcelona-pavilion/geometry'):
    for fname in fnames:
        if fname.endswith("_ascii.ply"):
            convert_ply_to_obj(Path(root, fname), Path(root, fname.replace(".ply", ".obj")))
