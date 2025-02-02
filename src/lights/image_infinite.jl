# PBR 12.6 Infinite Area Lights
struct InfiniteLight <: Light
    Lmap::MIPMap
    world_center::Pnt3
    world_radius::Float64
    distribution::Distribution2D
    light_to_world::Transformation
    world_to_light::Transformation
    medium::Maybe{Medium}
    flags::LightFlags
    do_octahedral::Bool

    function InfiniteLight(bounds::Bounds3, light_to_world::Transformation, LL::Spectrum, texmap::String, do_octahedral::Bool)
        dat2, L, W = read_image(texmap, LL)

        Lmap = MIPMap(Pnt2(W, L), dat2) # NOTE THE FLIP HERE

        world_center, world_radius = bounding_sphere(bounds)
        # world_center = Pnt3( 0.0449999571, 1.04499996, -0.75000006 )
        # world_radius = 2.42487
        @info "Infinite Light center: $(world_center), radius: $(world_radius)"

        # Initialize sampling PDFs for infinite area light
        # Compute scalar-valued image img from environment map
        # create im for pdf creation
        width::Int64 = 2 * Lmap.resolution.x
        height::Int64 = 2 * Lmap.resolution.y
        @info "Infinite Light Sampling Dist ($(width), $(height))"
        fwidth = 0.5 / min(width, height)
        im = zeros(Float64, width, height)
        for v in 0:(height-1)
            vp = (v + 0.5) / height
            sin_theta = sin(pi * (v + 0.5) / height)
            for u in 0:(width-1)
                up = (u + 0.5) / width
                im[u + 1, v + 1] = y_spectrum(lookup(Lmap, Pnt2(up, vp), fwidth)) * sin_theta
                # @info "Infinite Light PDF: $(u), $(v) = $(im[u + 1, v + 1]) = $(lookup(Lmap, Pnt2(up, vp), fwidth)) --- up: $(up) vp: $(vp) fwidth: $(fwidth)"
            end
        end
        distribution = Distribution2D(reshape(im, width, height)) 
        return new(
            Lmap,
            world_center,
            world_radius,
            distribution,
            light_to_world,
            Inv(light_to_world),
            nothing,
            LightInfinite,
            do_octahedral
        )
    end
end

function power(il::InfiniteLight)::Float64
    return pi * il.world_radius * il.world_radius * spectrum_from_float(lookup(il.Lmap, Pnt2(0.5, 0.5), 0.5))
end

function le(il::InfiniteLight, ray::AbstractRay)::Spectrum
    w = normalize(il.world_to_light(ray.direction))
    if il.do_octahedral
        st = equal_area_sphere_to_square(w)
    else
        st = Pnt2(
            spherical_phi(w) / 2pi,
            spherical_theta(w) / pi
        )
    end
    return lookup(il.Lmap, st)
end

function sample_li(il::InfiniteLight, interaction::Interaction, uvu::Pnt2)::Tuple{Spectrum, Vec3, Float64, VisibilityTester, Pnt3, Nml3}
    # Find $(u,v)$ sample coordinates in infinite light texture
    uv, map_pdf = sample_continuous(il.distribution, uvu)
    (map_pdf == 0) && return spectrum_from_float(0.0), Vec3(0), 0.0, VisibilityTester(Interaction(), Interaction()), Pnt3(0), Nml3(0)

    # Convert infinite light sample point to direction
    if il.do_octahedral
        wi = il.light_to_world(equal_area_square_to_sphere(uv))
    else
        theta = uv.y * pi
        phi = uv.x * 2 * pi
        cos_theta = cos(theta)
        sin_theta = sin(theta)
        sin_phi = sin(phi)
        cos_phi = cos(phi)
        wi = il.light_to_world(Vec3(sin_theta * cos_phi, sin_theta * sin_phi, cos_theta))
    end
    @info "InfLight sample_li: uv $uv - map_pdf $map_pdf - wi $wi"

    # Compute PDF for sampled infinite light direction
    if il.do_octahedral
        pdf_val = map_pdf / (4 * pi)
    else
        pdf_val = map_pdf / (2 * pi * pi * sin_theta)
        (sin_theta == 0) && (pdf_val = 0.0)
    end

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

    radiance = lookup(il.Lmap, uv)
    @info "InfLight sample_li: Lmap $radiance Spectrum $(spectrum_from_RGB(radiance.a, radiance.b, radiance.c, Illuminant))"
    radiance = spectrum_from_RGB(radiance.a, radiance.b, radiance.c, Illuminant)

    return radiance, wi, pdf_val, visibility, Pnt3(0,0,0), Nml3(0,0,0)
