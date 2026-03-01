struct SeperableBSSRDFAdapter <: AbstractBxDF
	type::UInt8
	bssrdf::AbstractBSSRDF

    function SeperableBSSRDFAdapter(bssrdf::AbstractBSSRDF)
		bxdf = BSDF_GLOSSY | BSDF_REFLECTION | BSDF_TRANSMISSION
        return new(BSDF_REFLECTION | BSDF_DIFFUSE, bssrdf)
    end
end

function f(adapter::SeperableBSSRDFAdapter, wo::Vec3, wi::Vec3)::Spectrum
    f_val = Sw(adapter.bssrdf, wi)
    # Update BSSRDF transmission term to account for adjoint light transport
    if adapter.bssrdf.seperable_bssrdf.mode == Radiance
        f_val *= adapter.bssrdf.seperable_bssrdf.eta ^ 2
    end
    return f_val
end

function Sw(bssrdf::AbstractBSSRDF, w::Vec3)::Spectrum
    c = 1.0 - 2.0 * fresnel_moment_1(1.0 / bssrdf.seperable_bssrdf.eta)
    x = (1.0 - fresnel_dielectric(cos_theta(w), 1.0, bssrdf.seperable_bssrdf.eta)) / (c * pi)
    return spectrum_from_float(x)
end

# new file because 'Scene' dependency >:(
function sample_s(bssrdf::AbstractBSSRDF, scene::Scene, u1::Float64, u2::Pnt2)::Tuple{Spectrum, SurfaceInteraction, Float64}
    si = empty_surface_interation()
    Sp, si, pdf_val = sample_sp(bssrdf, scene, u1, u2, si)
    if !is_black(Sp)
        # Initialize material model at sampled surface interaction
        si.bsdf = BSDF(si, 1.0, (SeperableBSSRDFAdapter(bssrdf),))
        si.core.wo = Vec3(si.shading.n)
    end
    return Sp, si, pdf_val
end

function sample_sp(bssrdf::AbstractBSSRDF, scene::Scene, u1::Float64, u2::Pnt2, si::SurfaceInteraction)::Tuple{Spectrum, SurfaceInteraction, Float64}
    # @info "why: $u1, god: $u2"
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
    @info "beep boop integrating::sample_sr:: $r - $ch - $(u2[0 + 1])"
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
        @info "beep boop integrating::booping around $ray"
        
        if ray.direction == Vec3(0, 0, 0)
            break
        end
        
        hit, hit_t, si_tmp = intersect!(scene.b, ray)
        if !hit
            break
        end
        
        base = Interaction(si_tmp.core.p, si_tmp.core.t)
        # @info "beep boop integrating::booping around $base"
        
        # Only store admissible intersections
        if si_tmp.primitive.material === bssrdf.seperable_bssrdf.material_name
            # @info "PUSHHHHHH"
            push!(intersections, si_tmp)
        end
    end

    # Randomly choose one of the intersections
    nfound = length(intersections)
    nfound == 0 && return (spectrum_from_float(0.0, 0.0, 0.0), si, 0.0)
    
    selected_idx = clamp(floor(Int, u1 * nfound), 0, nfound - 1) + 1
    selected_si = intersections[selected_idx]
    @info "beep boop integrating::selected_si $selected_si"

    # Compute sample PDF and return the spatial BSSRDF term Sp
    pdf_val = pdf_sp(bssrdf, selected_si) / nfound
    @info "beep boop integrating::pdf_val $pdf_val"
    sp = Sp(bssrdf, selected_si)
    @info "beep boop integrating::sp $sp"
    return (sp, selected_si, pdf_val)
end

function Sr(bssrdf::AbstractBSSRDF, r::Float64)::Spectrum
    Sr_val = MVector{nSpectralSamples, Float64}(undef)
    for ch in 0:(nSpectralSamples - 1)
        # Convert $r$ into unitless optical radius $r_{\roman{optical}}$
        rOptical = r * bssrdf.sigma_t[ch + 1]

        # Compute spline weights to interpolate BSSRDF on channel _ch_
        table = get_material(bssrdf.seperable_bssrdf.material_name).table

        # Compute spline weights to interpolate BSSRDF density on channel _ch_
        rho_check, rho_offset, rho_weights = catmull_rom_weights(
            table.n_rho_samples, 
            table.rho_samples,
            bssrdf.rho[ch + 1]    
        )
        if !rho_check
            continue
        end
        radius_check, radius_offset, radius_weights = catmull_rom_weights(
            table.n_radius_samples, 
            table.radius_samples,
            rOptical  
        )  
        if !radius_check
            continue
        end  

        # Set BSSRDF value _Sr[ch]_ using tensor spline interpolation
        sr = 0.0
        for i in 0:3
            for j in 0:3
                weight = rho_weights[i + 1] * radius_weights[j + 1]
                if (weight != 0.0)
                    sr += weight * eval_profile(table, rho_offset + i, radius_offset + j)
                end
            end
        end

        # Cancel marginal PDF factor from tabulated BSSRDF profile
        if (rOptical != 0.0) 
            sr /= 2 * pi * rOptical
        end
        Sr_val[ch + 1] = sr
    end

    # Transform BSSRDF value into world space units
    Sr_val .*= bssrdf.sigma_t .* bssrdf.sigma_t
    return Sr_val
