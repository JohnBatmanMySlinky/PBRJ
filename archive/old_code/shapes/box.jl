function Box(p0::Vec3, p1::Vec3, material::Material)::BVHNode

    for i = 1:3
        if p0[i] >= p1[i]
            error("bound erorr")
        end
    end


    stuff = Hittable[]

    # XYs
    push!(stuff, XYRectangle(p0[1], p1[1], p0[2], p1[2], p1[3], material))
    push!(stuff, XYRectangle(p0[1], p1[1], p0[2], p1[2], p0[3], material))

    # XZs
    push!(stuff, XZRectangle(p0[1], p1[1], p0[3], p1[3], p1[2], material))
    push!(stuff, XZRectangle(p0[1], p1[1], p0[3], p1[3], p0[2], material))

    # YZs
    push!(stuff, YZRectangle(p0[2], p1[2], p0[3], p1[3], p1[1], material))
    push!(stuff, YZRectangle(p0[2], p1[2], p0[3], p1[3], p0[1], material))

    return construct_bvh(HittableList(stuff), 0.0, 1.0)
end