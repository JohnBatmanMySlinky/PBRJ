# SPPM - Stochastic Progressive Photon Mapping
# PBRT v3 Chapter 16.4
# Handles caustic transport paths (L S* D) that BDPT and VolPath struggle with.
# Designed specifically for the ParticleEmitter Cherenkov light in scene23.

struct SPPMIntegrator <: AbstractIntegrator
    camera::C where C <: Camera
    sampler::S where S <: AbstractSampler
    max_depth::Int64
    n_iterations::Int64
    photons_per_iter::Int64
    initial_radius::Float64

    function SPPMIntegrator(
        camera::C where C <: Camera, 
        sampler::S where S <: AbstractSampler, 
        film::Film,
        max_depth::Int64,
        n_iterations::Int64,
        photons_per_iter::Int64,
        initial_radius::Float64
    )
        photons_per_iter = photons_per_iter > 0 ? photons_per_iter : area(film.cropped_pixel_bounds)
        return new(camera, sampler, max_depth, n_iterations, photons_per_iter, initial_radius)
    end
end

# Per-pixel accumulation state, persists across all iterations
mutable struct SPPMPixel
    # Visible point (overwritten each camera pass)
    vp_p::Pnt3
    vp_wo::Vec3
    vp_bsdf::Maybe{AbstractBSDF}
    vp_beta::Spectrum        # path throughput to this visible point
    vp_valid::Bool

    # Per-iteration photon accumulation (reset at start of each photon pass)
    phi::Spectrum
    M::Int64                 # photons that landed in radius this iteration

    # Across-iteration state
    radius::Float64          # current search radius
    N::Float64               # total weighted photon count so far
    tau::Spectrum            # total accumulated flux (scaled for radius changes)

    # Direct illumination (summed over all camera passes, divided at the end)
    Ld::Spectrum
end

function SPPMPixel(initial_radius::Float64)::SPPMPixel
    return SPPMPixel(
        Pnt3(0.0), Vec3(0.0), nothing, spectrum_from_float(0.0), false,
        spectrum_from_float(0.0), 0,
        initial_radius, 0.0, spectrum_from_float(0.0),
        spectrum_from_float(0.0)
    )
end

# ─── Spatial grid ────────────────────────────────────────────────────────────

struct SPPMGrid
    # Flat hash table: grid_heads[h] = first node index in bucket (0 = empty)
    grid_heads::Vector{Int32}
    # Pool-allocated singly-linked lists
    node_pixel::Vector{Int32}   # which pixel this node refers to
    node_next::Vector{Int32}    # next node index (0 = end of list)
    bounds::Bounds3
    cell_size::Float64
    grid_size::Int64            # length of grid_heads (power of 2)
end

@inline function cell_hash(ix::Int64, iy::Int64, iz::Int64, grid_size::Int64)::Int64
    h = (ix * 73856093) ⊻ (iy * 19349663) ⊻ (iz * 83492791)
    return (h % grid_size + grid_size) % grid_size + 1   # 1-based
end

