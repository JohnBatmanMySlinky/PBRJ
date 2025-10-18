struct VolPathIntegratorv3 <: AbstractIntegrator
    camera::C where C <: Camera
    sampler::S where S <: AbstractSampler
    max_depth::Int64
end

function li(svp::VolPathIntegratorv3, ray::AbstractRay, scene::Scene, depth::Int64, sampler::AbstractSampler)::Spectrum
    # declare local variables for delta tracking integration
    LL = spectrum_from_float(0.0)
    beta = spectrum_from_float(1.0)
    bounces = 0
    specular_bounce = false
    eta_scale = 1.0
    light_distribution_generator = LightDistribution("uniform", scene)


    while true
        # Intersect _ray_ with scene and store intersection in _isect_
        check, t, si = intersect!(scene.b, ray)

        # Sample the participating medium, if present
        if !(ray.medium isa Nothing)
            @assert false
        end

        if is_black(beta)
            break
        end

        # JOHN HACK - skipping mi.is_valid() check
        # Handle scattering at point on surface for volumetric path tracer

        # Possibly add emitted light at intersection
        if (bounces == 0) || specular_bounce
            # Add emitted light at path vertex or from the environment
            if !(si isa Nothing)
                LL += beta * le(si, -ray.direction)
            else
                for light in scene.lights
                    if is_infinite_light(light)
                        LL += beta * le(light, ray)
                    end
                end
            end
        end

        # Terminate path if ray escaped or _maxDepth_ was reached
        if ((si isa Nothing) || (bounces >= depth)) 
            break
        end

        compute_scattering!(si, ray, true, Radiance)
        if si.bsdf isa Nothing
            ray = spawn_ray(si.core, ray.direction)
            bounces -= 1
            continue
        end

        # Sample illumination from lights to find attenuated path contribution
        light_distribution = lookup(light_distribution_generator, si.core.p)
        L += beta * uniform_sample_one_light(si, scene, i.sampler, light_distribution, true)

        # Sample BSDF to get new path direction
        wo = -ray.direction
        wi, f, pdf_val, sampled_type = sample_f(si.bsdf, wo, get_2D!(i.sampler), BSDF_ALL)
        if (pdf_val == 0.0) || is_black(f)
            break
        end
        beta *= f * abs(dot(wi, si.shading.n)) / pdf_val
        specular_bounce = (sampled_type & BSDF_SPECULAR) != 0
        if ((sampled_type & BSDF_SPECULAR) && (sampled_type & BSDF_TRANSMISSION))
            eta = si.bsdf.eta
            # Update the term that tracks radiance scaling for refraction
            # depending on whether the ray is entering or leaving the
            # medium.
            eta_scale *= (dot(wo, si.n) > 0) ? (eta * eta) : 1.0 / (eta * eta);
        end
        ray = spawn_ray(si.core, wi)

        if !(is.bssrdf isa Nothing) && (sampled_type & BSDF_TRANSMISSION)
            @assert false
        end

        # Possibly terminate the path with Russian roulette.
        # Factor out radiance scaling due to refraction in rrBeta.
        rr_beta = beta * eta_scale
        rr_threshold = 1.0
        if (maximum(rr_beta) < rr_threshold) && (bounces > 3)
            q = max(.05, 1 - max(rr_beta))
            if (Get1D!(sampler) < q)
                break
            end
            beta /= 1.0 - q
        end
        bounces += 1
    end
    return LL
end