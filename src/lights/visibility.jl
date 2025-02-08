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
    while true
        check, t, isect = intersect!(scene, ray, true)
        @info "VisiblityTesting: ray: $(ray), check: $(check), isect: $(isect)"
        if check && !(isect.primitive.material isa Nothing)
            return spectrum_from_float(0.0)
        end

        if !(ray.medium isa Nothing)
            t_max = 1.0
            u = get_1D!(sampler)
            p_exit = at(ray, !(isect isa Nothing) ? isect.core.t : (1 - eps()))
            ray.direction = p_exit - ray.origin

            # Update transmittance for current ray segment
            t_max *= length_pbrt(ray.direction)
            ray.direction = normalize(ray.direction)

            # Initialize _MajorantIterator_ for ray majorant sampling
            iter = sample_ray(ray.medium, ray, t_max)

            # Generate ray majorant samples until termination
            T_maj = spectrum_from_float(1.0)

            SEG_COUNTER = 0
            done = false
            if !(iter isa Nothing)
                for seg in iter
                    @info "VISIBILITY: seg: $seg"
                    SEG_COUNTER += 1
                    # Get next majorant segment from iterator and sample it

                    # Handle zero-valued majorant for current segment
                    if (is_black(seg.sigma_maj)) 
                        dt = seg.t_max - seg.t_min
        
                        T_maj *= exp.(-dt * seg.sigma_maj)
                        continue
                    end

                    # Generate samples along current majorant segment
                    t_min = seg.t_min
                    @info "VISIBILITY: t_min: $t_min"

                    INNER_COUNTER = 0
                    while true
                        INNER_COUNTER += 1
                        # Try to generate sample along current majorant segment
                        t = t_min + sample_exponential(u, y_spectrum(seg.sigma_maj))
                        u = get_1D!(sampler)
                        @info "VISIBILITY: u: $u, t: $t, seg: $(seg), Tr: $Tr"
                        if t < seg.t_max
                            # Call callback function for sample within segment
                            T_maj *= exp.(-(t - t_min) * seg.sigma_maj)
                            mp = sample_point(ray.medium, at(ray,t))

                            ############
                            # CALLBACK #
                            ############
                            sigma_n = clamp.(seg.sigma_maj - mp.sigma_a - mp.sigma_s, 0.0, typemax(Float64))

                            # ratio-tracking: only evaluate null scattering
                            pr = T_maj * y_spectrum(seg.sigma_maj)
                            Tr *= T_maj * sigma_n ./ pr
                            inv_w *= T_maj * seg.sigma_maj ./ pr

                            if (is_black(Tr) || is_black(inv_w))
                                callback_value = false
                            else
                                callback_value = true
                            end
                            
                            Tr *= T_maj ./ y_spectrum(T_maj)
                            inv_w *= T_maj ./ y_spectrum(T_maj)

                            if !callback_value
                                done = true
                                break
                            end
                            t_min = t
                        else
                            # Handle sample past end of majorant segment
                            dt = seg.t_max - t_min
                            # Handle infinite _dt_ for ray majorant segment
                            T_maj *= exp.(-dt * seg.sigma_maj)
                            break
                        end
                    end
                    @info "VSIBILITY: INNERS: $INNER_COUNTER"
                    if done
                        break
                    end
                end
            end 
            @info "VISIBILITY: SEGS: $SEG_COUNTER"
        end
        if isect isa Nothing
            break
        else
            ray = spawn_ray_to(isect.core, vt.p1)
        end
    end
    return Tr / y_spectrum(inv_w)
end