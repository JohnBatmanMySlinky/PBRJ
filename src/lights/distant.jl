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
        Interaction(p_outside, interaction.t, Vec3(0,0,0), Nml3(0,0,0))
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
    cd = concentric_sample_disk(u1)
    p_disk = light.world_center + light.world_radius + (cd.x * v1 + cd.y * v2)

    # set ray origin and direction for infinite light ray
    ray = Ray(p_disk + w.world_radius * w_light, -light.w_light, t, typemax(Float64))
    pdf_pos = 1/ (pi * light.world_radius^2)
    pdf_dir = 1.0
    return light.L, ray, Nml3(ray.direction), pdf_pos, pdf_dir
end