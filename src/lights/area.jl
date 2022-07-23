struct DiffuseAreaLight <: Light
    Lemit::Spectrum
    shape::Shape
    area::Float64

    function DiffuseAreaLight(Lemit::Spectrum, shape::Shape)
        return new(
            Lemit,
            shape,
            area(shape)
        )
    end
end

# PBR 12.6 
# "Because infinite area lights need to be able to contribute radiance to rays that don’t hit any geometry in the scene,
# we’ll add a method to the base Light class that returns emitted radiance due to that light along a ray that escapes the scene bounds. 
# (The default implementation for other lights returns no radiance.) It is the responsibility of the integrators to call this method for these rays."
function le(dal::DiffuseAreaLight, ray::AbstractRay)
    return Spectrum(0,0,0)
end

function L(dal::DiffuseAreaLight, interaction::Interaction, w::Vec3)::Spectrum
    return dot(interaction.n, w) > 0 ? dal.Lemit : Spectrum(0,0,0)
end

function Power(li::DiffuseAreaLight)
    return li.Lemit * li.area * pi
end

# PBR 14.2.3
function sample_li(dal::DiffuseAreaLight, interaction::Interaction, u::Pnt2)
    # TODO use more efficient sampling cone of visibility
    pshape, nshape = sample(dal.shape, interaction, u)
    wi = Vec3(normalize(pshape - interaction.p))
    pdf_val = pdf(dal.shape, interaction, wi)
    visibility = VisibilityTester(
        interaction,
        Interaction(pshape, interaction.time, wi, nshape)
    )
    radiance = L(dal, interaction, wi)
    return radiance, wi, pdf_val, visibility
end