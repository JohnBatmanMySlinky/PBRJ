struct SpotLight <: Light
    flags::LightFlags
    light_to_world::Transformation
    world_to_light::Transformation
    I::Spectrum
    p_light::Pnt3
    cos_total_width::Float64
    cos_falloff_start::Float64
    medium::Maybe{Medium}

    function SpotLight(light_to_world::Transformation, I::Spectrum, cone_angle::Float64, cone_delta_angle::Float64)
        new(
            LightDeltaPosition,
            light_to_world,
            Inv(light_to_world),
            I,
            light_to_world(Pnt3(0,0,0)),
            cos(deg2rad(cone_angle)),
            cos(deg2rad(cone_angle - cone_delta_angle)),
            nothing
        )
    end
end

function falloff(sl::SpotLight, wi::Vec3)::Float64
    wl = normalize(sl.world_to_light(wi))
    @info "Fall off: wi = $wi"
    @info "Fall off: wl = $wl"
    cos_theta = wl.z
    cos_theta < sl.cos_total_width && return 0.0
    cos_theta >= sl.cos_falloff_start && return 1.0
    @info "fall off: sl.cos_falloff_start = $(sl.cos_falloff_start)"
    @info "fall off: fin = $(((cos_theta-sl.cos_total_width)/(sl.cos_falloff_start-sl.cos_total_width))^4)"
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
    return spectrum_from_float(0, 0, 0)
end

function pdf_li(light::SpotLight, isect::SurfaceInteraction, wi::Vec3)::Float64
    return 0.0
end


##############
### 16.1.2 BDPT stuff
##############

function sample_le(light::SpotLight, u1::Pnt2, u2::Pnt2, t::Float64)::Tuple{Spectrum, RayDifferential, Nml3, Float64, Float64}
    @info "Sample_Le: cos_total_width = $(light.cos_total_width)"
    w = uniform_sample_cone(u1, light.cos_total_width)
    @info "Sample_Le: w = $w"
    ray = Ray(light.p_light, light.light_to_world(w), t, typemax(Float64))
    n_light = Nml3(ray.direction)
    pdf_pos = 1.0
    pdf_dir = uniform_cone_pdf(light.cos_total_width)
    return light.I * falloff(light, ray.direction), RayDifferential(ray), n_light, pdf_pos, pdf_dir
end

function pdf_le(light::SpotLight, ray::AbstractRay, n::Nml3)::Tuple{Float64, Float64}
    pdf_pos = 0.0
    pdf_dir = cos_theta(light.world_to_light(ray.direction)) >= light.cos_total_width ? uniform_cone_pdf(light.cos_total_width) : 0.0
    return pdf_pos, pdf_dir
end