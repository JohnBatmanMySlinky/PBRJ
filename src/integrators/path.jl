# PBR 14.5 Path Tracing
struct PathIntegrator <: AbstractIntegrator
    camera::C where C <: Camera
    sampler::S where S <: AbstractSampler
    max_depth::Int64
end

function li(i::PathIntegrator, ray::AbstractRay, scene::Scene, depth::Int64)::Spectrum
    L = Spectrum(0)
    beta = Spectrum(1) # the throughput weight
    specular_bounce = false
    bounces = 0
    light_distribution_generator = LightDistribution("centriod_distance", scene)

    # TODO instantiate light distribution builder

    """
    Each time through the (while) loop of the integrator, the next vertex of the path is found by intersecting the
    current ray with the scene geometry and computing the contribution of the path to the overall radiance
    value with the direct lighting code. A new direction is then chosen by sampling from the BSDF's 
    distribution at the last vertex of the path. After a few vertices have been sampled, Russian roulette is used to 
    randomly terminate the path
    """

    # Find next path vertex and accumulate contribution
    while true
        """The first step in the loop is to find the next path vertex by intersecting ray against the scene geometry."""
        # Intersect _ray_ with scene and store intersection in _isect_
        check, t, isect = intersect!(scene.b, ray)

        """
        if the ray hits an object that is emissive, that is usually ignored since the loop at the previous iteration preformed a direct illumination
        estimate that already accounted for its effect. There are two exceptions
            1) the first is the initial intersection point of camera rays, since there was no previous iteration
            2) the sampled direction of the previous path vertex was from a specular BSDF because delta distribution
        """
        # Possibly add emitted light at intersection
        if (bounces == 0) || specular_bounce
            # Add emitted light at path vertex or from the environment
            if check
                L += beta * le(isect, -ray.direction)
            else
                for light in scene.lights
                    # add infinite area lights
                    L += beta * le(light, ray)
                end
            end
        end
        # Terminate path if ray escaped or _maxDepth_ was reached
        if (!check) || (bounces >= i.max_depth)
            break
        end

        # Compute scattering functions and skip over medium boundaries
        compute_scattering!(isect, ray)
        """ bsdf is a nothing when passing in between participating media"""
        if isect.bsdf isa Nothing
            # we have no participating media so we shouldn't get here
            @assert false
            ray = spawn_ray(isect.core, ray.direction)
            bounces -= 1
            continue
        end

        # TODO build light distribution
        light_distribution = lookup(light_distribution_generator, isect.core.p)

        # Sample illumination from lights to find path contribution.
        # (But skip this for perfectly specular BSDFs.)
        """this gives an estimate of the exitant radiance from direct lighting at the vertex of the current path"""
        L += beta * uniform_sample_one_light(isect, scene, i.sampler, light_distribution, false) # TODO pass light distribution here

        # Sample BSDF to get new path direction
        wo = -ray.direction
        wi, f, pdf, sampled_type = sample_f(isect.bsdf, wo, get_2D!(i.sampler), BSDF_ALL)
        (pdf == 0.0) && break
        beta *= f * abs(dot(wi, isect.shading.n)) / pdf
        specular_bounce = (sampled_type & BSDF_SPECULAR) != 0
        ray = spawn_ray(isect.core, wi)

        # account for subsurface scattering, if applicable
        # it ain't appicable

        # Possibly terminate the path with Russian roulette.
        if bounces > 3
            q = max(.05, 1-beta.g)
            if get_1D!(i.sampler) < q
                break
            end
            beta /= 1-q
        end
        bounces += 1
    end
    return L
end