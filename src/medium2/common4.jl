function sampleT_maj!(
    callback::Function, ray::AbstractRay, t_max::Float64, 
    u::Float64, sampler::AbstractSampler
)::Spectrum
    t_max *= length_pbrt(ray.direction)
    ray = set_direction(ray, normalize(ray.direction))

    iter = sample_ray(ray.medium, ray, t_max)

    T_maj = spectrum_from_float(1.0)
    break_early = false
    if !(iter isa Nothing)
        for seg in iter
            if y_spectrum(seg.sigma_maj) == 0
                dt = seg.t_max - seg.t_min
                if isinf(dt)
                    dt = floatmax(Float64)
                end
                T_maj *= fastexp.(-dt * seg.sigma_maj)
                continue
            end

            t_min = seg.t_min
            while true
                t = t_min + sample_exponential(u, y_spectrum(seg.sigma_maj))
                u = get_1D!(sampler)
                if t < seg.t_max
                    T_maj *= fastexp.(-(t - t_min) * seg.sigma_maj)
                    p = at(ray, t)
                    mp = sample_point(ray.medium, p)
                    if !callback(p, mp, seg.sigma_maj, T_maj)
                        break_early = true
                        break
                    end
                    T_maj = spectrum_from_float(1.0)
                    t_min = t
                else
                    dt = seg.t_max - t_min
                    if isinf(dt)
                        dt = floatmax(Float64)
                    end
                    T_maj *= fastexp.(-dt * seg.sigma_maj)
                    break
                end
            end
            if break_early
                break
            end
        end
    end
    
    if break_early
        return spectrum_from_float(1.0)
    else
        return T_maj
    end
end