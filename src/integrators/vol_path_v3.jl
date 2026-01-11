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
    light_distribution_generator = LightDistribution(UInt8(1), scene)


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
                @info "Added Le -> L = $LL"
            else
                for light in scene.lights
                    if is_infinite_light(light)
                        LL += beta * le(light, ray)
                    end
                end
            end
        end
        # @info "LL = $LL - $beta"

        # Terminate path if ray escaped or _maxDepth_ was reached
        if (si isa Nothing)
            # @info "Terminated due to no hit"
            break
        end

        if (bounces >= vp.max_depth)
            # @info "Terminated due to max depth"
            break
        end

        compute_scattering!(si, ray, true, Radiance)
        if si.bsdf isa Nothing
            ray = spawn_ray(si.core, ray.direction)
            # bounces -= 1 ignored due to incrementing at the bottom
            continue
        end

        # Sample illumination from lights to find attenuated path contribution
        light_distribution = lookup(light_distribution_generator, si.core.p)

        # JOHN HACK 
        # SWITCH TO ON TO HANDLE MEDIA
        LL += beta * uniform_sample_one_light(si, scene, sampler, light_distribution, true)
        # @info "LL = $LL - $beta"

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
            # Update the term that tracks radiance scaling for refraction
            # depending on whether the ray is entering or leaving the
            # medium.
            eta_scale *= (dot(wo, si.core.n) > 0) ? (eta * eta) : 1.0 / (eta * eta)
        end
        ray = spawn_ray(si.core, wi)

        if !(si.bssrdf isa Nothing) && ((sampled_type & BSDF_TRANSMISSION) != 0)
            # Importance sample the BSSRDF
            # @info "beep boop integrating: importance sampling the BSSDRF"
            why = get_1D!(sampler)
            god = get_2D!(sampler)
            S, pisect, pdf_val = sample_s(si.bssrdf, scene, why, god)
            if (is_black(S) || pdf_val == 0) 
                break
            end
            beta *= S / pdf_val

            # Account for the attenuated direct subsurface scattering component
            # JOHN HACK ON THE MEDIA = false
            LL += beta * uniform_sample_one_light(
                pisect, 
                scene, 
                sampler, 
                lookup(light_distribution_generator, pisect.core.p), 
                true
            )
            # @info "LL = $LL - $beta"

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
        # @info "beep booping around:: $beta - $eta_scale"
        rr_beta = beta * eta_scale
        rr_threshold = 1.0
        if (maximum(rr_beta) < rr_threshold) && (bounces > 3)
            q = max(0.05, 1 - maximum(rr_beta))
            if (get_1D!(sampler) < q)
                break
            end
            beta /= 1.0 - q
        end
        bounces += 1
    end
    return LL
end