struct SimpleVolPathIntegrator <: AbstractIntegrator
    camera::C where C <: Camera
    sampler::S where S <: AbstractSampler
    max_depth::Int64
end

function li(svp::SimpleVolPathIntegrator, ray::AbstractRay, scene::Scene, depth::Int64, sampler::AbstractSampler)::Spectrum
    # declare local variables for delta tracking integration
    LL = spectrum_from_float(0.0)
    beta = 1.0
    depth = 0

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

            # Initialize _MajorantIterator_ for ray majorant sampling
            iter = sample_ray(ray.medium, ray, t_max)
            
            # Generate ray majorant samples until termination
            T_maj = spectrum_from_float(1.0)
            done = false
            if !(iter isa Nothing)
                for seg in iter
                    # Get next majorant segment from iterator and sample it

                    # Handle zero-valued majorant for current segment
                    if (is_black(seg.sigma_maj))
                        dt = seg.t_max - seg.t_min
        
                        T_maj *= fastexp.(-dt * seg.sigma_maj)
                        continue
                    end

                    # Generate samples along current majorant segment
                    t_min = seg.t_min
                    while true
                        # Try to generate sample along current majorant segment
                        t = t_min + sample_exponential(u, seg.sigma_maj[0+1])
                        u = get_1D!(sampler)
                        if t < seg.t_max
                            # Call callback function for sample within segment
                            T_maj *= fastexp.(-(t - t_min) * seg.sigma_maj)
                            mp = sample_point(ray.medium, at(ray,t))
                            p = at(ray,t)

                            ############
                            # CALLBACK #
                            ############
                            # computer medium event probabilities for interaction
                            p_absorb = mp.sigma_a[0+1] / seg.sigma_maj[0+1]
                            p_scatter = mp.sigma_s[0+1] / seg.sigma_maj[0+1]
                            p_null = max(0.0, 1.0 - p_absorb - p_scatter)

                            # randomly sample medium scattering event for delta trackign
                            callback_mode, _, _ = sample_discrete(Distribution1D([p_absorb, p_scatter, p_null]), u_mode)
                            if callback_mode == 0+1
                                # handle absorption event for medium sample
                                LL += beta * mp.Le
                                terminated = true
                                callback_val = false
                            elseif callback_mode == 1+1
                                # handle regular scattering eeven for medium sample
                                # stop sampling if maximum depth has been reached
                                depth += 1
                                if depth >= svp.max_depth
                                    terminated = true
                                    callback_val = false
                                end

                                # sample phase function for medium scattering event
                                u = get_2D!(sampler)
                                ps_p, ps_wi, ps_pdf = sample_p(ray.medium.phase, -ray.direction, get_2D!(sampler))
                                if ps_p isa Nothing
                                    terminated = true
                                    callback_val = false
                                end

                                # update state fo recursive evaluation of L_i
                                beta *= ps_p / ps_pdf
                                ray.origin = p
                                ray.direction = ps_wi
                                scattered = true
                                callback_val = false
                            elseif callback_mode == 2+1
                                # handle nul scattering event for medium sample
                                u_mode = get_1D!(sampler)
                                callback_val = false
                            else
                                @assert false
                            end

                            # outside callback
                            if !callback_val
                                done = true
                                break
                            end
                            T_maj = spectrum_from_float(1.0)
                            t_min = t
                        else
                            # Handle sample past end of majorant segment
                            dt = seg.t_max - t_min
                            # Handle infinite _dt_ for ray majorant segment
                            T_maj *= fastexp.(-dt * seg.sigma_maj)
                            break
                        end
                    end
                    if done
                        break
                    end
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
    return L
end
