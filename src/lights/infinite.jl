# PBR 12.6 Infinite Area Lights
struct InfinteLight <: Light
    flags::LightFlags
    light_to_world::Transformation
    world_to_light::Transformation
    I::Spectrum
    pdf::Distribution2D
    map::Matrix
    world_radius::Float64

    function InfinteLight(bounds::Bounds3, light_to_world::Transformation, I::Spectrum, map_url::String)
        dat = load(map_url)
        width, height = size(dat)
        im = zeros(width, height)
        for v in 1:height
            sin_theta = sin(pi * (v + 0.5) / height)
            for u in 1:width
                im[u,v] = (dat[u,v].r + dat[u,v].g + dat[u,v].b) / 3.0 * 1.01
                im[u,v] *= sin_theta                            
            end
        end

        pdf = Distribution2D(im)      

        pMin = abs.(bounds.pMin)
        pMax = abs.(bounds.pMax)
        world_radius = max(pMin.x, pMin.y, pMin.z, pMax.x, pMax.y, pMax.z) * 1.01

        return new(
            LightInfinite,
            light_to_world,
            Inv(light_to_world),
            I,
            pdf,
            dat,
            world_radius
        )
    end
end

function power(il::InfinteLight)::Float64
    u, v = size(il.map)
    return pi .* il.world_radius .* il.world_radius .* Spectrum(il.map[u ÷ 2, v ÷ 2]) .* il.I
end

function le(il::InfinteLight, ray::AbstractRay)::Spectrum
    x, y = size(il.map)
    w = normalize(il.world_to_light(ray.direction))
    s = Int(trunc(spherical_phi(w) / (2pi) * x) + 1)
    t = Int(trunc(spherical_theta(w) / pi * y) + 1)
    l = il.map[s,t]
    return Spectrum(l.r, l.g, l.b) * il.I
end

function sample_li(il::InfinteLight, interaction::Interaction, uvu::Pnt2)::Tuple{Spectrum, Vec3, Float64, VisibilityTester, Pnt3, Nml3}
    # Find $(u,v)$ sample coordinates in infinite light texture
    uv, map_pdf = sample_continuous(il.pdf, uvu)
    (map_pdf == 0) && return Spectrum(0), Vec3(0), 0.0, VisibilityTester(Interaction(), Interaction()), Pnt3(0), Nml3(0)

    # Convert infinite light sample point to direction
    theta = uv.y * pi
    phi = uv.x * 2 * pi
    cos_theta = cos(theta)
    sin_theta = sin(theta)
    sin_phi = sin(phi)
    cos_phi = cos(phi)
    wi = il.light_to_world(Vec3(sin_theta * cos_phi, sin_theta * sin_phi, cos_theta))

    # Compute PDF for sampled infinite light direction
    map_pdf /= (2 * pi * pi * sin_theta)
    (sin_theta == 0) && (map_pdf = 0.0)

    # Return radiance value for infinite light direction
    x, y = size(il.map)
    color = il.map[Int(trunc(uv.x * x)+1), Int(trunc(uv.y * y)+1)]
    radiance = Spectrum(color.r, color.g, color.b) * il.I

    # visibility
    visibility = VisibilityTester(
        interaction,
        Interaction(interaction.p + wi .* 2 * il.world_radius, interaction.t, Vec3(0, 0, 0), Nml3(0, 0, 0))
    )

    return radiance, wi, map_pdf, visibility, Pnt3(0,0,0), Nml3(0,0,0)
end

function pdf_li(il::InfinteLight, isect::SurfaceInteraction, wi::Vec3)::Float64
    wi = il.world_to_light(wi)
    theta = spherical_theta(wi)
    phi = spherical_phi(wi)
    sin_theta = sin(theta)
    (sin_theta == 0.0) && return 0.0

    u_idx = phi / 2pi
    v_idx = theta / pi

    pdf_val = pdf(il.pdf, Pnt2(v_idx, u_idx))

    return pdf_val / (2 * pi * pi * sin_theta)
end

################
#### 16.1.2 BDPT 
################

function sample_le(light::InfinteLight, u1::Pnt2, u2::Pnt2, t::Float64)::Tuple{Spectrum, RayDifferential, Nml3, Float64, Float64}
    # compute direction for infinite light sample ray
    u = u1
    # find uv coordinates in infinite light texture
    uv, map_pdf = sample_continuous(light.pdf, u)
    (map_pdf == 0.0) && return Spectrum(0.0), RayDifferential(Ray()), Nml3(0), 0.0, 0.0

    theta = uv.y * pi
    phi = uv.x * 2.0 * pi
    cos_theta = cos(theta)
    sin_theta = sin(theta)
    sin_phi = sin(phi)
    cos_phi = cos(phi)
    d = -light.light_to_world(Vec3(sin_theta * cos_phi, sin_theta * sin_phi, cos_theta))
    n_light = Nml3(d)
    
    # compute origin for infinite light sample ray
    _, v1, v2 = orthonormal_basis(-d)
    cd = random_in_concentric_disk(u2)
    pdisk = Pnt3(0) + light.world_radius * (cd.x * v1 + cd.y * v2)
    ray = RayDifferential(Ray(pdisk + light.world_radius * -d, d, t, typemax(Float64)))
    
    # compute infinite area light ray pdfs
    pdf_dir = sin_theta == 0.0 ? 0.0 : map_pdf / (2.0 * pi * pi * sin_theta)
    pdf_pos = 1 / (pi * light.world_radius * light.world_radius)

    # JOHN convert map to spectrum
    x,y = size(light.map)
    l = light.map[Int(trunc(uv.x * x)+1), Int(trunc(uv.y * y)+1)]
    return Spectrum(l.r, l.g, l.b) * light.I, ray, n_light, pdf_pos, pdf_dir
end