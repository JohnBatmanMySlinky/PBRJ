struct WhittedIntegrator <: AbstractIntegrator
    camera::C where C <: Camera
    sampler::S where S <: AbstractSampler
    max_depth::Int64
end

function li(i::WhittedIntegrator, ray::AbstractRay, scene::Scene, depth::Int64)::Spectrum
    L = Spectrum(0, 0, 0)
    check, t, interaction = intersect!(scene.b, ray)
    # if nothing is hit --> this is only for env light.
    if !check
        for light in scene.lights
            L += le(light, ray)
        end
        return L
    end

    # compute scattering functions at surface
    compute_scattering!(interaction, ray)
    if interaction.bsdf isa Nothing
        return li(spawn_ray(interaction.core, ray.direction), scene, i.sampler, depth)
    end

    # initialize after computing scattering, ughhhhhhhhhhhhhhhh
    n = interaction.shading.n
    wo = interaction.core.wo 

    # if hit an area light, compute emitted ray 
    L += le(interaction, wo)

    # for each light source, add contrib
    for light in scene.lights
        # JOHN HACK TODO clean up extra args
        sampled_li, wi, pdf, visibility_tester, p_sample, n_sample = sample_li(light, interaction.core, get_2D!(i.sampler))  

        if pdf == 0
            continue
        end
        f = interaction.bsdf(wo, wi)

        if unoccluded(visibility_tester, scene.b)
            L += f .* sampled_li * abs(dot(wi, n)) / pdf
        end

        if false
            if (interaction.core.p.z ≈ -300.0) && (interaction.core.p.x > -50) && (interaction.core.p.x < 50) && (interaction.core.p.y > 50) && (interaction.core.p.y < 150)
                print("\n")
                print("p_hit ", interaction.core.p, "\n")
                print("n_hit ", interaction.core.n, "\n")
                print("n shading ", interaction.shading.n, "\n")
                print("hit time ", interaction.core.t, "\n")
                print("p_sample ", p_sample, "\n")
                print("n_sample ", n_sample, "\n")
                print("sampled_li ", sampled_li, "\n")
                print("wi ", wi, "\n")
                print("pdf ", pdf, "\n")
                print("unoccluded? ", unoccluded(visibility_tester, scene.b), "\n")
                print("f ", f, "\n")
                print("n ", n, "\n")
                print("contrib ", f .* sampled_li * abs(dot(wi, n)) / pdf, "\n")
                print("absdot ", abs(dot(wi, n)), "\n")
                asdf
            end
        end
    end

    if depth + 1 <= i.max_depth
        L += specular_reflect(i, ray, interaction, scene, depth)
        L += specular_transmit(i, ray, interaction, scene, depth)
    end
    return L
end


function specular_reflect(i::WhittedIntegrator, ray::AbstractRay, surface_interaction::SurfaceInteraction, scene::Scene, depth::Int64)
    wo = surface_interaction.core.wo
    type = BSDF_REFLECTION | BSDF_SPECULAR
    wi, f, pdf, sampled_type = sample_f(surface_interaction.bsdf, wo, get_2D!(i.sampler), type)

    ns = surface_interaction.shading.n
    if pdf == 0 || abs(dot(wi, ns)) == 0
        return Spectrum(0, 0, 0)
    end

    ray = spawn_ray(surface_interaction.core, wi)
    return f .* li(i, ray, scene, depth + 1) * abs(dot(wi, ns)) / pdf
end

function specular_transmit(i::WhittedIntegrator, ray::AbstractRay, surface_interaction::SurfaceInteraction, scene::Scene, depth::Int64)
    wo = surface_interaction.core.wo
    type = BSDF_TRANSMISSION | BSDF_SPECULAR
    wi, f, pdf, sampled_type = sample_f(surface_interaction.bsdf, wo, get_2D!(i.sampler), type)

    ns = surface_interaction.shading.n
    if pdf == 0 || abs(dot(wi, ns)) == 0
        return Spectrum(0, 0, 0)
    end

    ray = spawn_ray(interaction.core, wi)
    eta = 1 / surface_interaction.bsdf.eta

    if dot(ns,ns) < 0
        eta = 1/eta
        ns = -ns
    end

    return f * li(i, ray, scene, depth+1) * abs(dot(wi,ns)) / pdf
end