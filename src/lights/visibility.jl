struct VisibilityTester
    p0::Interaction
    p1::Interaction
end

function unoccluded(vt::VisibilityTester, scene::BVHAccel)::Bool
    check = intersect_p(scene, spawn_ray_to(vt.p0, vt.p1))
    return !check
end

function tr(vt::VisibilityTester, scene::BVHAccel, sampler::AbstractSampler)::Spectrum
    ray = spawn_ray_to(vt.p0, vt.p1)
    Tr = spectrum_from_float(1.0)
    inv_w = spectrum_from_float(1.0)

    if length_squared(ray.direction) == 0
        return Tr
    end

    while true
        check, t, isect = intersect!(scene, ray, true)
        # Handle opaque surface along ray's path
        if check && !(isect.primitive.material isa Nothing)
            return spectrum_from_float(0.0)
        end

        if !(ray.medium isa Nothing)
            p_exit = at(ray, !(isect isa Nothing) ? isect.core.t : (1 - eps()))
            ray = set_direction(ray, Vec3(p_exit - ray.origin))

            u = get_1D!(sampler)
            T_maj = sampleT_maj!(ray, 1.0, u, sampler) do p, mp, sigma_maj, T_maj
                sigma_n = clamp.(sigma_maj - mp.sigma_a - mp.sigma_s, 0.0, typemax(Float64))

                # ratio-tracking: only evaluate null scattering
                pr = y_spectrum(T_maj) * y_spectrum(sigma_maj)
                Tr *= T_maj * sigma_n / pr
                inv_w *= T_maj * sigma_maj / pr

                if (is_black(Tr) || is_black(inv_w))
                    return false
                end

                return true
            end
            Tr *= T_maj / y_spectrum(T_maj)
            inv_w *= T_maj / y_spectrum(T_maj)
        end

        # Generate next ray segment or return final transmittance
        if isect isa Nothing
            break
        end
        ray = spawn_ray_to(isect.core, vt.p1)
    end
    return Tr / y_spectrum(inv_w)
end