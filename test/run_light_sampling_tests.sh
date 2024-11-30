julia -t 4 RayTracing.jl --scene-number 1 --image-dim 350 --samples-per-pixel 9 --file-name "ld-9-uniform.exr" --light-distribution uniform
convert ld-9-uniform.exr -set colorspace RGB -colorspace sRGB ld-9-uniform.png

julia -t 4 RayTracing.jl --scene-number 1 --image-dim 350 --samples-per-pixel 9 --file-name "ld-9-power.exr" --light-distribution power
convert ld-9-power.exr -set colorspace RGB -colorspace sRGB ld-9-power.png

julia -t 4 RayTracing.jl --scene-number 1 --image-dim 350 --samples-per-pixel 9 --file-name "ld-9-centroid-distance.exr" --light-distribution centroid_distance
convert ld-9-centroid-distance.exr -set colorspace RGB -colorspace sRGB ld-9-centroid-distance.png

julia -t 4 RayTracing.jl --scene-number 1 --image-dim 350 --samples-per-pixel 9 --file-name "ld-9-voxels-125.exr" --light-distribution spatial --n-voxels 125
convert ld-9-voxels-125.exr -set colorspace RGB -colorspace sRGB ld-9-voxels-125.png

julia -t 4 RayTracing.jl --scene-number 1 --image-dim 350 --samples-per-pixel 9 --file-name "ld-9-voxels-512.exr" --light-distribution spatial --n-voxels 512
convert ld-9-voxels-512.exr -set colorspace RGB -colorspace sRGB ld-9-voxels-512.png

julia -t 4 RayTracing.jl --scene-number 1 --image-dim 350 --samples-per-pixel 9 --file-name "ld-9-voxels-1000.exr" --light-distribution spatial --n-voxels 1000
convert ld-9-voxels-1000.exr -set colorspace RGB -colorspace sRGB ld-9-voxels-1000.png

julia -t 4 RayTracing.jl --scene-number 1 --image-dim 350 --samples-per-pixel 9 --file-name "ld-9-voxels-2197.exr" --light-distribution spatial --n-voxels 2197
convert ld-9-voxels-2197.exr -set colorspace RGB -colorspace sRGB ld-9-voxels-2197.png

nohup julia -t 4 RayTracing.jl --scene-number 1 --image-dim 350 --samples-per-pixel 1024 --file-name "ld-1024-power.exr" --light-distribution power > baseline_light_run.log 2>&1 &
echo $! > baseline_light_run.log
convert ld-1024-power.exr -set colorspace RGB -colorspace sRGB ld-1024-power.png