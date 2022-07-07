# PBR 12.6 Infinite Area Lights
struct InfinteLight <: Light
    flags::LightFlags
    light_to_world::Transformation
    world_to_light::Transformation
    I::Spectrum
    pdf::PDF_2D
    map::Matrix
    world_center::Point3
    world_radius::Float64

    function InfinteLight(scene::Scene, flags::LightFlags, light_to_world, world_to_light, I::Spectrum, map_url::String)
        dat = Image(Load(""))
        pdf = construct_pdf_2d(dat)

        return new(
            flags,
            light_to_world,
            world_to_light,
            I,
            pdf,
            map,
            world_center,
            world_radius
        )
    end
end

function power(il::InfinteLight)
    u_idx, v_idx = sample_2d_pdf(il.pdf, Pnt2(.5, .5))
    return pi .* il.world_radius .* il.world_radius .* Spectrum(il.map[u_idx, v_idx])
end

function le(il::InfinteLight, ray::Ray)
    x, y = size(il.map)
    w = normalize(il.world_to_light(ray.direction))
    s = trunc(spherical_phi(w) / (2pi) * x) + 1
    t = trunc(spherical_theta(w) / pi * y) + 1
    return Spectrum(il.map[s,t])
end

function sample_li(il::InfinteLight, interaction::Interaction, u::Pnt2)
end

