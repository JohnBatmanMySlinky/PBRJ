"""
scene 1: indoor office ✅
    - tweak area light material a bit
    - julia -t auto RayTracing.jl --scene-number 1 --image-dim 500 500 --samples-per-pixel 64 --file-name "1-office-scene.exr"
scene 2: caustic glass ✅
    - julia -t auto RayTracing.jl --scene-number 2 --image-dim 525 750 --samples-per-pixel 16 --file-name "2-caustic-glass.exr"
scene 3: AOIntegrator + dragon ✅
    - julia -t auto RayTracing.jl --scene-number 3 --image-dim 500 500 --samples-per-pixel 16 --file-name "3-ao-dragon.exr"
scene 4: cornell box 🟨
    - DEBUG: top back right coner - what's good with that???
    - colors look off?
    - need to mess with medium params to make it a bit less dense
    - julia -t auto RayTracing.jl --scene-number 4 --image-dim 500 500 --samples-per-pixel 16 --file-name "4-cornell-box.exr"
scene 5: soft bodies ✅
    - julia -t auto RayTracing.jl --scene-number 5 --image-dim 500 500 --samples-per-pixel 16 --file-name "5-soft-bodies.exr"
scene 6: goursat ✅
    - julia -t auto RayTracing.jl --scene-number 6 --image-dim 500 500 --samples-per-pixel 16 --file-name "6-goursat.exr"
    - better material? 
    - infinite light?
    - something fucky with the normals...
scene 7: julia logo w/ tea pots ✅
    - julia -t auto RayTracing.jl --scene-number 7 --image-dim 500 500 --samples-per-pixel 16 --file-name "7-julia-logo.exr"
scene 8: an anemic leafless procedural tree 🟨
    - add leaves
    - julia -t auto RayTracing.jl --scene-number 7 --image-dim 500 500 --samples-per-pixel 16 --file-name "8-anemic-tree.exr"
scene 9: lte orb ✅
    - julia -t auto RayTracing.jl --scene-number 9 --image-dim 500 500 --samples-per-pixel 16 --file-name "9-lte-orb.exr"
scene 10: a cloud + SimpleVolPathIntegrator (v3 GridMedium) ✅
    - julia -t auto RayTracing.jl --scene-number 10 --image-dim 500 500 --samples-per-pixel 256 --file-name "10-cloud.exr"
scene 11: dragon with fun materials ✅
    - julia -t auto RayTracing.jl --scene-number 11 --image-dim 500 500 --samples-per-pixel 16 --file-name "11-dragon.exr"
scene 12: v4 smoke plume (v4 GridMedium) ✅
    - julia -t auto RayTracing.jl --scene-number 12 --image-dim 500 500 --samples-per-pixel 16 --file-name "12-smoke-plume.exr"
scene 13: DISNEY CLOUD (v4 NanoVDBMedium) 🟨
    - why is it black!?!?!
    - caffeinate -di julia -t auto RayTracing.jl --scene-number 13 --image-dim 640 360 --samples-per-pixel 16 --file-name "13-disney-cloud.exr"
scene 14: Anemone (v4 GridMedium) 🟨
    - VolPathIntegratorv3 looking OK!!!!
    - caffeinate -di julia -t auto RayTracing.jl --scene-number 14 --image-dim 640 360 --samples-per-pixel 1024 --max-depth 30 --file-name "14-anemone.exr"
scene 15: procedural clouds 🟨
    - something is fucky
scene 16: elevator hallway 🟨
    - floor bump map isn't work as expected....
    - wall material needs some work - how to get it more specular?
    - crop window? screen? something fucky with camera.
    - julia -t auto RayTracing.jl --scene-number 16 --image-dim 640 360 --samples-per-pixel 16 --file-name "16-elevator-lobby.exr"
scene 17: barcelona pavillion 🟨
    - add background trees
    - remove fourier material convergence hack
    - caffeinate -di julia -t auto RayTracing.jl --scene-number 17 --image-dim 640 360 --samples-per-pixel 16 --file-name "17-barcelona-pavillion.exr"
scene 18: SDFs baby! 🟨
    - lighting kinda fucked
    - caffeinate -di julia -t auto RayTracing.jl --scene-number 18 --image-dim 640 360 --samples-per-pixel 16 --file-name "18-SDFs.exr"
scene 19: bunny cloud (v4 NanoVDB) 🟨
    - only works single threaded? ok cool
    - hmmm gets all fucky when voxel grid is 3x3x3 - probably majorant iterator...
    - blue floor
    - caffeinate -di julia -t 1 RayTracing.jl --scene-number 19 --image-dim 640 360 --samples-per-pixel 16 --file-name "19-bunny-cloud.exr"
scene 20: explosion + SimpleVolPathIntegrator (v4 NanoVDB) 🟨
    - caffeinate -di julia -t auto RayTracing.jl --scene-number 20 --image-dim 1000 1000 --samples-per-pixel 16 --file-name "20-explosion.exr"
    - hmmmmm maybe black body is off?
scene 21: sanmiguel ✅
    - julia -t auto RayTracing.jl --scene-number 21 --image-dim 500 500 --crop-window 0.0 0.0 0.997245 0.745 --samples-per-pixel 16 --file-name "21-san-miguel.exr"
    - check my bullshit mipmap hack
scene 21: ground explosion ✅
    - julia -t auto RayTracing.jl --scene-number 22 --image-dim 500 500 --samples-per-pixel 4 --file-name "22-ground-explosion.exr"
scene 99: sphere-a-mid 🟨
    - add more interesting materails
    - julia -t auto RayTracing.jl --scene-number 99 --image-dim 500 500 --samples-per-pixel 16 --file-name "99-sphere-a-mid.exr"
scene 100: Furry Bunny from pbrt-v4 ✅
    - julia -t auto RayTracing.jl --scene-number 100 --image-dim 500 500 --samples-per-pixel 16 --file-name "100-fuzzy-bunny.exr"
scene 101: SF3D CUP 🔴 (obj parser sucks)
scene 102: party blob ✅
    - see NB for animation 
scene 103: check board test
    - simple scene to test checker board pattern....
scene 104: emissive images testing
scene 105: his name is doug ✅
    - BSSRDF + VolPathIntegratorv3
    - julia -t auto RayTracing.jl --scene-number 105 --samples-per-pixel 256 --image-dim 640 360 --sampler zsobol --max-depth 2 --file-name "105-head.exr"
scene 106: fleshy dragon? ✅
    - BSSRDF + VolPathIntegratorv3
    - caffeinate -di julia -t auto RayTracing.jl --scene-number 106 --samples-per-pixel 64 --image-dim 683 512 --max-depth 3 --file-name "106-dragon_10.exr"
scene 107: train station
    - 3ds max 2011
    - julia -t auto RayTracing.jl --scene-number 107 --image-dim 640 360 --samples-per-pixel 128 --file-name "107-train-station.exr"
scene 108: spherical cow (sphere-packing algorithm)
    - sphere-packing algorithm. fill up ya meshes with spheres
    - julia -t auto RayTracing.jl --scene-number 108 --image-dim 500 500 --samples-per-pixel 64 --file-name "108-spherical-cow.exr"
scene 109: voxel cow (vozelization of meshes)
    - voxelize ya meshes. 
    - julia -t auto RayTracing.jl --scene-number 109 --image-dim 500 500 --samples-per-pixel 64 --filename "109-voxel-cow.exr"
scene 110: floating lanterns
    - why does my bump mapping look fucked up???
    - julia -t auto RayTracing.jl --scene-number 110 --image-dim 1280 720 --samples-per-pixel 36 --crop-window 0.2 0.32 0.85 1.0 --file-name "110-floating_lanterns.exr"
scene 111: RGB screen
    - mhmmm
scene 112: ocean n boat
    - julia -t auto RayTracing.jl --scene-number 112 --image-dim 500 500 --samples-per-pixel 16 --file-name "112-ocean-n-boat.exr"
scene 113: matchbulb
    - caffeinate -di julia -t 4 RayTracing.jl --scene-number 113 --image-dim 640 360 --samples-per-pixel 12 --file-name "113-matchbulb.exr"
scene 114: procedural city
    - caffeinate -di julia -t 4 RayTracing.jl --scene-number 114 --image-dim 640 360 --samples-per-pixel 12 --file-name "114-procedural_city.exr"
"""

