struct VolPathIntegratorv3 <: AbstractIntegrator
    camera::C where C <: Camera
    sampler::S where S <: AbstractSampler
    max_depth::Int64
end

function li(
    vp::VolPathIntegratorv3,
    ray::AbstractRay,
    scene::Scene,
    sampler::AbstractSampler,
    light_distribution_generator,
)::Spectrum
    LL = spectrum_from_float(0.0)
    beta = spectrum_from_float(1.0)
    bounces = 0
    specular_bounce = false
    eta_scale = 1.0
    rr_threshold = 1.0

    while true
        check, t, si = intersect!(scene.b, ray)

        scattered = false
        terminated = false

        if !(ray.medium isa Nothing)
            t_max = (si isa Nothing) ? typemax(Float64) : t
            u = get_1D!(sampler)

            LL_ref              = Ref(LL)
            beta_ref            = Ref(beta)
            scattered_ref       = Ref(false)
            terminated_ref      = Ref(false)
            specular_bounce_ref = Ref(specular_bounce)
            u_mode_ref          = Ref(get_1D!(sampler))

            sampleT_maj!(ray, t_max, u, sampler) do p, mp, sigma_maj, T_maj
                sigma_maj_hero = y_spectrum(sigma_maj)
                p_absorb  = y_spectrum(mp.sigma_a) / sigma_maj_hero
                p_scatter = y_spectrum(mp.sigma_s) / sigma_maj_hero

                um = u_mode_ref[]
                event = if um < p_absorb
                    1
                elseif um < p_absorb + p_scatter
                    2
                else
                    3
                end

                if event == 1
                    LL_ref[] += beta_ref[] * mp.Le
                    terminated_ref[] = true
                    return false

                elseif event == 2
                    if bounces >= vp.max_depth
                        terminated_ref[] = true
                        return false
                    end

                    if p_scatter > 0.0
                        beta_ref[] = beta_ref[] .* mp.sigma_s ./ (sigma_maj .* p_scatter)
                    else
                        terminated_ref[] = true
                        return false
                    end

                    mi = MediumInteraction(p, ray.t, -ray.direction, ray.medium, mp.phase)
                    light_distribution = lookup(light_distribution_generator, p)
                    LL_ref[] += beta_ref[] * uniform_sample_one_light(mi, scene, sampler, light_distribution, true)

                    ps_p, ps_wi, ps_pdf = sample_p(mp.phase, -ray.direction, get_2D!(sampler))
                    if ps_pdf == 0.0
                        terminated_ref[] = true
                        return false
                    end
                    beta_ref[] = beta_ref[] * spectrum_from_float(ps_p / ps_pdf)
                    specular_bounce_ref[] = false

                    new_origin = p + ShadowEpsilon * ps_wi
                    ray = if ray isa RayDifferential
                        RayDifferential(new_origin, ps_wi, ray.t, typemax(Float64), false, ray.rx_origin, ray.ry_origin, ray.rx_direction, ray.ry_direction, ray.medium)
                    else
                        Ray(new_origin, ps_wi, ray.t, typemax(Float64), ray.medium)
                    end

                    scattered_ref[] = true
                    return false

                else
                    u_mode_ref[] = get_1D!(sampler)
                    return true
                end
            end

            LL              = LL_ref[]
            beta            = beta_ref[]
            scattered       = scattered_ref[]
            terminated      = terminated_ref[]
            specular_bounce = specular_bounce_ref[]
        end

        if is_black(beta) || terminated
            break
        end

        if scattered
            rr_beta = beta * eta_scale
            if (maximum(rr_beta) < rr_threshold) && (bounces > 3)
                q = max(0.05, 1.0 - maximum(rr_beta))
                if get_1D!(sampler) < q
                    break
                end
                beta /= 1.0 - q
            end
            bounces += 1
            continue
        end

        if si isa Nothing
            for light in scene.lights
                if is_infinite_light(light)
                    LL += beta * le(light, ray)
                end
            end
            break
        end

        if (bounces == 0) || specular_bounce
            LL += beta * le(si, -ray.direction)
        end

        if (bounces >= vp.max_depth)
            break
        end

        compute_scattering!(si, ray, true, Radiance)
        if si.bsdf isa Nothing
            ray = spawn_ray(si.core, ray.direction)
            continue
        end

        light_distribution = lookup(light_distribution_generator, si.core.p)
        LL += beta * uniform_sample_one_light(si, si.bsdf, scene, sampler, light_distribution, true)

        wo = -ray.direction
        wi, f, pdf_val, sampled_type = sample_f(si.bsdf, wo, get_2D!(sampler), BSDF_ALL)
        if (pdf_val == 0.0) || is_black(f)
            break
        end
        beta *= f * abs(dot(wi, si.shading.n)) / pdf_val
        specular_bounce = (sampled_type & BSDF_SPECULAR) != 0
        if ((sampled_type & BSDF_SPECULAR) != 0) && ((sampled_type & BSDF_TRANSMISSION) != 0)
            eta = si.bsdf.eta
            eta_scale *= (dot(wo, si.core.n) > 0) ? (eta * eta) : 1.0 / (eta * eta)
        end
        ray = spawn_ray(si.core, wi)

        if !(si.bssrdf isa Nothing) && ((sampled_type & BSDF_TRANSMISSION) != 0)
            why = get_1D!(sampler)
            god = get_2D!(sampler)
            S, pisect, pdf_val = sample_s(si.bssrdf, scene, why, god)
            if (is_black(S) || pdf_val == 0)
                break
            end
            beta *= S / pdf_val

            LL += beta * uniform_sample_one_light(
                pisect,
                pisect.bsdf,
                scene,
                sampler,
                lookup(light_distribution_generator, pisect.core.p),
                true
            )

            wi, f, pdf_val, sampled_type = sample_f(pisect.bsdf, pisect.core.wo, get_2D!(sampler), BSDF_ALL)
            if (is_black(f) || pdf_val == 0)
                break
            end
            beta *= f * abs(dot(wi, pisect.shading.n)) / pdf_val
            specular_bounce = (sampled_type & BSDF_SPECULAR) != 0
            ray = spawn_ray(pisect.core, wi)
        end

        rr_beta = beta * eta_scale
        if (maximum(rr_beta) < rr_threshold) && (bounces > 3)
            q = max(0.05, 1.0 - maximum(rr_beta))
            if (get_1D!(sampler) < q)
                break
            end
            beta /= 1.0 - q
        end
        bounces += 1
    end
    return LL
end
