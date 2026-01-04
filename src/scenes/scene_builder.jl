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
scene 8: an anemic leafless procedural tree ✅
    - add leaves
scene 9: lte orb ✅
    - julia -t auto RayTracing.jl --scene-number 9 --image-dim 500 500 --samples-per-pixel 16 --file-name "9-lte-orb.exr"
scene 10: a cloud + SimpleVolPathIntegrator (v3 GridMedium) ✅
    - julia -t auto RayTracing.jl --scene-number 10 --image-dim 500 500 --samples-per-pixel 256 --file-name "10-cloud.exr"
scene 11: dragon with fun materials ✅
    - julia -t auto RayTracing.jl --scene-number 11 --image-dim 500 500 --samples-per-pixel 16 --file-name "11-dragon.exr"
scene 12: v4 smoke plume (v4 GridMedium) ✅
    - julia -t auto RayTracing.jl --scene-number 12 --image-dim 500 500 --samples-per-pixel 16 --file-name "12-smoke-plume.exr"
scene 13: DISNEY CLOUD (v4 NanoVDBMedium) 🟨
    - re-render with screen fix
    - fix reflections from disk
    - caffeinate -di julia -t auto RayTracing.jl --scene-number 11 --image-dim 640 360 --samples-per-pixel 16 --file-name "13-disney-cloud.exr"
scene 14: Anemone (v4 GridMedium) 🟨
    - emmissive medium is only supported by VolPath (v4) integrator. 
    - Looks as good as it can with BDPT at the moment
scene 15: procedural clouds 🟨
    - something is fucky
scene 16: elevator hallway 🟨
    - floor bump map isn't work as expected....
    - wall material needs some work - how to get it more specular?
scene 17: barcelona pavillion 🟨
    - add background trees
    - remove fourier material convergence hack
scene 18: SDFs baby! 🟨
    - lighting kinda fucked
scene 19: bunny cloud (v4 NanoVDB) 🟨
    - only works single threaded? ok cool
    - hmmm gets all fucky when voxel grid is 3x3x3 - probably majorant iterator...
    - blue floor
scene 20: explosion + SimpleVolPathIntegrator (v4 NanoVDB) 🟨
    - caffeinate -di julia -t auto RayTracing.jl --scene-number 20 --image-dim 1000 1000 --samples-per-pixel 16
    - hmmmmm maybe black body is off?
scene 21: sanmiguel ✅
    - julia -t auto RayTracing.jl --scene-number 21 --image-dim 500 500 --crop-window 0.0 0.0 0.997245 0.745 --samples-per-pixel 16
    - check my bullshit mipmap hack
scene 99: sphere-a-mid 🟨
    - add more interesting materails
scene 100: Furry Bunny from pbrt-v4 🟨
    - fix HairBxDF
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
    - julia -t auto RayTracing.jl --scene-number 107 --image-dim 640 360 --samples-per-pixel 128
scene 108: spherical cow (sphere-packing algorithm)
    - sphere-packing algorithm. fill up ya meshes with spheres
    - julia -t auto RayTracing.jl --scene-number 108 --image-dim 500 500 --samples-per-pixel 64
scene 109: voxel cow (vozelization of meshes)
    - voxelize ya meshes. 
    - julia -t auto RayTracing.jl --scene-number 109 --image-dim 500 500 --samples-per-pixel 64
scene 110: floating lanterns
    - why does my bump mapping look fucked up???
    - julia -t auto RayTracing.jl --scene-number 110 --image-dim 1280 720 --samples-per-pixel 36 --crop-window 0.2 0.32 0.85 1.0 --file-name "110-floating_lanterns.exr"
"""

function build_scene(parsed_args::Dict)::Tuple{AbstractIntegrator, Scene}
    if parsed_args["scene-number"] == 1
        return make_scene1(parsed_args)
    elseif parsed_args["scene-number"] == 2
        return make_scene2(parsed_args)
    elseif parsed_args["scene-number"] == 3
        return make_scene3(parsed_args)
    elseif parsed_args["scene-number"] == 4
        return make_scene4(parsed_args)
    elseif parsed_args["scene-number"] == 5
        return make_scene5(parsed_args)
    elseif parsed_args["scene-number"] == 6
        return make_scene6(parsed_args)
    elseif parsed_args["scene-number"] == 7
        return make_scene7(parsed_args)
    elseif parsed_args["scene-number"] == 8
        return make_scene8(parsed_args)
    elseif parsed_args["scene-number"] == 9
        return make_scene9(parsed_args)
    elseif parsed_args["scene-number"] == 10
        return make_scene10(parsed_args)
    elseif parsed_args["scene-number"] == 11
        return make_scene11(parsed_args)
    elseif parsed_args["scene-number"] == 12
        return make_scene12(parsed_args)
    elseif parsed_args["scene-number"] == 13
        return make_scene13(parsed_args)
    elseif parsed_args["scene-number"] == 14
        return make_scene14(parsed_args)
    elseif parsed_args["scene-number"] == 15
        return make_scene15(parsed_args)
    elseif parsed_args["scene-number"] == 16
        return make_scene16(parsed_args)
    elseif parsed_args["scene-number"] == 17
        return make_scene17(parsed_args)
    elseif parsed_args["scene-number"] == 18
        return make_scene18(parsed_args)
    elseif parsed_args["scene-number"] == 19
        return make_scene19(parsed_args)
    elseif parsed_args["scene-number"] == 20
        return make_scene20(parsed_args)
    elseif parsed_args["scene-number"] == 21
        return make_scene21(parsed_args)
    elseif parsed_args["scene-number"] == 99
        return make_scene99(parsed_args)
    elseif parsed_args["scene-number"] == 100
        return make_scene100(parsed_args)
    elseif parsed_args["scene-number"] == 101
        return make_scene101(parsed_args)
    elseif parsed_args["scene-number"] == 102
        return make_scene102(parsed_args)
    elseif parsed_args["scene-number"] == 103
        return make_scene103(parsed_args)
    elseif parsed_args["scene-number"] == 104
        return make_scene104(parsed_args)
    elseif parsed_args["scene-number"] == 105
        return make_scene105(parsed_args)
    elseif parsed_args["scene-number"] == 106
        return make_scene106(parsed_args)
    elseif parsed_args["scene-number"] == 107
        return make_scene107(parsed_args)
    elseif parsed_args["scene-number"] == 108
        return make_scene108(parsed_args)
    elseif parsed_args["scene-number"] == 109
        return make_scene109(parsed_args)
    elseif parsed_args["scene-number"] == 110
        return make_scene110(parsed_args)
    else
        @assert false
    end
end