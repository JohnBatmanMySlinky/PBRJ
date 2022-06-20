# in python scatter() return a tuple of these, here I am returning a struct
struct Scatter 
    check::Bool
    specular_ray::Option{Ray}
    diffuse_ray::Option{Ray}
    attenuation::Vec3
    pdf::Option{PDF}
    is_specular::Bool
    diffuse_prob::Union{Int64, Float64}
end

##################
### Lambertian ###
##################

struct Lambertian <: Material
    albedo::Texture
end

function scatter(l::Lambertian, r::Ray, hit_record::HitRecord)::Scatter
    check = true
    specular_ray = missing
    attenuation = color_value(l.albedo, hit_record.u, hit_record.v, hit_record.p)
    pdf = CosinePDF(hit_record.normal)
    diffuse_ray = Ray(hit_record.p, generate(pdf), r.time)
    is_specular = false
    diffuse_prob = 1
    return Scatter(check, specular_ray, diffuse_ray, attenuation, pdf, is_specular, diffuse_prob)
end

struct ImportanceLambertian <: Material
    albedo::Texture
    epdf::EnvironmentPDF
end

function scatter(l::ImportanceLambertian, r::Ray, hit_record::HitRecord)::Scatter
    check = true
    specular_ray = Ray(Vec3(0,0,0), Vec3(0,0,0), 0) # DUMMY
    attenuation = color_value(l.albedo, hit_record.u, hit_record.v, hit_record.p)
    pdf = ImportanceCosinePDF(hit_record.normal, l.epdf)
    diffuse_ray = Ray(hit_record.p, generate(pdf), r.time)
    is_specular = false
    diffuse_prob = 1
    return Scatter(check, specular_ray, diffuse_ray, attenuation, pdf, is_specular, diffuse_prob)
end

struct AnisotropicPhong <: Material
    albedo::Texture
    nu::Float64
    nv::Float64
end

function scatter(aniphong::AnisotropicPhong, r::Ray, hit_record::HitRecord)::Scatter
    check = true
    attenuation = color_value(aniphong.albedo, hit_record.u, hit_record.v, hit_record.p)
    specular_color = Vec3(1,1,1) # NOT RIGHT

    # ignoring if expoenent logic
    seed = rand()
    pdf = AnisotropicPhongPDF(r.direction, hit_record.normal, aniphong.nu, aniphong.nv)

    dir, is_specular, diffuse_prob = generate(pdf)
    while dot(dir, hit_record.normal) < 0
        dir, is_specular, diffuse_prob = generate(pdf)
    end

    if is_specular == true
        specular_ray = Ray(hit_record.p, dir, r.time)
        diffuse_ray = missing
    else
        diffuse_ray = Ray(hit_record.p, dir, r.time)
        specular_ray = missing
    end

    return Scatter(check, specular_ray, diffuse_ray, attenuation, pdf, is_specular, diffuse_prob)
end

function scattering_pdf(l::Union{Lambertian,ImportanceLambertian,AnisotropicPhong}, r::Ray, hit_record::HitRecord, scattered::Ray)::Float64
    cosine = dot(hit_record.normal, unit_vector(scattered.direction))
    if cosine < 0
        return 0
    else 
        return cosine / pi
    end
end


##################
##### Metal ######
##################

struct Metal <: Material
    albedo::Vec3
    fuzz::Float64
end

function scatter(m::Metal, r::Ray, hit_record::HitRecord)::Scatter
    check = true
    reflected = reflect(unit_vector(r.direction), hit_record.normal)
    specular_ray = Ray(hit_record.p, reflected .+ m.fuzz .* random_in_unit_sphere(), r.time)
    diffuse_ray = missing
    attenuation = m.albedo
    pdf = missing
    is_specular = true
    diffuse_prob = 0
    return Scatter(check, specular_ray, diffuse_ray, attenuation, pdf, is_specular, diffuse_prob)
end

function reflect(v::Vec3, n::Vec3)::Vec3
    return v .- 2n .* dot(v,n)
end


##################
### Dielectric ###
##################

struct Dielectric <: Material
    ir::Float64
end
function refract(d::Dielectric, uv::Vec3, n::Vec3, etai_over_etat::Float64)::Vec3
    cos_theta = min(dot(-uv,n), 1.0)
    r_out_perp = etai_over_etat .* (uv + cos_theta .* n)
    r_out_parallel = -sqrt(abs(1.0 - norm(r_out_perp)^2)) .* n
    return r_out_perp .+ r_out_parallel
end

function scatter(d::Dielectric, r::Ray, hit_record::HitRecord)::Scatter
    check = true
    is_specular = true
    pdf = missing
    attenuation = Vec3(1.0, 1.0, 1.0)

    if hit_record.front_face
        refraction_ratio = 1.0 / d.ir
    else
        refraction_ratio = d.ir
    end

    unit_direction = unit_vector(r.direction)
    cos_theta = min(dot(-unit_direction, hit_record.normal), 1.0)
    sin_theta = sqrt(1.0 - cos_theta^2)
    cannot_refract = refraction_ratio * sin_theta > 1.0
    if cannot_refract || reflectance(cos_theta, refraction_ratio) > rand()
        direction = reflect(unit_direction, hit_record.normal)
    else    
        direction = refract(d, unit_direction, hit_record.normal, refraction_ratio)
    end

    specular_ray = Ray(hit_record.p, direction, r.time)
    diffuse_ray = missing
    diffuse_prob = 0
    return Scatter(check, specular_ray, diffuse_ray, attenuation, pdf, is_specular, diffuse_prob)
end

function reflectance(cosine::Float64, ref_idx::Float64)::Float64
    r0 = ((1-ref_idx) / (1+ref_idx))^2
    return r0 + (1-r0) * (1-cosine)^5

end


#####################
### Diffuse Light ###
#####################

struct DiffuseLight <: Material
    emit::Texture
end
function scatter(dl::DiffuseLight, r_in, hit_record)::Scatter
    return Scatter(
        false, 
        missing,
        missing, 
        Vec3(0,0,0),
        missing,
        false,
        0
    )
end
function emitted(dl::DiffuseLight, ff::Bool, u::Float64, v::Float64, p::Vec3)::Vec3
    if ff
        return color_value(dl.emit, u, v, p)
    else
        return Vec3(0,0,0)
    end
end


#####################
##### Isotropict ####
#####################

struct Isotropic <: Material
    albedo::Texture
end
function scatter(iso::Isotropic, r_in, hit_record)::Scatter
    return Scatter(
        true, 
        Ray(hit_record.p, random_in_unit_sphere(), hit_record.t), 
        color_value(iso.albedo, hit_record.u, hit_record.v, hit_record.p)
    )
end

# giving all others an emitted
function emitted(d::Union{Dielectric, ImportanceLambertian, Lambertian, Metal, Isotropic, AnisotropicPhong}, ff::Bool, u::Float64, v::Float64, p::Vec3)::Vec3
    return Vec3(0,0,0)
end