struct SimpleIntegrator <: AbstractIntegrator
    camera::C where C <: Camera
    sampler::S where S <: AbstractSampler
end

function li(si::SimpleIntegrator, ray::AbstractRay, scene::Scene, sampler::AbstractSampler, _light_dist)::Spectrum
    check, t, interaction, = intersect!(scene.b, ray)
    if !check
        L = spectrum_from_float(0.0)
    else
        material = get_material(interaction.primitive.material)
        L = albedo(material, interaction)
    end
    return L
end