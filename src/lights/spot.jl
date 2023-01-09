struct SpotLight <: Light
    flags::LightFlags
    light_to_world::Transformation
    world_to_light::Transformation
    I::Spectrum
    p_light::Pnt3
    cos_total_width::Float64
    cos_falloff_start::Float64
    function SpotLight(light_to_world::Transformation, I::Spectrum, total_width::Float64, falloff_start::Float64)
        new(
            LightDeltaPosition,
            light_to_world,
            Inv(light_to_world),
            I,
            light_to_world(Pnt3(0,0,0)),
            cos(deg2rad(clamp(total_width, 0, 360))),
            cos(deg2rad(clamp(falloff_start, 0, 360))),
        )
    end
end

function falloff(sl::SpotLight, wi::Vec3)::Float64
    wl = normalize(sl.world_to_light(wi))
    cos_theta = wl.z
    cos_theta < sl.cos_total_width && return 0.0
    cos_theta > sl.cos_falloff_start && return 1.0
    return ((cos_theta-sl.cos_total_width)/(sl.cos_falloff_start-sl.cos_total_width))^4
end

function sample_li(sl::SpotLight, interaction::Interaction, u::Pnt2)::Tuple{Spectrum, Vec3, Float64, VisibilityTester, Pnt3, Nml3}
    wi = normalize(Vec3(sl.p_light - interaction.p))
    pdf_val = 1.0
    visibility = VisibilityTester(
        interaction,
        Interaction(sl.p_light, interaction.t, Vec3(0, 0, 0), Nml3(0, 0, 0))
    )
    radiance = sl.I * falloff(sl, -wi) / distance_squared(sl.p_light, interaction.p)
    return radiance, wi, pdf_val, visibility, Pnt3(0,0,0), Nml3(0,0,0)
end

function power(sl::SpotLight)
    return sl.I * 2 * pi * (1-0.5*(sl.cos_falloff_start-sl.cos_total_width))
end

function le(sl::SpotLight, ray::AbstractRay)
    return Spectrum(0, 0, 0)
end

function pdf_li(light::SpotLight, isect::SurfaceInteraction, wi::Vec3)::Float64
    return 0.0
end


##############
### 16.1.2 BDPT stuff
##############

function sample_le(light::SpotLight, u1::Pnt2, u2::Pnt2, t::Float64)::Tuple{Spectrum, RayDifferential, Nml3, Float64, Float64}
    w = uniform_sample_cone(u1, light.cos_total_width)
    ray = Ray(light.p_light, light.light_to_world(w), t, typemax(Float64))
    n_light = Nml3(ray.direction)
    pdf_pos = 1.0
    pdf_dir = uniform_cone_pdf(light.cos_total_width)
    return light.I * falloff(light, ray.direction), ray, n_light, pdf_pos, pdf_dir
end