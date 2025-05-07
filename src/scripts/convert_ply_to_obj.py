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