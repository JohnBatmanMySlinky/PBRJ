include("../RayTracing.jl")

function run()::Bool
    mat_curves = RayTracing.Matte(            
        RayTracing.ConstantTexture(RayTracing.spectrum_from_float(0.15, 0.21, 1.0)),
        RayTracing.ConstantTexture(RayTracing.spectrum_from_float(0.0, 0.0, 0.0)),
        nothing
    )

    curves_t = RayTracing.Inv(RayTracing.Translate(RayTracing.Pnt3(0,2,5))) * RayTracing.Translate(RayTracing.Pnt3(.15, -.03, 0)) * RayTracing.Scale(7.0, 7.0, 7.0)
    fur_shape_core = RayTracing.ShapeCore(
        curves_t,
        RayTracing.Inv(curves_t),
        false,
        false
    )

    @time curves = RayTracing.parse_curves(
        RayTracing.jmfp("/home/jmyslinski/random_stuff/pbrt-v4-scenes/bunny-fur/geometry/bunny-fur-curves.pbrt"),
        fur_shape_core 
    )

    primitives = RayTracing.Primitive[]
    for curve in curves
        push!(primitives, RayTracing.Primitive(curve, mat_curves, nothing))
    end

    @time bvh = RayTracing.BVH(primitives)

    o = RayTracing.Pnt3(2.451949, -1.669419, -11.742881)
    d = RayTracing.Vec3( -0.37262046, 0.024686506, 0.92765534)
    r = RayTracing.Ray(
        o,
        d,
        0.0,
        typemax(Float64)
    )

    check, t, inter = RayTracing.intersect!(bvh, r)

    println("check: $check")
    println("t: $t")
    println("interaction: $inter")
    return true
end

run()