const SCENE_BUILDERS = Dict{Int, Function}(
    1 => make_scene1,     2 => make_scene2,     3 => make_scene3,
    4 => make_scene4,     5 => make_scene5,     6 => make_scene6,
    7 => make_scene7,     8 => make_scene8,     9 => make_scene9,
    10 => make_scene10,   11 => make_scene11,   12 => make_scene12,
    13 => make_scene13,   14 => make_scene14,   15 => make_scene15,
    16 => make_scene16,   17 => make_scene17,   18 => make_scene18,
    19 => make_scene19,   20 => make_scene20,   21 => make_scene21,
    22 => make_scene22,   23 => make_scene23,
    99 => make_scene99,   100 => make_scene100,  101 => make_scene101,
    102 => make_scene102, 103 => make_scene103,  104 => make_scene104,
    105 => make_scene105, 106 => make_scene106,  107 => make_scene107,
    108 => make_scene108, 109 => make_scene109,  110 => make_scene110,
    111 => make_scene111, 112 => make_scene112,  113 => make_scene113,
    114 => make_scene114,
)

function build_scene(parsed_args::Dict)::Tuple{AbstractIntegrator, Scene}
    scene_number = parsed_args["scene-number"]
    builder = Base.get(SCENE_BUILDERS, scene_number, nothing)
    isnothing(builder) && error("no scene builder registered for scene-number $scene_number")
    return builder(parsed_args)
end