struct DistantLight <: Light
    L::Spectrum
    w_light::Vec3
    world_center::Pnt3
    world_radius::Float64
    light_to_world::Transformation
    flags::LightFlags
    medium::Maybe{AbstractMedium}

    function DistantLight(L::Spectrum, from::Vec3, to::Vec3, world_center::Pnt3, world_radius::Float64, light_to_world::Transformation)
        w_light = from - to
        return new(
            L,
            normalize(light_to_world(w_light)),
            world_center,
            world_radius,
            light_to_world,
            LightDeltaDirection,
            nothing
        )
    end
end

function le(dl::DistantLight, ray::AbstractRay)::Spectrum
    return spectrum_from_float(0,0,0)
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
        Interaction(p_outside, interaction.t, Vec3(0,0,0), Nml3(0,0,0), dl.medium)
    )
    radiance = L(dl, nshape, -wi)
    return radiance, wi, pdf_val, visibility, pshape, nshape
end

function pdf_li(light::DistantLight, isect::SurfaceInteraction, wi::Vec3)::Float64
    return 0.0
end


################
#### 16.1.2 BDPT stuff
################

function sample_le(light::DistantLight, u1::Pnt2, u2::Pnt2, t::Float64)::Tuple{Spectrum, RayDifferential, Nml3, Float64, Float64}
    # choose point on disk oriented toward infinite light direction
    w_light, v1, v2 = orthonormal_basis(light.w_light)
    cd = random_in_concentric_disk(u1)
    p_disk = light.world_center .+ light.world_radius * (cd.x * v1 + cd.y * v2)
    @info "SampleLe:\n\tworld_center: $(light.world_center) \n\tworld_radius: $(light.world_radius)\n\tw_light: $w_light\n\tv1: $v1\n\tv2: $v2\n\tcd: $cd\n\tp_disk: $p_disk"

    # set ray origin and direction for infinite light ray
    ray = RayDifferential(Ray(p_disk + light.world_radius * w_light, -w_light, t, typemax(Float64)))
    pdf_pos = 1.0 / (pi * light.world_radius^2)
    pdf_dir = 1.0
    return light.L, ray, Nml3(ray.direction), pdf_pos, pdf_dir
end

function pdf_le(light::DistantLight, ray::AbstractRay, n::Nml3)::Tuple{Float64, Float64}
    pdf_pos = 1.0 / (pi * light.world_radius^2)
    pdf_dir = 0.0
    return pdf_pos, pdf_dir
end