function build_grid(pixels::Vector{SPPMPixel}, max_radius::Float64)::SPPMGrid
    bounds = Bounds3(Pnt3(Inf), Pnt3(-Inf))
    for px in pixels
        px.vp_valid || continue
        sp = Bounds3(px.vp_p - Vec3(px.radius), px.vp_p + Vec3(px.radius))
        bounds = world_bounds(bounds, sp)
    end

    cell_size = 2.0 * max_radius

    # Count total (pixel, cell) pairs so we can allocate exactly
    n_nodes = 0
    for px in pixels
        px.vp_valid || continue
        p_min = floor.((px.vp_p - Vec3(px.radius) - bounds.pMin) ./ cell_size)
        p_max = floor.((px.vp_p + Vec3(px.radius) - bounds.pMin) ./ cell_size)
        n_nodes += prod(Int64.(p_max .- p_min) .+ 1)
    end

    n_valid   = count(px.vp_valid for px in pixels)
    grid_size = nextpow(2, max(n_valid * 2, 64))

    grid_heads = zeros(Int32, grid_size)
    node_pixel = Vector{Int32}(undef, n_nodes)
    node_next  = Vector{Int32}(undef, n_nodes)
    node_count = 0

    for (i, px) in enumerate(pixels)
        px.vp_valid || continue
        p_min = Pnt3(floor.((px.vp_p - Vec3(px.radius) - bounds.pMin) ./ cell_size))
        p_max = Pnt3(floor.((px.vp_p + Vec3(px.radius) - bounds.pMin) ./ cell_size))
        for iz in Int64(p_min.z):Int64(p_max.z)
            for iy in Int64(p_min.y):Int64(p_max.y)
                for ix in Int64(p_min.x):Int64(p_max.x)
                    h = cell_hash(ix, iy, iz, grid_size)
                    node_count += 1
                    node_pixel[node_count] = Int32(i)
                    node_next[node_count]  = grid_heads[h]
                    grid_heads[h]          = Int32(node_count)
                end
            end
        end
    end

    return SPPMGrid(grid_heads, node_pixel, node_next, bounds, cell_size, grid_size)
end

# ─── Camera pass ─────────────────────────────────────────────────────────────

function sppm_camera_pass!(
    pixels::Vector{SPPMPixel},
    integrator::SPPMIntegrator,
    scene::Scene,
    iter::Int64
)
    film = integrator.camera.core.core.film
    sample_bounds = get_sample_bounds(film)
    sample_extent = diagonal(sample_bounds)
    tile_size = 16
    n_tiles = Pnt2i(floor.((sample_extent .+ tile_size .- 1) ./ tile_size))
    total_tiles = n_tiles.x * n_tiles.y

    light_distr = LightDistribution("uniform", scene)
    w = film.full_resolution.x

    Threads.@threads for k in 0:(total_tiles - 1)
        tile = Pnt2i(k % n_tiles.x, k ÷ n_tiles.x)
        seed::Int64 = iter * total_tiles + tile.y * n_tiles.x + tile.x
        sampler = clone(integrator.sampler, seed)

        x0 = sample_bounds.pMin.x + tile.x * tile_size
        x1 = min(x0 + tile_size, sample_bounds.pMax.x)
        y0 = sample_bounds.pMin.y + tile.y * tile_size
        y1 = min(y0 + tile_size, sample_bounds.pMax.y)
        tile_bounds = Bounds2i(Pnt2i(x0, y0), Pnt2i(x1, y1))

        for pixel in tile_bounds
            # pixel index into flat pixel array
            px_idx = (pixel.x - sample_bounds.pMin.x) +
                     (pixel.y - sample_bounds.pMin.y) * (sample_bounds.pMax.x - sample_bounds.pMin.x) + 1
            px = pixels[px_idx]
            px.vp_valid = false

            start_pixel_sample!(sampler, pixel, 0)
            camera_sample = get_camera_sample!(sampler, pixel)
            ray, wt = generate_ray_differential(integrator.camera, camera_sample)
            wt == 0.0 && continue
            ray = scale_differentials(ray, 1.0 / sqrt(Float64(integrator.sampler.samples_per_pixel)))

            beta::Spectrum = spectrum_from_float(wt)
            specular_bounce::Bool = false

            for depth in 0:(integrator.max_depth - 1)
                hit, t, si = intersect!(scene.b, ray)
                if !hit
                    # escaped — accumulate infinite light emission
                    for light in scene.lights
                        if is_infinite_light(light)
                            px.Ld += beta * le(light, ray)
                        end
                    end
                    break
                end

                # Surface hit
                compute_scattering!(si, ray, true, Radiance)
                if si.bsdf isa Nothing
                    # null surface (medium boundary) — continue straight through
                    ray = spawn_ray(si.core, ray.direction)
                    depth -= 1
                    continue
                end

                wo::Vec3 = si.core.wo

                # Accumulate emission from area lights hit directly
                if depth == 0 || specular_bounce
                    px.Ld += beta * le(si, wo)
                end

                # Direct illumination at this visible point
                if length(scene.lights) > 0
                    light_distr_local = lookup(light_distr, si.core.p)
                    light_idx, light_pdf, _ = sample_discrete(light_distr_local, get_1D!(sampler))
                    light = scene.lights[light_idx]
                    Ld = estimate_direct(si, si.bsdf, get_2D!(sampler), light, get_2D!(sampler), scene, sampler, false, false)
                    px.Ld += beta * Ld / light_pdf
                end

                is_diffuse = num_components(si.bsdf, BSDF_DIFFUSE | BSDF_REFLECTION | BSDF_TRANSMISSION) > 0
                is_glossy  = num_components(si.bsdf, BSDF_GLOSSY  | BSDF_REFLECTION | BSDF_TRANSMISSION) > 0

                if is_diffuse || (is_glossy && depth == integrator.max_depth - 1)
                    # Store visible point at diffuse surface (or glossy at max depth)
                    px.vp_p    = si.core.p
                    px.vp_wo   = wo
                    px.vp_bsdf = si.bsdf
                    px.vp_beta = beta
                    px.vp_valid = true
                    break
                end

                # Continue path: specular or glossy below max_depth
                wi, f, pdf_val, sampled_type = sample_f(si.bsdf, wo, get_2D!(sampler), BSDF_ALL)
                if is_black(f) || pdf_val == 0.0
                    break
                end
                specular_bounce = (sampled_type & BSDF_SPECULAR != 0)
                beta *= f * abs(dot(wi, Vec3(si.shading.n))) / pdf_val
                ray = spawn_ray(si.core, wi)
            end
        end
    end
