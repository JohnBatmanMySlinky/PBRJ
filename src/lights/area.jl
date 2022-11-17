struct DiffuseAreaLight <: Light
    flags::LightFlags
    Lemit::Spectrum
    shape::Shape
    area::Float64
    two_sided::Bool

    function DiffuseAreaLight(Lemit::Spectrum, shape::Shape, two_sided::Bool)
        return new(
            LightArea,
            Lemit,
            shape,
            area(shape),
            two_sided
        )
    end
end

function le(dal::DiffuseAreaLight, ray::AbstractRay)::Spectrum
    return Spectrum(0,0,0)
end

function L(dal::DiffuseAreaLight, n::Nml3, w::Vec3)::Spectrum
    return (dal.two_sided || dot(n, w) > 0) ? dal.Lemit : Spectrum(0,0,0)
end

function Power(li::DiffuseAreaLight)::Spectrum
    return li.Lemit * li.area * pi
end

# PBR 14.2.3
function sample_li(dal::DiffuseAreaLight, interaction::Interaction, u::Pnt2)::Tuple{Spectrum, Vec3, Float64, VisibilityTester, Pnt3, Nml3}
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
    radiance = L(dal, nshape, -wi)
    return radiance, wi, pdf_val, visibility, pshape, nshape
end

function pdf_li(light::DiffuseAreaLight, isect::SurfaceInteraction, wi::Vec3)::Float64
    return pdf(light.shape, isect.core, wi)
end