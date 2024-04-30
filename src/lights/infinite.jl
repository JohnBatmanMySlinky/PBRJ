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

    function InfiniteLight(bounds::Bounds3, light_to_world::Transformation, LL::Spectrum, texmap::String)
        ident = texmap[end-3:end]
        if ident == ".exr"
            dat = OpenEXR.load(texmap)
        else
            @assert false # NOT IMPLEMENTED
        end

        # Convert from colors to Spectrum and adjust by LL
        L, W = size(dat)
        dat2 = zeros(Spectrum, L * W)
        i = 0
        for l in 1:L
            for w in 1:W
                i += 1
                dat2[i] = Spectrum(dat[l,w].r, dat[l,w].g, dat[l,w].b) * LL
            end
        end

        Lmap = MIPMap(Pnt2(W, L), dat2) # NOTE THE FLIP HERE

        world_center, world_radius = bounding_sphere(bounds)
        world_center = Pnt3( 0.0449999571, 1.04499996, -0.75000006 )
        world_radius = 2.42487
        @info "Infinite Light center: $(world_center), radius: $(world_radius)"

        # Initialize sampling PDFs for infinite area light
        # Compute scalar-valued image img from environment map
        # create im for pdf creation
        width = 2 * Lmap.resolution.x, height = 2 * Lmap.resolution.y
        fwidth = 0.5 / min(width, height)
        im = zeros(Float64, width, height)
        for v in 0:(height-1)
            vp = (v + 0.5) / height
            sin_theta = sin(pi * (v + 0.5) / height)
            for u in 0:(width-1)
                up = (u + 0.5) / width
                im[u + 1, v + 1] = y_spectrum(lookup(Lmap, Pnt2(up, vp), fwidth)) * sin_theta
                @info "Infinite Light PDF: $(u+1), $(v+1) = $(im[u + 1, v + 1])"
            end
        end
        distribution = Distribution2D(im) 
        return new(
            Lmap,
            world_center,
            world_radius,
            distribution,
            light_to_world,
            Inv(light_to_world),
            nothing,
            LightInfinite
        )
    end
end

# struct InfiniteLight <: Light
#     flags::LightFlags
#     light_to_world::Transformation
#     world_to_light::Transformation
#     I::Spectrum
#     pdf::Distribution2D
#     map::Matrix{RGBA{Float16}}
#     world_center::Pnt3
#     world_radius::Float64
#     medium::Maybe{Medium}
    
#     function InfiniteLight(bounds::Bounds3, light_to_world::Transformation, I::Spectrum, map_url::String)
#         ident = map_url[end-3:end]
#         if ident == ".exr"
#             dat = OpenEXR.load(map_url)
#         else
#             @assert false # NOT IMPLEMENTED
#         end

#         @info "World bounds $(bounds.pMin) - $(bounds.pMax)"
        
#         # create im for pdf creation
#         width, height = 2.0 * size(dat)
#         fwdith = 0.5 / min(width, height)
#         im = zeros(width, height)
#         for v in 1:height
#             vp = (v + 0.5) / height
#             sin_theta = sin(pi * (v + 0.5) / height)
#             for u in 1:width
#                 up = (u + 0.5) / width
#                 im[u,v] = dat[u,v] * sin_theta
#             end
#         end
#         pdf = Distribution2D(im)      

#         # get world radius and world center
#         world_center, world_radius = bounding_sphere(bounds)

#         return new(
#             LightInfinite,
#             light_to_world,
#             Inv(light_to_world),
#             I,
#             pdf,
#             dat,
#             world_center,
#             world_radius,
#             nothing
#         )
#     end
# end

function power(il::InfiniteLight)::Float64
    return pi * il.world_radius * il.world_radius * spectrum_from_float(lookup(il.Lmap, Pnt2(0.5, 0.5), 0.5), Illuminant)
end

function le(il::InfiniteLight, ray::AbstractRay)::Spectrum
    w = normalize(il.world_to_light(ray.direction))
    st = Pnt2(
        spherical_phi(w) / 2pi,
        spherical_theta(w) / pi
    )
    return spectrum_from_float(lookup(il.Lmap, st), Illuminant)
