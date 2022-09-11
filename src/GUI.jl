ENV["QSG_RENDER_LOOP"] = "basic"

using QML
using Qt5QuickControls2_jll

using FileIO
using Images

include("RayTracing.jl")

# render(
#     integrator(
#         camera,
#         sampler,
#         depth
#     ),
#     scene(
#         lights,
#         bvh
#     ),
#     minimal::bool
# )

function test_display(d::JuliaDisplay, LA_X::Int32, LA_Y::Int32, LA_Z::Int32, LF_X::Int32, LF_Y::Int32, LF_Z::Int32)
    status = RayTracing.RENDER(true, 1, 250, LA_X, LA_Y, LA_Z, LF_X, LF_Y, LF_Z)
    img = load(joinpath(dirname(@__FILE__), "yeehaw.png"))
    display(d, img)
end
@qmlfunction test_display

loadqml(joinpath(dirname(@__FILE__), "qml", "GUI.qml"))

exec()
