# Particle Emitter light - port of eg2020-pbrt-v3 particle_emitter.{cpp,h}
# https://gitlab.arm.com/wasp/eg2020-pbrt-v3
# Emits Cherenkov radiation from charged particles traveling through the scene.
# Particles are spawned from a shape surface (typically a disk) and traced through
# the scene. In intervals where the particle is superluminal (v > c/n), it emits
# Cherenkov photons at angle theta = acos(1/(v*n)) per the Frank-Tamm formula.

const ETA_AIR = 1.000293

struct ParticleEmitterParticle
    origin::Pnt3
    direction::Vec3    # normalized, = surface normal at spawn point
    range::Float64
end

# Superluminal interval: (t_start, t_end, refractive_index)
const SLInterval = Tuple{Float64, Float64, Float64}

mutable struct ParticleEmitter <: Light
    flags::LightFlags
    shape::Shape
    velocity::Float64        # v/c
    range::Float64
    cherenkov_scale::Float64
    uniform_scale::Float64
    ambient_eta::Float64
    n_particles::Int64
    seed::Int64

    # filled by preprocess!
    particles::Vector{ParticleEmitterParticle}
    intervals::Vector{Vector{SLInterval}}
    ft_spectra::Vector{Vector{Spectrum}}
    particle_length::Float64
    superluminal_length::Float64
    prob_sl::Float64

    function ParticleEmitter(
        shape::Shape;
        velocity::Float64        = 0.8,
        range::Float64           = 50.0,
        cherenkov_scale::Float64 = 1000.0,
        uniform_scale::Float64   = 50.0,
        ambient_eta::Float64     = ETA_AIR,
        n_particles::Int64       = 1,
        seed::Int64              = 0
    )
        new(
            LightArea,
            shape,
            velocity, range, cherenkov_scale, uniform_scale, ambient_eta,
            n_particles, seed,
            ParticleEmitterParticle[], Vector{SLInterval}[], Vector{Spectrum}[],
            0.0, 0.0, 0.0
        )
    end
end

# Frank-Tamm spectrum: dE/dx per unit wavelength for a superluminal particle
# vals[i] = 2*pi*alpha * (1 - 1/(v^2*n^2)) / lambda_i^2
function frank_tamm(v::Float64, n::Float64)::Vector{Float64}
    alpha = 0.0072973525693   # fine-structure constant
    vals = Vector{Float64}(undef, nCIESamples)
    for i in 1:nCIESamples
        w = CIE_lambda[i] * 1e-9  # nm -> m
        vals[i] = 2.0 * pi * alpha * (1.0 - 1.0 / (v^2 * n^2)) / (w^2)
    end
    return vals
end

# Cherenkov emission direction: rotate particle direction d by Cherenkov angle theta,
# then by random azimuthal angle phi around d.
function cherenkov_direction(d::Vec3, u::Pnt2, v::Float64, n::Float64)::Vec3
    phi   = 2.0 * pi * u.x
    theta = acos(clamp(1.0 / (v * n), -1.0, 1.0))

    # build a perpendicular axis to d
    ax = abs(d.x) < 0.1 ? Vec3(1.0, 0.0, 0.0) : Vec3(0.0, 1.0, 0.0)
    r  = normalize(cross(d, ax))

    # rotate d by theta around r, then by phi around d
    R_theta = Rotate(rad2deg(theta), r)
    R_phi   = Rotate(rad2deg(phi), d)
    return normalize(Vec3(R_phi(R_theta(d))))
end

