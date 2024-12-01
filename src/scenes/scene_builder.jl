"""
scene 1: indoor office ✅
scene 2: caustic glass 🟨
scene 3: AOIntegrator + dragon ✅
scene 4: cornell box ✅
scene 5: soft bodies ✅
scene 6: goursat ✅
scene 7: julia logo ✅
scene 8: an anemic leafless procedural tree ✅
scene 9: a broken ass orb 🔴 (obj parser sucks)
scene 10: a cloud ✅
scene 11: infinite light show off & material testing ✅
scene 12: DISNEY CLOUD GRID! ✅
scene 13: DISNEY CLOUD ✅
scene 14: elevator hallway 🟨
scene 99: sphere-a-mid 🟨 (it works just not complete yet) (TODO: infinite uniform light, bilinear patch, and more interesting materials)
scene 100: Furry Bunny from pbrt-v4 ✅ (just dont use HairBSDF)
scene 101: SF3D CUP 🔴 (obj parser sucks)
"""

function build_scene(parsed_args::Dict)::Tuple{AbstractIntegrator, Scene}
    if parsed_args["scene-number"] == 1
        return make_scene1()
    elseif parsed_args["scene-number"] == 2
        return make_scene2()
    elseif parsed_args["scene-number"] == 3
        return make_scene3()
    elseif parsed_args["scene-number"] == 4
        return make_scene4()
    elseif parsed_args["scene-number"] == 5
        return make_scene5()
    elseif parsed_args["scene-number"] == 6
        return make_scene6()
    elseif parsed_args["scene-number"] == 7
        return make_scene7()
    elseif parsed_args["scene-number"] == 8
        return make_scene8()
    elseif parsed_args["scene-number"] == 9
        return make_scene9()
    elseif parsed_args["scene-number"] == 10
        return make_scene10()
    elseif parsed_args["scene-number"] == 11
        return make_scene11()
    elseif parsed_args["scene-number"] == 12
        return make_scene12()
    elseif parsed_args["scene-number"] == 13
        return make_scene13()
    elseif parsed_args["scene-number"] == 14
        return make_scene14()
    elseif parsed_args["scene-number"] == 99
        return make_scene99()
    elseif parsed_args["scene-number"] == 100
        return make_scene100()
    elseif parsed_args["scene-number"] == 101
        return make_scene101()
    else
        @assert false
    end
end