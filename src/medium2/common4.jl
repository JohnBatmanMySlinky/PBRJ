function sampleT_maj!(
    callback::Function, ray::AbstractRay, t_max::Float64, 
    u::Float64, sampler::AbstractSampler
)::Spectrum
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
                t = t_min + sample_exponential(u, y_spectrum(seg.sigma_maj))
                u = get_1D!(sampler)
                if t < seg.t_max
                    # Call callback function for sample within segment
                    T_maj *= fastexp.(-(t - t_min) * seg.sigma_maj)
                    mp = sample_point(ray.medium, at(ray,t))
                    p = at(ray,t)

                    # outside callback
                    if !callback(at(ray,t), mp, seg.sigma_maj, T_maj)
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
    return spectrum_from_float(1.0)
end