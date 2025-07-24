"""
scene 1: indoor office ✅
    - add geometry
scene 2: caustic glass 🟨
    - https://www.pbrt.org/scenes-v3_images/f16-9c.jpg
    - black lines in glass are missing in mine
    - fov and dimensions are differnet
scene 3: AOIntegrator + dragon ✅
scene 4: cornell box ✅
    - need to mess with medium params to make it a bit less dense
scene 5: soft bodies ✅
    - better material? 
    - infinite light?
scene 6: goursat ✅🟨
    - better material? 
    - infinite light?
    - something fucky with the normals...
scene 7: julia logo w/ tea pots ✅🟨
    - more interesting floor. maybe water???
scene 8: an anemic leafless procedural tree ✅🟨
    - add leaves
scene 9: lte orb ✅🟨
    - get more interesting measured bsdf's
scene 10: a cloud + SimpleVolPathIntegrator (v3 GridMedium) ✅🟨
    - parser broken
scene 11: dragon with fun materials ✅🟨
scene 12: v4 smoke plume (v4 GridMedium) ✅🟨
scene 13: DISNEY CLOUD (v4 NanoVDBMedium) ✅🟨
scene 14: Anemone (v4 GridMedium) 🟨🟨
scene 15: procedural clouds 🟨🟨
scene 16: elevator hallway 🟨🟨
scene 17: barcelona pavillion 🟨🟨
    - add background trees
    - remove fourier material convergence hack
scene 18: SDFs baby! 🟨🟨
    - lighting kinda fucked
scene 19: bunny cloud (v4 NanoVDB) ✅🟨
    - only works single threaded? ok cool
    - hmmm gets all fucky when voxel grid is 3x3x3 - probably majorant iterator...
scene 20: explosion + SimpleVolPathIntegrator (v4 NanoVDB) 🟨🟨
    - caffeinate -di julia -t 4 RayTracing.jl --scene-number 20 --image-dim 1000 1000 --samples-per-pixel 16
    - hmmmmm maybe black body is off?
scene 21: sanmiguel ✅
    - julia -t 4 RayTracing.jl --scene-number 21 --image-dim 500 500 --crop-window 0.0 0.0 0.997245 0.745 --samples-per-pixel 16
    - check my bullshit mipmap hack
scene 99: sphere-a-mid 🟨🟨
    - add more interesting materails
scene 100: Furry Bunny from pbrt-v4 🟨🟨
    - fix HairBxDF
scene 101: SF3D CUP 🔴🟨 (obj parser sucks)
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
    else
        @assert false
    end
end