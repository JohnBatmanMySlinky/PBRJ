# 12.3 Point Lights
struct PointLight <: Light
    flags::LightFlags
    light_to_world::Transformation
    world_to_light::Transformation
    I::Spectrum
    light_position::Pnt3
    medium::Maybe{Medium}

    function PointLight(light_to_world::Transformation, I::Spectrum)
        return new(
            LightDeltaPosition,
            light_to_world,
            Inv(light_to_world),
            I, 
            light_to_world(Pnt3(0, 0, 0)),
            nothing
        )
    end
end


function sample_li(p::PointLight, interaction::Interaction, u::Pnt2)::Tuple{Spectrum, Vec3, Float64, VisibilityTester, Pnt3, Nml3}
    wi = normalize(Vec3(p.light_position - interaction.p))
    pdf_val = 1.0
    visibility = VisibilityTester(
        interaction,
        Interaction(p.light_position, interaction.t, Vec3(0, 0, 0), Nml3(0, 0, 0))
    )
    radiance = p.I / distance_squared(p.light_position, interaction.p)
    return radiance, wi, pdf_val, visibility, Pnt3(0,0,0), Nml3(0,0,0)
end

function power(p::PointLight)
    return 4.0 * pi * p.I
end

function le(l::PointLight, ray::AbstractRay)
    return spectrum_from_float(0, 0, 0)
end

function pdf_li(light::PointLight, isect::SurfaceInteraction, wi::Vec3)::Float64
    return 0.0
end


# 16.1.2 Sampling Light Rays
function sample_le(light::PointLight, u1::Pnt2, u2::Pnt2, t::Float64)::Tuple{Spectrum, RayDifferential, Nml3, Float64, Float64}
    ray = Ray(light.light_position, Vec3(random_on_sphere(u1)), t, typemax(Float64))
    n_light = Nml3(ray.direction)
    pdf_pos = 1.0
    pdf_dir = uniform_sphere_pdf()
    return light.I, RayDifferential(ray), n_light, pdf_pos, pdf_dir
end