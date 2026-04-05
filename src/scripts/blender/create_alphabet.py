import bpy
import os

# Configuration
output_dir = "/Users/johnmyslinski/Documents/PBRJ/ref/alphabet"  # Change this to your desired output directory
font_size = 1.0
extrude_depth = 0.2

# Create output directory if it doesn't exist
os.makedirs(output_dir, exist_ok=True)

# Clear existing mesh objects
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)

def create_letter_obj(letter):
    """Create a 3D text object for a single letter and export as OBJ"""
    
    # Create text object
    bpy.ops.object.text_add(location=(0, 0, 0))
    text_obj = bpy.context.active_object
    text_obj.name = f"Letter_{letter}"
    
    # Set the text content
    text_obj.data.body = letter
    
    # Set text properties
    text_obj.data.size = font_size
    text_obj.data.extrude = extrude_depth
    text_obj.data.align_x = 'CENTER'
    text_obj.data.align_y = 'CENTER'
    
    # Convert text to mesh
    bpy.ops.object.convert(target='MESH')
    
    # Get bounding box dimensions
    bbox = text_obj.bound_box
    min_x = min([v[0] for v in bbox])
    max_x = max([v[0] for v in bbox])
    min_y = min([v[1] for v in bbox])
    max_y = max([v[1] for v in bbox])
    min_z = min([v[2] for v in bbox])
    max_z = max([v[2] for v in bbox])
    
    width = max_x - min_x
    height = max_y - min_y
    depth = max_z - min_z
    
    # Calculate scale factor to fit in 1x1x1 cube
    # Use the largest dimension to determine scale
    max_dim = max(width, height, depth)
    scale_factor = 1.0 / max_dim if max_dim > 0 else 1.0
    
    # Apply scale
    text_obj.scale = (scale_factor, scale_factor, scale_factor)
    bpy.ops.object.transform_apply(scale=True)
    
    # Center the object at origin
    bpy.ops.object.origin_set(type='ORIGIN_GEOMETRY', center='BOUNDS')
    text_obj.location = (0, 0, 0)
    
    # Select only this object
    bpy.ops.object.select_all(action='DESELECT')
    text_obj.select_set(True)
    bpy.context.view_layer.objects.active = text_obj
    
    # Export as OBJ
    obj_filepath = os.path.join(output_dir, f"{letter}.obj")
    bpy.ops.wm.obj_export(
        filepath=obj_filepath,
        export_selected_objects=True,
        export_triangulated_mesh=True,
        apply_modifiers=True,
        export_materials=False
    )
    
    print(f"Exported {letter} to {obj_filepath}")
    
    # Delete the object to prepare for next letter
    bpy.ops.object.delete(use_global=False)

# Generate all letters
for letter in "ABCDEFGHIJKLMNOPQRSTUVWXYZ":
    create_letter_obj(letter)

print(f"\nAll letters exported to: {output_dir}")