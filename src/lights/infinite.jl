# PBR 12.6 Infinite Area Lights
struct InfinteLight <: Light
    flags::LightFlags
    light_to_world::Transformation
    world_to_light::Transformation
    I::Spectrum
    pdf::Distribution2D
    map::Matrix{RGBA{Float16}}
    world_center::Pnt3
    world_radius::Float64
    medium::Maybe{Medium}
    
    function InfinteLight(bounds::Bounds3, light_to_world::Transformation, I::Spectrum, map_url::String)
        ident = map_url[end-3:end]
        if ident == ".exr"
            dat = OpenEXR.load(map_url)
        else
            @assert false # NOT IMPLEMENTED
        end
        
        # create im for pdf creation
        width, height = size(dat)
        im = zeros(width, height)
        for v in 1:height
            sin_theta = sin(pi * (v + 0.5) / height)
            for u in 1:width
                im[u,v] = Gray(dat[u,v]) * sin_theta
            end
        end
        pdf = Distribution2D(im)      

        # get world radius and world center
        world_center, world_radius = bounding_sphere(bounds)

        return new(
            LightInfinite,
            light_to_world,
            Inv(light_to_world),
            I,
            pdf,
            dat,
            world_center,
            world_radius,
            nothing
        )
    end
end

function power(il::InfinteLight)::Float64
    y, x = size(il.map)
    u = _uv_map(0.5, x)
    v = _uv_map(0.5, y)
    return pi .* il.world_radius .* il.world_radius .* spectrum_from_float(il.map[v, u]) .* il.I
end

function le(il::InfinteLight, ray::AbstractRay)::Spectrum
    y, x = size(il.map)
    w = normalize(il.world_to_light(ray.direction))
    s = spherical_phi(w) / (2pi)
    t = spherical_theta(w) / pi
    new_s = _uv_map(t, x)
    new_t = _uv_map(s, y)
    l = spectrum_from_float(il.map[new_t, new_s])
    return l * il.I
end

function sample_li(il::InfinteLight, interaction::Interaction, uvu::Pnt2)::Tuple{Spectrum, Vec3, Float64, VisibilityTester, Pnt3, Nml3}
    # Find $(u,v)$ sample coordinates in infinite light texture
    uv, map_pdf = sample_continuous(il.pdf, uvu)
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
    map_pdf /= (2 * pi * pi * sin_theta)
    (sin_theta == 0) && (map_pdf = 0.0)

    # Return radiance value for infinite light direction
    y, x = size(il.map)
    new_u = _uv_map(uv.x, x)
    new_v = _uv_map(uv.y, y)
    tmp = il.map[new_v, new_u]
    radiance = spectrum_from_float(Float64(tmp.r), Float64(tmp.g), Float64(tmp.b)) * il.I

    # visibility
    visibility = VisibilityTester(
        interaction,
        Interaction(interaction.p + wi .* 2 * il.world_radius, interaction.t, Nml3(0, 0, 0))
    )

    return radiance, wi, map_pdf, visibility, Pnt3(0,0,0), Nml3(0,0,0)
end

function pdf_li(il::InfinteLight, isect::SurfaceInteraction, wi::Vec3)::Float64
    wi = il.world_to_light(wi)
    theta = spherical_theta(wi)
    phi = spherical_phi(wi)
    sin_theta = sin(theta)
    (sin_theta == 0.0) && return 0.0

    v_idx = phi / 2pi
    u_idx = theta / pi

    pdf_val = pdf(il.pdf, Pnt2(v_idx, u_idx))

    return pdf_val / (2 * pi * pi * sin_theta)
end

################
#### 16.1.2 BDPT 
################

function sample_le(light::InfinteLight, u1::Pnt2, u2::Pnt2, t::Float64)::Tuple{Spectrum, RayDifferential, Nml3, Float64, Float64}
    # compute direction for infinite light sample ray
    # find uv coordinates in infinite light texture
    uv, map_pdf = sample_continuous(light.pdf, u1)
    (map_pdf == 0.0) && return spectrum_from_float(0.0), RayDifferential(Ray()), Nml3(0), 0.0, 0.0

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
    pdisk = light.world_center + light.world_radius * (cd.x * v1 + cd.y * v2)
    ray = RayDifferential(Ray(pdisk + light.world_radius * -d, d, t, typemax(Float64)))
    
    # compute infinite area light ray pdfs
    pdf_dir = sin_theta == 0.0 ? 0.0 : map_pdf / (2.0 * pi * pi * sin_theta)
    pdf_pos = 1 / (pi * light.world_radius * light.world_radius)

    # JOHN convert map to spectrum
    y, x = size(light.map)
    new_u = _uv_map(uv.x, x)
    new_v = _uv_map(uv.y, y)
    tmp = light.map[new_v, new_u]
    l = spectrum_from_float(Float64(tmp.r), Float64(tmp.g), Float64(tmp.b))
    return l * light.I, ray, n_light, pdf_pos, pdf_dir
end

# JOHN HACK
"""
why do I need this? I am 100% certain I do need this but WHY???? 
trunc(a*b) gives me the right answer mapping the continuous coords uv to a discrete pixel
but then need to toss in the clamp to avoid 0 indexing!!!
"""
function _uv_map(a::Float64, b::Int64)::Int64
    return clamp(1, Int(trunc(a * b)), b)
end