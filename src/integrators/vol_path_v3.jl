struct VolPathIntegrator <: AbstractIntegrator
    camera::C where C <: Camera
    sampler::S where S <: AbstractSampler
    max_depth::Int64
end

function li(vp::VolPathIntegrator, ray::AbstractRay, scene::Scene, depth::Int64, sampler::AbstractSampler)::Spectrum
    # declare local variables for delta tracking integration
    LL = spectrum_from_float(0.0)
    beta = 1.0
    depth = 0
    specularBounce = false
    eta_scale = 1.0

    # terminate secondary wavelengths before starting random walk
    # JOHN HACK SKIP

    while true
        # estimate radiance for ray path using delta tracking
        check, t, si = intersect!(scene.b, ray)
        scattered = false
        terminated = false

        if !(ray.medium isa Nothing)
            t_max = (t isa Nothing) ? typemax(Float64) : t
            u = get_1D!(sampler)
            u_mode = get_1D!(sampler)

            # stepping inside SampleT_maj
            # Normalize ray direction and update _tMax_ accordingly
            t_max *= length_pbrt(ray.direction)
            ray.direction = normalize(ray.direction)

            # Use sampleT_maj! with do block
            T_maj = sampleT_maj!(ray, t_max, u, sampler) do p, mp, sigma_maj, T_maj
                # computer medium event probabilities for interaction
                p_absorb = mp.sigma_a[0+1] / sigma_maj[0+1]
                p_scatter = mp.sigma_s[0+1] / sigma_maj[0+1]
                p_null = max(0.0, 1.0 - p_absorb - p_scatter)

                # randomly sample medium scattering event for delta tracking
                callback_mode, _, _ = sample_discrete(Distribution1D([p_absorb, p_scatter, p_null]), u_mode)
                
                if callback_mode == 0+1
                    # handle absorption event for medium sample
                    LL += beta * mp.Le
                    terminated = true
                    return false
                elseif callback_mode == 1+1
                    # handle regular scattering event for medium sample
                    # stop sampling if maximum depth has been reached
                    depth += 1
                    if depth >= vp.max_depth
                        terminated = true
                        return false
                    end

                    # sample phase function for medium scattering event
                    u = get_2D!(sampler)
                    ps_p, ps_wi, ps_pdf = sample_p(ray.medium.phase, -ray.direction, u)
                    if ps_p isa Nothing
                        terminated = true
                        return false
                    end

                    # update state for recursive evaluation of L_i
                    beta *= ps_p / ps_pdf
                    ray.origin = p
                    ray.direction = ps_wi
                    scattered = true
                    return false
                elseif callback_mode == 2+1
                    # handle null scattering event for medium sample
                    u_mode = get_1D!(sampler)
                    return true  # continue sampling
                else
                    @assert false
                end
            end
        end

        if terminated
            return LL
        end
        if scattered
            continue
        end
        
        if !(si isa Nothing)
            LL += beta * le(si, -ray.direction)
        else
            for light in scene.lights
                if is_infinite_light(light)
                    LL += beta * le(light, ray)
                end
            end
            return LL
        end

        compute_scattering!(si, ray, true, Radiance)
        if si.bsdf isa Nothing
            ray = spawn_ray(si.core, ray.direction)
            continue
        else
            @assert false
        end
    end
    return LL
end