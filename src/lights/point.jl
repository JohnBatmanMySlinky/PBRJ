# 12.3 Point Lights
struct PointLight <: Light
    flags::LightFlags
    light_to_world::Transformation
    world_to_light::Transformation
    I::Spectrum
    light_position::Pnt3
    function PointLight(light_to_world::Transformation, I::Spectrum)
        new(
            LightDeltaPosition,
            light_to_world,
            Inv(light_to_world),
            I, 
            light_to_world(Pnt3(0, 0, 0)),
        )
    end
end


function sample_li(p::PointLight, interaction::Interaction, u::Pnt2)
    wi = normalize(Vec3(p.light_position - interaction.p))
    pdf = 1.0
    visibility = VisibilityTester(
        interaction,
        Interaction(p.light_position, interaction.time, Vec3(0, 0, 0), Nml3(0, 0, 0))
    )
    radiance = p.I / distance_squared(p.light_position, interaction.p)
    return radiance, wi, pdf, visibility
end

function power(p::PointLight)
    return 4.0 * pi * p.I
end

function le(l::PointLight, ray::Ray)
    return Spectrum(0, 0, 0)
end