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
world_bounds = RayTracing.Bounds3(
    RayTracing.Pnt3(a, b, c),
    RayTracing.Pnt3(d, e, f)
)
ray_from = RayTracing.Pnt3(-310, -311, -312)
ray_at = RayTracing.Pnt3(5, 5, 5)
world_ray = RayTracing.Ray(
    ray_from,
    RayTracing.Vec3(ray_at - ray_from) .* .0001,
    0.0, 
    typemax(Float64),
    nothing
)
world_hit, world_tmin, world_tmax = RayTracing.intersect_p(world_bounds, world_ray)
print(">>>>>WORLD SPACE<<<<<\n\tBounds: ($(world_bounds.pMin), $(world_bounds.pMax))\n\tRay: $(world_ray)\n\tWorld Intersection: $(world_hit), $(world_tmin), $(world_tmax), $(RayTracing.at(world_ray, world_tmin))\n")


unit_transform = UnitCube(world_bounds)
unit_bounds = unit_transform(world_bounds)
unit_ray = unit_transform(world_ray)
unit_hit, unit_tmin, unit_tmax = RayTracing.intersect_p(unit_bounds, unit_ray)
print(">>>>>UNIT SPACE<<<<<\n\tBounds: ($(unit_bounds.pMin), $(unit_bounds.pMax))\n\tRay: $(unit_ray)\n\tUnit Intersection: $(unit_hit), $(unit_tmin), $(unit_tmax), $(RayTracing.at(unit_ray, unit_tmin))\n\tWorld Intersection: $(RayTracing.Inv(unit_transform)(RayTracing.at(unit_ray, unit_tmin)))\n")

unit_ray_norm = unit_transform(world_ray)
unit_ray_norm.direction = RayTracing.normalize(unit_ray_norm.direction)
unit_hit_norm, unit_tmin_norm, unit_tmax_norm = RayTracing.intersect_p(unit_bounds, unit_ray_norm)
print(">>>>>UNIT (norm ray dir vec) SPACE<<<<<\n\tBounds: ($(unit_bounds.pMin), $(unit_bounds.pMax))\n\tRay: $(unit_ray_norm)\n\tWorld Intersection: $(unit_hit_norm), $(unit_tmin_norm), $(unit_tmax_norm)\n")

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





"""
Ray Entering:
    o = [-0.567131519, -0.144239023, -1.16352522]
    d = [0.437237144, 0.849456966, 0.295375347]
    time=0.5, tMax=2.8

Ray Transformed:
    o = [0.213570058, -0.0778982118, 0.0339424647]
    d = [0.220826834, 0.429018646, 0.378686309]
    time=0, tMax=2.8

tMin, tMax = 0.181573, 2.51248

final t? = 0.618256

where the fuck is this point?
[ -0.296806902, 0.38094312, -0.980907559 ]
"""