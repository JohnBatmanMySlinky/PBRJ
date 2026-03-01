struct AOIntegrator <: AbstractIntegrator
    camera::C where C <: Camera
    sampler::S where S <: AbstractSampler
    cos_sample::Bool
end

function li(ao::AOIntegrator, ray::AbstractRay, scene::Scene, sampler::AbstractSampler)::Spectrum
    L = spectrum_from_float(0.0)
    isect = empty_surface_interation()

    while true
        check, t, isect = intersect!(scene.b, ray)
        if check
            compute_scattering!(isect, ray)
            if isect.bsdf isa Nothing
                ray = spawn_ray(isect.core, ray.direction)
            else
                break
            end
        else
            return L
        end
    end

    # compute coordinate frame based on true geom not shading geom
    n = face_forward(isect.core.n, -ray.direction)
    s = normalize(isect.dpdu)
    tt = cross(isect.core.n, s)

    u = get_2D!(sampler)
    if ao.cos_sample
        wi = cosine_sample_hemisphere(u)
        pdf_val = cosine_hemisphere_pdf(abs(wi.z))
    else
        @assert false
    end

    wi = Vec3(
        s.x * wi.x + tt.x * wi.y + n.x * wi.z,
        s.y * wi.x + tt.y * wi.y + n.y * wi.z,
        s.z * wi.x + tt.z * wi.y + n.z * wi.z,
    )

    if !intersect_p(scene.b, spawn_ray(isect.core, wi))
        L = L .+ dot(wi, n) / (pdf_val * pi) # bug in PBRT-v3? missing the π? thankful for v4's implementation...
    end

    return L
end