end

function pdf_li(il::InfiniteLight, isect::SurfaceInteraction, w::Vec3)::Float64
    wi = il.world_to_light(w)
    if il.do_octahedral
        uv = equal_area_sphere_to_square(wi)
        pdf_val = pdf(il.distribution, uv) / (4 * pi)
    else
        theta = spherical_theta(wi)
        phi = spherical_phi(wi)
        sin_theta = sin(theta)
        (sin_theta == 0.0) && return 0.0
        uv = Pnt2(phi / 2pi, theta / pi)
        pdf_val = pdf(il.distribution, uv) / (2 * pi * pi * sin_theta)
    end
    return pdf_val
end

################
#### 16.1.2 BDPT 
################

function sample_le(il::InfiniteLight, u1::Pnt2, u2::Pnt2, t::Float64)::Tuple{Spectrum, RayDifferential, Nml3, Float64, Float64}
    u = u1
    uv, map_pdf = sample_continuous(il.distribution, u)
    @info "Sampling Light: UV: $(uv), map_pdf: $(map_pdf)"
    (map_pdf == 0.0) && return spectrum_from_float(0.0), RayDifferential(Ray()), Nml3(0), 0.0, 0.0

    if il.do_octahedral
        d = -il.light_to_world(equal_area_square_to_sphere(uv))
    else
        theta = uv.y * pi
        phi = uv.x * 2.0 * pi
        cos_theta = cos(theta)
        sin_theta = sin(theta)
        sin_phi = sin(phi)
        cos_phi = cos(phi)
        d = -il.light_to_world(Vec3(sin_theta * cos_phi, sin_theta * sin_phi, cos_theta))
    end
    @info "Sampling Light: d: $d"
    nlight = Nml3(d)

    _, v1, v2 = orthonormal_basis(-d)
    cd = random_in_concentric_disk(u2)
    p_disk = il.world_center + il.world_radius * (cd.x * v1 + cd.y * v2)
    @info "world_center: $(il.world_center)  world_radius: $(il.world_radius)"
    @info "Sampling Light: p_disk: $p_disk"
    ray = RayDifferential(Ray(p_disk + il.world_radius * -d, d, t, typemax(Float64)))

    if il.do_octahedral
        pdf_dir = map_pdf / ( 4 * pi)
    else
        pdf_dir = sin_theta == 0.0 ? 0.0 : map_pdf / (2 * pi * pi * sin_theta)
    end

    pdf_pos = 1.0 / (pi * il.world_radius * il.world_radius)
    radiance = lookup(il.Lmap, uv)
    radiance = spectrum_from_RGB(radiance.a, radiance.b, radiance.c, Illuminant)
    return radiance, ray, nlight, pdf_pos, pdf_dir
end

function pdf_le(il::InfiniteLight, ray::RayDifferential, n::Nml3)::Tuple{Float64, Float64}
    d = -il.world_to_light(ray.direction)
    if il.do_octahedral
        uv = equal_area_sphere_to_square(d)
    else
        theta = spherical_theta(d)
        phi = spherical_phi(d)
        uv = Pnt2(phi / 2pi, theta / pi)
    end

    map_pdf = pdf(il.distribution, uv)

    # JOHN HACK
    if il.do_octahedral
        pdf_dir = map_pdf / (4 * pi)
    else
        pdf_dir = map_pdf / (2.0 * pi * pi * sin(theta))
    end
    pdf_pos = 1.0 / (pi * il.world_radius * il.world_radius)
    return pdf_dir, pdf_pos
end