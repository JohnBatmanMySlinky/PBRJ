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


# medium is implicitly [0,1]^3
# medium_to_world = +3, +3, +3
# this places the medium in the scene


# world ray 
    # origin: -1, -1.5, -1.2
    # direction: 3,3,3 - origin

# if you intersect in world, they hit.
# apply world_to_medium to both. they hit.
    # however, you only apply world_to_medium to ray
    # unit cube is specified manually instead of by applying world_to_medium(medium.bounds)

    # now we are in unit cube space. 
    # now we normalize direction vector to work with nice t's
    # if we want to interact with NanoVDB we have to convert to NVDB space.
    # the UnitCube() above is really NanoVDB_to_unit_cube space and what we WOULD apply had we not 
        # manually specified [0,1]^3
    # so we should just apply Inv(UnitCube()) to ray to query nanovdb. 