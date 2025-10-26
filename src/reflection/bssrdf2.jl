# new file because 'Scene' dependency >:(
function sample_s(bssrdf::AbstractBSSRDF, scene::Scene, u1::Float64, u2::Pnt2)::Tuple{Spectrum, SurfaceInteraction, Float64}
    si = empty_surface_interation()
    Sp, si, pdf_val = sample_sp(bssrdf, scene, u1, u2, si)
    if !is_black(Sp)
        # Initialize material model at sampled surface interaction
        si.bsdf = BSDF(si)
        add!(si.bsdf, SeperableBSSRDFAdapter(bssrdf))
        si.core.wo = Vec3(si.shading.n)
    end
    return Sp, si, pdf_val
end

function sample_sp(bssrdf::AbstractBSSRDF, scene::Scene, u1::Float64, u2::Pnt2, si::SurfaceInteraction)::Tuple{Spectrum, SurfaceInteraction, Float64}
    # Choose projection axis for BSSRDF sampling
    if (u1 < 0.5)
        vx = bssrdf.seperable_bssrdf.ss
        vy = bssrdf.seperable_bssrdf.ts
        vz = Vec3(bssrdf.seperable_bssrdf.ns)
        u1 *= 2
    elseif (u1 < .75)
        # Prepare for sampling rays with respect to _ss_
        vx = bssrdf.seperable_bssrdf.ts
        vy = Vec3(bssrdf.seperable_bssrdf.ns)
        vz = bssrdf.seperable_bssrdf.ss
        u1 = (u1 - .5) * 4.0
    else
        # Prepare for sampling rays with respect to _ts_
        vx = Vec3(bssrdf.seperable_bssrdf.ns)
        vy = bssrdf.seperable_bssrdf.ss
        vz = bssrdf.seperable_bssrdf.ts
        u1 = (u1 - 0.75) * 4.0
    end
    
    ## Choose spectral channel for BSSRDF sampling
    ch = clamp(Int(floor(u1 * nSpectralSamples)), 0, nSpectralSamples - 1)
    u1 = u1 * nSpectralSamples - ch

    # Sample BSSRDF profile in polar coordinates
    r = sample_sr(bssrdf, ch, u2[0 + 1])
    @info "beep boop integrating::sample_sr:: $r"
    if (r < 0.0)
        return spectrum_from_float(0.0), si, 0.0
    end
    phi = 2 * pi * u2[1 + 1]

    # Compute BSSRDF profile bounds and intersection height
    rMax = sample_sr(bssrdf, ch, 0.999)
    @info "beep boop integrating::sample_sr:: $rMax"
    if (r >= rMax)
        return spectrum_from_float(0.0), si, 0.0
    end
    l = 2 * sqrt(rMax * rMax - r * r)

    # Compute BSSRDF sampling ray segment
    base = Interaction(
        bssrdf.seperable_bssrdf.po.core.p + r * (vx * cos(phi) + vy * sin(phi)) - l * vz * 0.5,
        bssrdf.seperable_bssrdf.po.core.t
    )
    @info "beep boop integratint::interaction $base"
    p_target = base.p + l * vz

    # Pre-allocate vector for valid intersections
    intersections = SurfaceInteraction[]
    sizehint!(intersections, 8)  # hint expected capacity to reduce allocations
    
    while true
        ray = spawn_ray_to(base, p_target)
        
        if ray.direction == Vec3(0, 0, 0)
            break
        end
        
        hit, hit_t, si_tmp = intersect!(scene.b, ray)
        if !hit
            break
        end
        
        base = Interaction(si_tmp.p, si_tmp.time)
        @info "beep boop integratint::booping around $base"
        
        # Only store admissible intersections
        if get_material(si_tmp.primitive) === bssrdf.material
            push!(intersections, si_tmp)
        end
    end

    # Randomly choose one of the intersections
    nfound = length(intersections)
    nfound == 0 && return (spectrum_from_float(0.0, 0.0, 0.0), si, 0.0)
    
    selected_idx = clamp(floor(Int, u1 * nfound), 0, nfound - 1) + 1
    selected_si = intersections[selected_idx]
    @info "beep boop integratint::selected_si $selected_si"

    # Compute sample PDF and return the spatial BSSRDF term Sp
    pdf_val = pdf_sp(bssrdf, selected_si) / nfound
    sp = sp(bssrdf, selected_si)
    return (sp, selected_si, pdf_val)
end

    # Intersect BSSRDF sampling ray against the scene geometry
    # // Declare _IntersectionChain_ and linked list
    # struct IntersectionChain {
    #     SurfaceInteraction si;
    #     IntersectionChain *next = nullptr;
    # };
    # IntersectionChain *chain = ARENA_ALLOC(arena, IntersectionChain)();

    # // Accumulate chain of intersections along ray
    # IntersectionChain *ptr = chain;
    # int nFound = 0;
    # while (true) {
    #     Ray r = base.SpawnRayTo(pTarget);
    #     if (r.d == Vector3f(0, 0, 0) || !scene.Intersect(r, &ptr->si))
    #         break;

    #     base = ptr->si;
    #     // Append admissible intersection to _IntersectionChain_
    #     if (ptr->si.primitive->GetMaterial() == this->material) {
    #         IntersectionChain *next = ARENA_ALLOC(arena, IntersectionChain)();
    #         ptr->next = next;
    #         ptr = next;
    #         nFound++;
    #     }
    # }

    # // Randomly choose one of several intersections during BSSRDF sampling
    # if (nFound == 0) return Spectrum(0.0f);
    # int selected = Clamp((int)(u1 * nFound), 0, nFound - 1);
    # while (selected-- > 0) chain = chain->next;
    # *pi = chain->si;

    # // Compute sample PDF and return the spatial BSSRDF term $\Sp$
    # *pdf = this->Pdf_Sp(*pi) / nFound;
    # return this->Sp(*pi);

function sample_sr(bssrdf::AbstractBSSRDF, ch::Int64, u::Float64)::Float64
    if bssrdf.sigma_t[ch + 1] == 0
        return -1.0
    end
    f_val, _, _ = sample_catmull_rom_2D(
        bssrdf.seperable_bssrdf.material.table.n_rho_samples,
        bssrdf.seperable_bssrdf.material.table.n_radius_samples,
        bssrdf.seperable_bssrdf.material.table.rho_samples,
        bssrdf.seperable_bssrdf.material.table.radius_samples,
        bssrdf.seperable_bssrdf.material.table.profile,
        bssrdf.seperable_bssrdf.material.table.profile_cdf,
        bssrdf.rho[ch + 1], 
        u
    )
    return f_val / bssrdf.sigma_t[ch + 1] 
end 