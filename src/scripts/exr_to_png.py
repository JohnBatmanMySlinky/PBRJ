#!/usr/bin/env python3
"""Convert all EXR files in PBRJ/renders to PNG (linear -> sRGB gamma)."""

import sys
import pathlib
import imageio.v2 as imageio
import numpy as np

renders = pathlib.Path(__file__).resolve().parents[2] / "renders"

exrs = sorted(renders.glob("*.exr"))
if not exrs:
    print(f"No EXR files found in {renders}")
    sys.exit(1)

for exr_path in exrs:
    png_path = exr_path.with_suffix(".png")
    try:
        img = imageio.imread(str(exr_path), format="EXR-FI")
        img = np.clip(img, 0, 1)
        img = np.power(img, 1.0 / 2.2)
        img = (img * 255).astype(np.uint8)
        imageio.imwrite(str(png_path), img)
        print(f"  {exr_path.name} -> {png_path.name}")
    except Exception as e:
        print(f"  FAILED {exr_path.name}: {e}")

print("Done.")
