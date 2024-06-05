include("../../src/RayTracing.jl")

function UnitCube(b::RayTracing.Bounds3)::RayTracing.Transformation
    scale = RayTracing.Scale(RayTracing.Vec3(
        1.0 ./ (b.pMin - b.pMax)
    ))
    translate = RayTracing.Translate(RayTracing.Pnt3(
        -scale(b).pMin
    ))
    return translate * scale
end

fpath = "/Users/johnmyslinski/Documents/pbrt-v4-scenes/disney-cloud/wdas_cloud_quarter.nvdb"
density_float_grid = RayTracing.NanoVDB.make_NanoVDBWrapper(fpath)

########################
## Bounding Box Stuff ##
########################

a, b, c, d, e, f = RayTracing.NanoVDB.get_WorldBBox(density_float_grid)
old_bounds = RayTracing.Bounds3(
    RayTracing.Pnt3(a, b, c),
    RayTracing.Pnt3(d, e, f)
)
mi = minimum(old_bounds.pMin)
ma = maximum(old_bounds.pMax)
new_bounds = RayTracing.Bounds3(
    RayTracing.Pnt3(mi, mi, mi),
    RayTracing.Pnt3(ma, ma, ma)
)
unit_cube_transform = UnitCube(new_bounds)
tra_bounds = unit_cube_transform(new_bounds)
fin_bounds = RayTracing.Inv(unit_cube_transform)(tra_bounds)
print("World Bounds Orig: ($(old_bounds.pMin), $(old_bounds.pMax))\n")
print("World Bounds Even'd: ($(new_bounds.pMin), $(new_bounds.pMax))\n")
print("World Bounds Unit'd: ($(tra_bounds.pMin), $(tra_bounds.pMax))\n")
print("World Bounds Back: ($(fin_bounds.pMin), $(fin_bounds.pMax))\n")