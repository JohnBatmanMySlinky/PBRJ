struct DistantLight <: Light
    L::Spectrum
    w_light::Vec3
    world_center::Pnt3
    world_radius::Float64
    light_to_world::Transformation
    flags::LightFlags

    function DistantLight(L::Spectrum, w_light::Vec3, world_center::Pnt3, world_radius::Float64, light_to_world::Transformation)
        return new(
            L,
            normalize(light_to_world(w_light)),
            world_center,
            world_radius,
            light_to_world,
            LightDeltaDirection
        )
    end
end

function le(dl::DistantLight, ray::AbstractRay)::Spectrum
    return Spectrum(0,0,0)
end
function L(dl::DistantLight, n::Nml3, w::Vec3)::Spectrum
    return dl.L
end
function Power(dl::DistantLight)::Spectrum
    return dl.L * pi * dl.worldRadius^2
end
function sample_li(dl::DistantLight, interaction::Interaction, u::Pnt2)::Tuple{Spectrum, Vec3, Float64, VisibilityTester, Pnt3, Nml3}
    pshape = Pnt3(0,0,0)
    nshape = Nml3(0,0,0)
    wi = dl.w_light
    pdf_val = 1.0
    p_outside = interaction.p + dl.w_light * 2 * dl.world_radius
    visibility = VisibilityTester(
        interaction, 
        Interaction(p_outside, interaction.t, Vec3(0,0,0), Nml3(0,0,0))
    )
    radiance = L(dl, nshape, -wi)
    return radiance, wi, pdf_val, visibility, pshape, nshape
end