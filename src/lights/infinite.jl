# PBR 12.6 Infinite Area Lights
struct InfinteLight <: Light
    flags::LightFlags
    light_to_world::Transformation
    world_to_light::Transformation
    I::Spectrum
    pdf::PDF_2D
    map::Matrix
    world_radius::Float64

    function InfinteLight(bvh::BVHNode, light_to_world::Transformation, world_to_light::Transformation, I::Spectrum, map_url::String)
        dat = load(map_url)
        pdf = construct_pdf_2d(dat)

        pMin = abs.(bvh.bounds.pMin)
        pMax = abs.(bvh.bounds.pMax)
        world_radius = max(pMin[1], pMin[2], pMin[3], pMax[1], pMax[2], pMax[3]) * 1.01

        return new(
            LightArea,
            light_to_world,
            world_to_light,
            I,
            pdf,
            dat,
            world_radius
        )
    end
end

function power(il::InfinteLight)
    u_idx, v_idx = sample_pdf_2d(il.pdf, Pnt2(.5, .5))
    tmp = pi .* il.world_radius .* il.world_radius .* Spectrum(il.map[u_idx, v_idx])
    return tmp
end

function le(il::InfinteLight, ray::AbstractRay)
    x, y = size(il.map)
    w = normalize(il.world_to_light(ray.direction))
    s = Int(trunc(spherical_phi(w) / (2pi) * x) + 1)
    t = Int(trunc(spherical_theta(w) / pi * y) + 1)
    l = il.map[s,t]
    return Spectrum(l.r, l.g, l.b)
end

function sample_li(il::InfinteLight, interaction::Interaction, uv::Pnt2)
    # find (u,v) sample coordinates in infinite light texture
    u_idx, v_idx = sample_pdf_2d(il.pdf, uv)

    u_pdf = il.pdf.col_pdf[min(2,u_idx)]
    v_pdf = il.pdf.row_pdf[min(2,v_idx), min(2,u_idx)]

    u = u_idx / (length(il.pdf.col_cdf)+1)
    v = v_idx / (length(il.pdf.row_pdf[:,1])+1)

    # convert infinite light sample point to direction
    theta = v * pi
    phi = u * 2 * pi
    cosTheta = cos(theta)
    sinTheta = sin(theta)
    sinPhi = sin(phi)
    cosPhi = cos(phi)
    wi = normalize(il.light_to_world(Vec3(sinTheta * cosPhi, sinTheta * sinPhi, cosTheta)))

    # compute pdf for sampled infinite light direction
    if sinTheta == 0
        pdf_val = 0
    else
        pdf_val = length(il.pdf.col_cdf) * length(il.pdf.row_cdf[:,1]) * u_pdf * v_pdf / (2 * pi * pi * sinTheta)
    end

    # return radiance value for infinite light direction
    color = il.map[v_idx, u_idx]
    radiance = Spectrum(color.r, color.g, color.b)

    # visibility
    visibility = VisibilityTester(
        interaction,
        Interaction(interaction.p + wi .* 2 * il.world_radius, interaction.time, Vec3(0, 0, 0), Nml3(0, 0, 0))
    )

    return radiance, wi, pdf_val, visibility
end