end

# ─── Photon pass ─────────────────────────────────────────────────────────────

function sppm_photon_pass!(
    pixels::Vector{SPPMPixel},
    grid::SPPMGrid,
    integrator::SPPMIntegrator,
    scene::Scene,
    iter::Int64
)
    light_distr = LightDistribution("power", scene)
    sampler = clone(integrator.sampler, iter)

    for photon_idx in 1:integrator.photons_per_iter
        start_pixel_sample!(sampler, Pnt2i(photon_idx - 1, iter - 1), 0)

        # Sample a light and generate an initial photon ray
        u_light_sel = get_1D!(sampler)
        u_light     = get_2D!(sampler)
        u_dir       = get_2D!(sampler)

        light_idx, light_pdf, _ = sample_discrete(light_distr.distr, u_light_sel)
        light_pdf == 0.0 && continue
        light = scene.lights[light_idx]

        Le, ray, n_light, pdf_pos, pdf_dir = sample_le(light, u_light, u_dir, 0.0)
        (is_black(Le) || pdf_pos == 0.0 || pdf_dir == 0.0) && continue

        beta::Spectrum = Le * abs(dot(n_light, Nml3(ray.direction))) /
                         (light_pdf * pdf_pos * pdf_dir)
        is_black(beta) && continue

        for depth in 0:(integrator.max_depth - 1)
            hit, _, si = intersect!(scene.b, ray)
            !hit && break

            compute_scattering!(si, ray, true, Importance)
            if si.bsdf isa Nothing
                ray = spawn_ray(si.core, ray.direction)
                depth -= 1
                continue
            end

            wo::Vec3 = si.core.wo
            is_specular_surf = (num_components(si.bsdf, BSDF_ALL & ~BSDF_SPECULAR) == 0)

            if !is_specular_surf && depth > 0
                # Deposit photon: look up the single cell the photon lands in.
                # VPs are already registered in ALL cells their radius sphere overlaps
                # (see build_grid), so checking one cell is sufficient — checking
                # neighbors would cause each photon to match the same VP multiple times.
                rel = si.core.p - grid.bounds.pMin
                cx  = Int64(floor(rel.x / grid.cell_size))
                cy  = Int64(floor(rel.y / grid.cell_size))
                cz  = Int64(floor(rel.z / grid.cell_size))
                h    = cell_hash(cx, cy, cz, grid.grid_size)
                node = Int64(grid.grid_heads[h])
                while node != 0
                    px_idx = Int64(grid.node_pixel[node])
                    px = pixels[px_idx]
                    if px.vp_valid
                        dist2 = sum((si.core.p - px.vp_p).^2)
                        if dist2 <= px.radius^2
                            wi_p = -ray.direction
                            f    = px.vp_bsdf(px.vp_wo, wi_p, BSDF_ALL)
                            if !is_black(f)
                                px.phi += f * beta
                                px.M   += 1
                            end
                        end
                    end
                    node = Int64(grid.node_next[node])
                end
            end

            # Continue photon path (specular or Russian roulette on diffuse)
            wi, f, pdf_val, sampled_type = sample_f(si.bsdf, wo, get_2D!(sampler), BSDF_ALL)
            (is_black(f) || pdf_val == 0.0) && break
            beta_new = beta * f * abs(dot(wi, Vec3(si.shading.n))) / pdf_val
            # Russian roulette
            q = max(0.05, 1.0 - y_spectrum(beta_new) / y_spectrum(beta))
            get_1D!(sampler) < q && break
            beta = beta_new / (1.0 - q)
            ray = spawn_ray(si.core, wi)
        end
    end
