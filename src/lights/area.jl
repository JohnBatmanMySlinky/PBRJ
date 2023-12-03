struct DiffuseAreaLight <: Light
    flags::LightFlags
    Lemit::Spectrum
    shape::Shape
    area::Float64
    two_sided::Bool

    function DiffuseAreaLight(Lemit::Spectrum, shape::Shape, two_sided::Bool)
        return new(
            LightArea,
            Lemit,
            shape,
            area(shape),
            two_sided
        )
    end
end

function le(dal::DiffuseAreaLight, ray::AbstractRay)::Spectrum
    return spectrum_from_float(0.0)
end

function L(dal::DiffuseAreaLight, n::Nml3, w::Vec3)::Spectrum
    return (dal.two_sided || dot(n, w) > 0) ? dal.Lemit : spectrum_from_float(0.0, 0.0, 0.0)
end

function Power(li::DiffuseAreaLight)::Spectrum
    return li.Lemit * li.area * pi
end

# PBR 14.2.3
function sample_li(dal::DiffuseAreaLight, interaction::Interaction, u::Pnt2)::Tuple{Spectrum, Vec3, Float64, VisibilityTester, Pnt3, Nml3}
    # TODO use more efficient sampling cone of visibility
    pshape, nshape = sample(dal.shape, interaction, u)
    wi = Vec3(normalize(pshape - interaction.p))
    pdf_val = pdf(dal.shape, interaction, wi)
    visibility = VisibilityTester(
        interaction,
        Interaction(pshape, interaction.t, nshape)
    )
    # PBR
    # "given a point on the surface of the area light"
    radiance = L(dal, nshape, -wi)
    return radiance, wi, pdf_val, visibility, pshape, nshape
end

function pdf_li(light::DiffuseAreaLight, isect::SurfaceInteraction, wi::Vec3)::Float64
    return pdf(light.shape, isect.core, wi)
end


##############
### 16.1.2 bdpt stuff
##############

function sample_le(light::DiffuseAreaLight, u1::Pnt2, u2::Pnt2, t::Float64)::Tuple{Spectrum, RayDifferential, Nml3, Float64, Float64}
    # JOHN HACK: kludging around in this function
    
    # samplea  point on the area lights shape, pshape
    p_shape, n_light = sample(light.shape, u1)
    @info "Light Sampling: p:$(p_shape), n:$(n_light)"
    pdf_pos = pdf(light.shape)

    if light.two_sided
        @assert false
    else
        w = cosine_sample_hemisphere(u2)
        pdf_dir = cosine_hemisphere_pdf(w.z)
    end

    n_light, v1, v2 = orthonormal_basis(Vec3(n_light))
    W = w.x * v1 + w.y * v2 + w.z * n_light
    ray = spawn_ray(Interaction(p_shape, t, n_light, n_light), W)
    return L(light, Nml3(W), W), ray, n_light, pdf_pos, pdf_dir
end

function pdf_le(light::DiffuseAreaLight, ray::AbstractRay, n::Nml3)::Tuple{Float64, Float64}
    it = Interaction(ray.origin, ray.t, Vec3(0), n)
    pdf_pos = pdf(light.shape) # JOHN HACK, not using interaction , just doing 1/area(shape)
    pdf_dir = light.two_sided ? (0.5 * cosine_hemisphere_pdf(abs(dot(n, ray.direction)))) : (cosine_hemisphere_pdf(dot(n, ray.direction)))
    return pdf_pos, pdf_dir
end