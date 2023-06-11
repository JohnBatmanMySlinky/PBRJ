struct VisibilityTester
    p0::Interaction
    p1::Interaction
end

function unoccluded(vt::VisibilityTester, scene::BVHAccel)::Bool
    check = intersect_p(scene, spawn_shadow_ray(vt.p0, vt.p1))
    return !check
end

function tr(vt::VisibilityTester, scene::BVHAccel, sampler::AbstractSampler)::Spectrum
    ray = spawn_shadow_ray(vt.p0, vt.p1)
    Tr = spectrum_from_float(1.0)
    while true
        check, t, isect = intersect!(scene, ray)
        if check && !(isect.primitive.material isa Nothing)
            return spectrum_from_float(0.0)
        end

        # JOHN HACK: skipping medium check

        if !check
            break
        end
        ray = spawn_ray(isect, p1)
    end
    return Tr
end