end

function sample_li(il::InfiniteLight, interaction::Interaction, uvu::Pnt2)::Tuple{Spectrum, Vec3, Float64, VisibilityTester, Pnt3, Nml3}
    # Find $(u,v)$ sample coordinates in infinite light texture
    uv, map_pdf = sample_continuous(il.distribution, uvu)
    (map_pdf == 0) && return spectrum_from_float(0.0), Vec3(0), 0.0, VisibilityTester(Interaction(), Interaction()), Pnt3(0), Nml3(0)

    # Convert infinite light sample point to direction
    theta = uv.y * pi
    phi = uv.x * 2 * pi
    cos_theta = cos(theta)
    sin_theta = sin(theta)
    sin_phi = sin(phi)
    cos_phi = cos(phi)
    wi = il.light_to_world(Vec3(sin_theta * cos_phi, sin_theta * sin_phi, cos_theta))

    # Compute PDF for sampled infinite light direction
    pdf_val = map_pdf / (2 * pi * pi * sin_theta)
    (sin_theta == 0) && (pdf_val = 0.0)

    # visibility
    visibility = VisibilityTester(
        interaction,
        Interaction(interaction.p + wi .* 2 * il.world_radius, interaction.t, Nml3(0, 0, 0), il.medium)
    )

    radiance = spectrum_from_float(lookup(il.Lmap, uv), Illuminant)

    return radiance, wi, map_pdf, visibility, Pnt3(0,0,0), Nml3(0,0,0)
end

function pdf_li(il::InfiniteLight, isect::SurfaceInteraction, w::Vec3)::Float64
    wi = il.world_to_light(w)
    theta = spherical_theta(wi)
    phi = spherical_phi(wi)
    sin_theta = sin(theta)
    (sin_theta == 0.0) && return 0.0

    return pdf(il.distribution, Pnt2(phi / 2pi, theta / pi)) / (2 * pi * pi * sin_theta)
end

################
#### 16.1.2 BDPT 
################

function sample_le(il::InfiniteLight, u1::Pnt2, u2::Pnt2, t::Float64)::Tuple{Spectrum, RayDifferential, Nml3, Float64, Float64}
    u = u1
    uv, map_pdf = sample_continuous(il.distribution, u)
    (map_pdf == 0.0) && return spectrum_from_float(0.0), RayDifferential(Ray()), Nml3(0), 0.0, 0.0

    theta = uv.y * pi, phi = uv.x * 2.0 * pi
    cos_theta = cos(theta), sin_theta = sin(theta)
    sin_phi = sin(phi), cos_phi = cos(phi)

    d = -il.light_to_world(Vec3(sin_theta * cos_phi, sin_theta * sin_phi, cos_theta))
    nlight = Nml3(d)

    _, v1, v2 = orthonormal_basis(-d)
    cd = random_in_concentric_disk(u2)
    p_disk = il.world_center + il.world_radius * (cd.x * v1 + cd.y * v2)
    ray = Ray(p_disk + il.world_radius * -d, d, typemax(Float64), t)

    pdf_dir = sin_theta == 0.0 ? 0.0 : map_pdf / (2 * pi * pi * sin_theta)
    pdf_pos = 1.0 / (pi * il.world_radius * il.world_radius)
    radiance = spectrum_from_float(lookup(il.Lmpa, uv), Illuminant)
    return radiance, ray, nlight, pdf_dir, pdf_pos
end

function pdf_le(il::InfiniteLight, ray::RayDifferential, n::Nml3)::Tuple{Float64, Float64}
    d = -il.world_to_light(ray.direction)
    theta = spherical_theta(d), phi = spherical_phi(d)
    uv = Pnt2(phi / 2pi, theta / pi)
    map_pdf = pdf(il.distribution, uv)
    pdf_dir = map_pdf / (2.0 * pi * pi * sin(theta))
    pdf_pos = 1.0 / (pi * il.world_radius * il.world_radius)
    return pdf_dir, pdf_pos
end