end

function Sp(bssrdf::AbstractBSSRDF, p_i::SurfaceInteraction)::Spectrum
    return Sr(bssrdf, distance(bssrdf.seperable_bssrdf.po.core.p, p_i.core.p))
end

function pdf_sr(bssrdf::AbstractBSSRDF, ch::Int64, r::Float64)::Float64
    # Convert $r$ into unitless optical radius $r_{\roman{optical}}$
    rOptical = r * bssrdf.sigma_t[ch + 1]

    table = get_material(bssrdf.seperable_bssrdf.material_name).table

    # Compute spline weights to interpolate BSSRDF density on channel _ch_
    rho_check, rho_offset, rho_weights = catmull_rom_weights(
        table.n_rho_samples, 
        table.rho_samples,
        bssrdf.rho[ch + 1]    
    )
    if !rho_check
        return 0.0
    end
    radius_check, radius_offset, radius_weights = catmull_rom_weights(
        table.n_radius_samples, 
        table.radius_samples,
        rOptical  
    )  
    if !radius_check
        return 0.0
    end  
    # @info "beeb boop integrating::pdf_sr $r - $(bssrdf.sigma_t) - $ch - $rOptical"
    # @info "beeb boop integrating::pdf_sr $rho_offset $radius_offset"
    # @info "beeb boop integrating::pdf_sr $rho_weights" 
    # @info "beeb boop integrating::pdf_sr $radius_weights"

    # Return BSSRDF profile density for channel _ch_
    sr = 0.0
    rhoEff = 0.0
    for i in 0:3
        if (rho_weights[i + 1] == 0.0) 
            continue
        end
        rhoEff += table.rho_eff[rho_offset + i + 1] * rho_weights[i + 1]
        for j in 0:3
            if radius_weights[j + 1] == 0.0
                continue
            end
            sr += eval_profile(table, rho_offset + i, radius_offset + j) * rho_weights[i + 1] * radius_weights[j + 1]
        end
    end

    # Cancel marginal PDF factor from tabulated BSSRDF profile
    if (rOptical != 0.0) 
        sr /= 2 * pi * rOptical
    end
    return max(0.0, sr * bssrdf.sigma_t[ch + 1] * bssrdf.sigma_t[ch + 1] / rhoEff)
end

function pdf_sp(bssrdf::AbstractBSSRDF, p_i::SurfaceInteraction)::Float64
    # Express $\pti-\pto$ and $\bold{n}_i$ with respect to local coordinates at $\pto$
    d = bssrdf.seperable_bssrdf.po.core.p - p_i.core.p
    dLocal = Vec3(
        dot(bssrdf.seperable_bssrdf.ss, d), 
        dot(bssrdf.seperable_bssrdf.ts, d), 
        dot(bssrdf.seperable_bssrdf.ns, d)
    )
    nLocal = Nml3(
        dot(bssrdf.seperable_bssrdf.ss, p_i.core.n), 
        dot(bssrdf.seperable_bssrdf.ts, p_i.core.n), 
        dot(bssrdf.seperable_bssrdf.ns, p_i.core.n)
    )

    # Compute BSSRDF profile radius under projection along each axis
    rProj = SVector(
        sqrt(dLocal.y * dLocal.y + dLocal.z * dLocal.z),
        sqrt(dLocal.z * dLocal.z + dLocal.x * dLocal.x),
        sqrt(dLocal.x * dLocal.x + dLocal.y * dLocal.y)
    )

    # @info "beep boop integrating:: $dLocal"
    # @info "beep boop integrating:: $nLocal"
    # @info "beep boop integrating:: $rProj"

    # Return combined probability from all BSSRDF sampling strategies
    pdf_val = 0.0 
    axisProb = SVector(0.25, 0.25, 0.5)
    chProb = 1.0 / nSpectralSamples
    for axis in 0:2
        for ch in 0:(nSpectralSamples - 1)
            # @info "beep boop integrating:: $axis - $ch - $(pdf_sr(bssrdf, ch, rProj[axis + 1]))"
            pdf_val += pdf_sr(bssrdf, ch, rProj[axis + 1]) * abs(nLocal[axis + 1]) * chProb * axisProb[axis + 1]
        end
    end
    return pdf_val
end

function sample_sr(bssrdf::AbstractBSSRDF, ch::Int64, u::Float64)::Float64
    if bssrdf.sigma_t[ch + 1] == 0
        return -1.0
    end
    mat = get_material(bssrdf.seperable_bssrdf.material_name)
    f_val, _, _ = sample_catmull_rom_2D(
        mat.table.n_rho_samples,
        mat.table.n_radius_samples,
        mat.table.rho_samples,
        mat.table.radius_samples,
        mat.table.profile,
        mat.table.profile_cdf,
        bssrdf.rho[ch + 1], 
        u
    )
    return f_val / bssrdf.sigma_t[ch + 1] 
end 