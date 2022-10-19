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
        Interaction(pshape, interaction.t, wi, nshape)
    )
    # PBR
    # "given a point on the surface of the area light"
    radiance = L(dal, Interaction(pshape, interaction.t, -wi, nshape), -wi)
    return radiance, wi, pdf_val, visibility, pshape, nshape
end