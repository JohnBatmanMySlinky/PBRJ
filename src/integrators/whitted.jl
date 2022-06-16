struct WhittedIntegrator <: Integrator
    max_depth::Int64
end

function (i::WhittedIntegrator)(ray::Ray, world::Hittable, lights::Hittable)
    L = Vec3(0, 0, 0)

    # find closest intersection
    hit_check, hit_record = hit(world, r, .0001, typemax(Float64))

    # if no intersection, 
    if hit == false
        for light in lights.list
            L += le(light, ray)
        end
        # return background radiance
        # because ray can't miss infinite env light
        return L
    end

    # shading vs geometric normal
    n = hit_record.normal
    wo = something

    # compute scattering function for surface interaction


    # if no bsdf, spawn new ray and recurse
    if hit_record.bsdf isa Nothing
        return li(
            spawn
        )
    end

    # if the light ray hit a light, add in emitted light
    L += le(hit_record, wo)

    # add contribution of each light source
    for light in lights.list
        # sample light
        # if unoccluded
        L += f * sampled_li * abs(dot(wi, n)) / pdf
    end

    if depth + 1 <= i.max_depth
        L += specular_reflect()
        L += specular_transmit()
    end
    return L
end