# Called once after BVH is built. Traces each particle through the scene and
# finds the superluminal intervals + Frank-Tamm spectra.
function preprocess!(light::ParticleEmitter, bvh::BVHAccel)
    rng = MersenneTwister(light.seed)

    # Spawn particles: sample points + normals on the shape surface
    empty!(light.particles)
    for _ in 1:light.n_particles
        u = Pnt2(rand(rng), rand(rng))
        p, n, _, _ = sample(light.shape, u)
        d = normalize(Vec3(n))
        push!(light.particles, ParticleEmitterParticle(p, d, light.range))
    end

    ft_vals_all = Vector{Vector{Vector{Float64}}}()
    tot_length  = 0.0
    sl_length   = 0.0

    for (pi_idx, particle) in enumerate(light.particles)
        ints    = SLInterval[]
        ft_raw  = Vector{Vector{Float64}}()

        ray    = RayDifferential(Ray(particle.origin, particle.direction, 0.0, particle.range))
        n_ior  = light.ambient_eta
        t_prev = 0.0
        p_prev = particle.origin
        last_prim = nothing

        while true
            hit, t_hit, si = intersect!(bvh, ray)
            if !hit || si isa Nothing
                break
            end
            # remaining distance from the original origin
            nt = norm(Vec3(p_prev - si.core.p))
            # is particle superluminal in [p_prev, si.core.p]?
            if light.velocity > 1.0 / n_ior
                push!(ints, (t_prev, t_prev + nt, n_ior))
                push!(ft_raw, frank_tamm(light.velocity, n_ior))
                sl_length += nt
            end

            # update IoR by reading eta directly from the material (avoids compute_scattering!)
            mat_eta = nothing
            if !(si.primitive isa Nothing) && !(si.primitive.material isa Nothing)
                mat = MATERIAL_REGISTRY[].materials[MATERIAL_REGISTRY[].name_to_index[si.primitive.material]]
                if mat isa Glass
                    mat_eta = mat.idx(si)
                end
            end

            if si.primitive == last_prim
                n_ior     = light.ambient_eta
                last_prim = nothing
            elseif !(mat_eta isa Nothing)
                n_ior     = mat_eta
                last_prim = si.primitive
            end

            t_prev = t_prev + nt
            p_prev = si.core.p
            # spawn continuation ray from hit point
            ray = spawn_ray(si.core, particle.direction)
            ray.tMax = particle.range - t_prev
            if ray.tMax <= 0.0
                break
            end
        end

        push!(ft_vals_all, ft_raw)
        push!(light.intervals, ints)
        tot_length += particle.range
    end

    # Normalize Frank-Tamm spectra by global max, then scale by cherenkov_scale
    normc = 0.0
    for ft in ft_vals_all
        for s in ft
            for v in s
                normc = max(normc, v)
            end
        end
    end

    for (i, ft) in enumerate(ft_vals_all)
        spectra = Spectrum[]
        for s in ft
            scaled = [light.cherenkov_scale * (v / max(normc, eps())) for v in s]
            push!(spectra, spectrum_from_sampled(CIE_lambda, scaled, nCIESamples))
        end
        push!(light.ft_spectra, spectra)
    end

    light.particle_length      = tot_length
    light.superluminal_length  = sl_length
    light.prob_sl              = sl_length / max(tot_length, eps())

    println("ParticleEmitter preprocess: $(length(light.particles)) particles, " *
            "$(sl_length) superluminal length / $(tot_length) total")
end

# Direct hit on the emitter disk returns no light (only particle paths emit)
function L(light::ParticleEmitter, n::Nml3, w::Vec3, uv::Pnt2)::Spectrum
    return spectrum_from_float(0.0)
end

function le(light::ParticleEmitter, ray::AbstractRay)::Spectrum
    return spectrum_from_float(0.0)
end

function power(light::ParticleEmitter)::Spectrum
    s = spectrum_from_float(0.0)
    for (i, ivs) in enumerate(light.intervals)
        for (j, iv) in enumerate(ivs)
            l = iv[2] - iv[1]
            s = s + light.ft_spectra[i][j] * l
        end
    end
    return s
end

# sample_li: particle paths are not sampleable from a ref point; delegate to L=0
function sample_li(light::ParticleEmitter, interaction::Interaction, u::Pnt2)::Tuple{Spectrum, Vec3, Float64, VisibilityTester, Pnt3, Nml3}
    p_shape, n_shape, _, pdf_val = sample(light.shape, interaction, u)
    if pdf_val == 0.0 || norm(Vec3(p_shape - interaction.p))^2 == 0.0
        return spectrum_from_float(0.0), Vec3(0,0,1), 0.0,
               VisibilityTester(interaction, interaction), Pnt3(0,0,0), Nml3(0,0,0)
    end
    wi = normalize(Vec3(p_shape - interaction.p))
    vis = VisibilityTester(interaction, Interaction(p_shape, interaction.t, Nml3(n_shape)))
    return L(light, n_shape, -wi, Pnt2(0,0)), wi, pdf_val, vis, p_shape, n_shape
