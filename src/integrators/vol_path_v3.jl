struct VolPathIntegratorv3 <: AbstractIntegrator
    camera::C where C <: Camera
    sampler::S where S <: AbstractSampler
    max_depth::Int64
end

function li(vp::VolPathIntegratorv3, ray::AbstractRay, scene::Scene, depth::Int64, sampler::AbstractSampler)::Spectrum
    # declare local variables for delta tracking integration
    LL = spectrum_from_float(0.0)
    beta = spectrum_from_float(1.0)
    bounces = 0
    specular_bounce = false
    eta_scale = 1.0
    rr_threshold = 1.0
    light_distribution_generator = LightDistribution("uniform", scene)

    while true
        # Intersect _ray_ with scene and store intersection in _isect_
        check, t, si = intersect!(scene.b, ray)

        # Sample the participating medium, if present
        scattered = false
        terminated = false

        if !(ray.medium isa Nothing)
            t_max = (si isa Nothing) ? typemax(Float64) : t
            u = get_1D!(sampler)
            u_mode = get_1D!(sampler)

            T_maj_result = sampleT_maj!(ray, t_max, u, sampler) do p, mp, sigma_maj, T_maj
                # Compute event probabilities via hero wavelength (luminance channel)
                sigma_maj_hero = y_spectrum(sigma_maj)
                p_absorb  = y_spectrum(mp.sigma_a) / sigma_maj_hero
                p_scatter = y_spectrum(mp.sigma_s) / sigma_maj_hero
                p_null    = max(0.0, 1.0 - p_absorb - p_scatter)

                event, _, _ = sample_discrete(Distribution1D([p_absorb, p_scatter, p_null]), u_mode)

                if event == 1
                    # Absorption — accumulate emission and terminate
                    LL += beta * mp.Le
                    terminated = true
                    return false

                elseif event == 2
                    # Scattering — direct lighting + sample new direction
                    if bounces >= vp.max_depth
                        terminated = true
                        return false
                    end

                    # Update throughput for the scatter event.
                    # The null-scattering estimator weight at a real scatter is
                    # T_maj * sigma_s / (sigma_maj * p_scatter).  For the hero
                    # channel this equals T_maj; for other channels it provides
                    # the spectral re-weighting.
                    if p_scatter > 0.0
                        beta = beta .* T_maj .* mp.sigma_s ./ (sigma_maj .* p_scatter)
                    else
                        terminated = true
                        return false
                    end

                    # Build medium interaction and estimate direct lighting
                    mi = MediumInteraction(p, ray.t, -ray.direction, ray.medium, mp.phase)
                    light_distribution = lookup(light_distribution_generator, p)
                    LL += beta * uniform_sample_one_light(mi, scene, sampler, light_distribution, true)

                    # Sample phase function for the new path direction
                    ps_p, ps_wi, ps_pdf = sample_p(mp.phase, -ray.direction, get_2D!(sampler))
                    if ps_pdf == 0.0
                        terminated = true
                        return false
                    end
                    beta = beta * spectrum_from_float(ps_p / ps_pdf)
                    specular_bounce = false

                    # Update ray in-place so the outer loop sees the new direction
                    ray.origin    = p + ShadowEpsilon * ps_wi
                    ray.direction = ps_wi
                    ray.tMax      = typemax(Float64)
                    ray.has_differentials = false

                    scattered = true
                    return false

                else
                    # Null scattering — weight is 1 for the hero channel; just continue
                    u_mode = get_1D!(sampler)
                    return true
                end
            end

            # If we neither scattered nor terminated, multiply beta by the
            # residual transmittance through the remaining medium segments.
            if !(scattered || terminated)
                beta = beta .* T_maj_result
            end
        end

        if is_black(beta) || terminated
            break
        end

        # Handle medium scatter: apply Russian roulette, then restart the loop
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

        # Possibly add emitted light at surface intersection
        if (bounces == 0) || specular_bounce
            if !(si isa Nothing)
                LL += beta * le(si, -ray.direction)
                @info "Added Le -> L = $LL"
            else
                for light in scene.lights
                    if is_infinite_light(light)
                        LL += beta * le(light, ray)
                    end
                end
            end
        end

        # Terminate path if ray escaped or _maxDepth_ was reached
        if (si isa Nothing)
            break
        end

        if (bounces >= vp.max_depth)
            break
        end

        compute_scattering!(si, ray, true, Radiance)
        if si.bsdf isa Nothing
            ray = spawn_ray(si.core, ray.direction)
            # don't increment bounces for medium boundary crossings
            continue
        end

        # Sample illumination from lights to find attenuated path contribution
        light_distribution = lookup(light_distribution_generator, si.core.p)
        LL += beta * uniform_sample_one_light(si, scene, sampler, light_distribution, true)

        # Sample BSDF to get new path direction
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
            # Importance sample the BSSRDF
            why = get_1D!(sampler)
            god = get_2D!(sampler)
            S, pisect, pdf_val = sample_s(si.bssrdf, scene, why, god)
            if (is_black(S) || pdf_val == 0)
                break
            end
            beta *= S / pdf_val

            # Account for the attenuated direct subsurface scattering component
            LL += beta * uniform_sample_one_light(
                pisect,
                scene,
                sampler,
                lookup(light_distribution_generator, pisect.core.p),
                true
            )

            # Account for the indirect subsurface scattering component
            wi, f, pdf_val, sampled_type = sample_f(pisect.bsdf, pisect.core.wo, get_2D!(sampler), BSDF_ALL)
            @info "Sampled BSDF, f = $f, pdf = $pdf_val"
            if (is_black(f) || pdf_val == 0)
                break
            end
            beta *= f * abs(dot(wi, pisect.shading.n)) / pdf_val
            @info "Updated beta = $beta"
            specular_bounce = (sampled_type & BSDF_SPECULAR) != 0
            ray = spawn_ray(pisect.core, wi)
        end

        # Possibly terminate the path with Russian roulette.
        # Factor out radiance scaling due to refraction in rrBeta.
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
