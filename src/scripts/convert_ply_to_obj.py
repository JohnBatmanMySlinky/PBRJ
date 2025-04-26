import bpy
import sys

argv = sys.argv

ply_file = argv[-2]
obj_file = argv[-1]

assert ply_file.endswith(".ply")
assert obj_file.endswith(".obj")

bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete()

bpy.ops.import_mesh.ply(filepath=ply_file)
bpy.ops.export_scene.obj(filepath=obj_file, axis_forward="Z", axis_up="Y")