end

function pdf_li(light::ParticleEmitter, isect::SurfaceInteraction, wi::Vec3)::Float64
    return pdf(light.shape, isect.core, wi)
end

function pdf_li(light::ParticleEmitter, isect::Interaction, wi::Vec3)::Float64
    return pdf(light.shape, isect, wi)
end

# sample_le: main sampling path for BDPT/VolPath NEE
function sample_le(light::ParticleEmitter, u1::Pnt2, u2::Pnt2, t::Float64)::Tuple{Spectrum, RayDifferential, Nml3, Float64, Float64}
    if isempty(light.particles)
        # Fallback: sample as a normal area light
        p_shape, n_light, _, _ = sample(light.shape, u1)
        w = cosine_sample_hemisphere(u2)
        pdf_dir = cosine_hemisphere_pdf(w.z)
        n_light_v, v1, v2 = orthonormal_basis(Vec3(n_light))
        W = w.x * v1 + w.y * v2 + w.z * n_light_v
        ray = spawn_ray(Interaction(p_shape, t, n_light), W)
        return L(light, n_light, W, Pnt2(0,0)), ray, n_light, pdf(light.shape), pdf_dir
    end

    # u1.x -> select particle, u1.y -> select t along path
    pi_idx = clamp(Int64(floor(u1.x * length(light.particles))) + 1, 1, length(light.particles))
    particle = light.particles[pi_idx]
    t_sample = particle.range * u1.y
    pp = Pnt3(particle.origin + t_sample * particle.direction)

    # Check if superluminal at t_sample
    s           = spectrum_from_float(0.0)
    superluminal = false
    n_local      = 1.0
    if pi_idx <= length(light.intervals)
        for (j, iv) in enumerate(light.intervals[pi_idx])
            if iv[1] <= t_sample <= iv[2]
                superluminal = true
                n_local = iv[3]
                s = light.ft_spectra[pi_idx][j]
                break
            end
        end
    end

    if superluminal
        w = cherenkov_direction(particle.direction, u2, light.velocity, n_local)
        n_out = Nml3(w)
        ray = RayDifferential(Ray(pp, w, t, typemax(Float64)))
        # Cherenkov: fixed polar angle theta_c, uniform azimuth phi.
        # PDF on the unit sphere for a ring at theta_c is 1/(2π·sin(θ_c)).
        theta_c = acos(clamp(1.0 / (light.velocity * n_local), -1.0, 1.0))
        pdf_dir = 1.0 / (2.0 * pi * sin(theta_c))
    else
        # Sub-threshold segment: no emission (uniform_scale is an optional debug hack)
        if light.uniform_scale > 0.0
            w = random_on_sphere(u2)
            n_out = Nml3(w)
            ray = RayDifferential(Ray(pp, Vec3(w), t, typemax(Float64)))
            s = spectrum_from_float(light.uniform_scale)
            pdf_dir = 1.0 / (4.0 * pi)
        else
            return spectrum_from_float(0.0), RayDifferential(Ray(pp, Vec3(0,1,0), t, 0.0)),
                   Nml3(0,1,0), 1.0, 1.0
        end
    end

    pdf_pos = 1.0 / max(light.particle_length, eps())

    return s, ray, n_out, pdf_pos, pdf_dir
end

function pdf_le(light::ParticleEmitter, ray::AbstractRay, n::Nml3)::Tuple{Float64, Float64}
    pdf_pos = 1.0 / max(light.particle_length, eps())
    pdf_dir = (1.0 + light.prob_sl) / (4.0 * pi)
    return pdf_pos, pdf_dir
end
