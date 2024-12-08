# Before

## Scene 4
johnmyslinski@Johns-MBP-2 src % julia -t 4 RayTracing.jl --image-dim 350 --samples-per-pixel 16 --scene-number 4 

There are 37 objects in the scene, building BVH
  0.021141 seconds (76.69 k allocations: 5.451 MiB, 99.24% compilation time)
Done building BVH
Using 16 samples per pixel
There are 2 lights in the scene
Rendering 484 tiles
Utilizing 4 threads

Progress: 100%|████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████| Time: 0:02:25
152.911429 seconds (4.79 G allocations: 410.866 GiB, 20.53% gc time, 14.95% compilation time)

## Scene 10
johnmyslinski@Johns-MBP-2 src % julia -t 4 RayTracing.jl --image-dim 350 --samples-per-pixel 16 --scene-number 10

There are 1 objects in the scene, building BVH
  0.003356 seconds (3.33 k allocations: 232.742 KiB, 98.11% compilation time)
Done building BVH
Using 16 samples per pixel
There are 1 lights in the scene
Rendering 484 tiles
Utilizing 4 threads

Progress: 100%|████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████| Time: 0:00:58
 68.147210 seconds (945.84 M allocations: 111.912 GiB, 12.12% gc time, 31.66% compilation time)