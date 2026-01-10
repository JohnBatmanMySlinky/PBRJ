struct SimpleIntegrator <: AbstractIntegrator
    camera::C where C <: Camera
    sampler::S where S <: AbstractSampler
end

function li(si::SimpleIntegrator, ray::AbstractRay, scene::Scene, depth::Int64, sampler::AbstractSampler)::Spectrum
    check, t, interaction, = intersect!(scene.b, ray)
    if !check
        L = spectrum_from_float(0.0)
    else
        material = get_material(p.material)
        L = albedo(material, interaction)
    end
    return L
end