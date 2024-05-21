# PBR 12.6 Infinite Area Lights
struct UniformInfiniteLight <: Light
    Lemit::Spectrum
    world_center::Pnt3
    world_radius::Float64
    light_to_world::Transformation
    world_to_light::Transformation
    medium::Maybe{Medium}
    flags::LightFlags

    function UniformInfiniteLight(bounds::Bounds3, light_to_world::Transformation, LL::Spectrum)
        world_center, world_radius = bounding_sphere(bounds)
        @info "Infinite Light center: $(world_center), radius: $(world_radius)"

        return new(
            LL,
            world_center,
            world_radius,
            light_to_world,
            Inv(light_to_world),
            nothing,
            LightInfinite
        )
    end
end

function le(il::UniformInfiniteLight, ray::AbstractRay)::Spectrum
    return il.Lemit
end

function sample_li(il::UniformInfiniteLight, interaction::Interaction, uvu::Pnt2)::Tuple{Spectrum, Vec3, Float64, VisibilityTester, Pnt3, Nml3}
    wi::Vec3 = random_on_sphere(uvu)

    # Compute PDF for sampled infinite light direction
    pdf_val = uniform_sphere_pdf()

    # visibility
    visibility = VisibilityTester(
        interaction,
        Interaction(
            interaction.p + wi .* 2 * il.world_radius, 
            interaction.t, 
            Nml3(0, 0, 0), 
            Vec3(0, 0, 0),
            MediumInterface(il.medium)
        )
    )

    return il.Lemit, wi, pdf_val, visibility, Pnt3(0,0,0), Nml3(0,0,0)
end

function pdf_li(il::UniformInfiniteLight, isect::SurfaceInteraction, w::Vec3)::Float64
    return uniform_sphere_pdf()
end

################
#### 16.1.2 BDPT 
################

function sample_le(il::UniformInfiniteLight, u1::Pnt2, u2::Pnt2, t::Float64)::Tuple{Spectrum, RayDifferential, Nml3, Float64, Float64}
    w::Vec3 = uniform_sample_sphere(u1)

    # choose point on disk oriented toward infinite light direction
    w, v1, v2 = orthonormal_basis(w)
    cd = concentric_sample_disk(u1)
    p_disk = light.world_center + light.world_radius + (cd.x * v1 + cd.y * v2)

    # set ray origin and direction for infinite light ray
    ray = Ray(p_disk + w.world_radius * w, -Nml3(w), t, typemax(Float64))
    pdf_pos = 1.0 / (pi * light.world_radius^2)
    pdf_dir = uniform_sphere_pdf()
    return light.Lemit, ray, Nml3(ray.direction), pdf_pos, pdf_dir
end

function pdf_le(il::UniformInfiniteLight, ray::RayDifferential, n::Nml3)::Tuple{Float64, Float64}
    pdf_pos = 1.0 / (pi * il.world_radius * il.world_radius)
    return uniform_sphere_pdf(), pdf_pos
end