end

# ─── Radius update (progressive) ─────────────────────────────────────────────

function sppm_update_pixels!(pixels::Vector{SPPMPixel}, gamma::Float64 = 2.0/3.0)
    for px in pixels
        px.M == 0 && continue
        N_new  = px.N + gamma * Float64(px.M)
        r_new  = px.radius * sqrt(N_new / (px.N + Float64(px.M)))
        scale  = (r_new / px.radius)^2
        px.tau    = (px.tau + px.vp_beta * px.phi) * scale
        px.N      = N_new
        px.radius = r_new
        # reset per-iteration accumulators
        px.phi = spectrum_from_float(0.0)
        px.M   = 0
    end
end

# ─── render() ────────────────────────────────────────────────────────────────

function render(integrator::SPPMIntegrator, scene::Scene, parsed_args::Dict)::Array{RGB}
    film = integrator.camera.core.core.film
    sample_bounds = get_sample_bounds(film)
    n_pixels = length(sample_bounds)

    pixels = [SPPMPixel(integrator.initial_radius) for _ in 1:n_pixels]

    for iter in 1:integrator.n_iterations
        print("SPPM iter $(iter)/$(integrator.n_iterations): camera pass... ")
        sppm_camera_pass!(pixels, integrator, scene, iter)

        max_r = maximum(px.radius for px in pixels)
        n_valid = count(px.vp_valid for px in pixels)
        print("$(n_valid) visible pts. building grid... ")
        grid = build_grid(pixels, max_r)

        print("photon pass ($(integrator.photons_per_iter) photons)... ")
        sppm_photon_pass!(pixels, grid, integrator, scene, iter)

        n_hit = count(px.M > 0 for px in pixels)
        sppm_update_pixels!(pixels)

        avg_r = n_hit > 0 ? mean(px.radius for px in pixels if px.N > 0) : max_r
        print("$(n_hit) px hit. r_avg=$(round(avg_r, digits=4)) done.\n")
    end

    # ── Write final image ──────────────────────────────────────────────────
    # Direct illumination: average over all iterations (Ld was summed)
    # Indirect (photon):   tau / (total_photon_paths * pi * r^2)
    n_iter = Float64(integrator.n_iterations)
    n_phot = Float64(integrator.photons_per_iter)
    total_photon_paths = n_iter * n_phot

    sample_extent = diagonal(sample_bounds)
    w_pixels = Int64(sample_extent.x)

    for (i, px) in enumerate(pixels)
        # Map flat index back to pixel coords
        ix = (i - 1) % w_pixels
        iy = (i - 1) ÷ w_pixels
        p  = Pnt2(Float64(sample_bounds.pMin.x + ix) + 0.5,
                  Float64(sample_bounds.pMin.y + iy) + 0.5)

        L = px.Ld / n_iter
        if px.N > 0.0
            L += px.tau / (total_photon_paths * pi * px.radius^2)
        end

        add_splat!(film, p, L)
    end

    return save(film, 1.0)
end
