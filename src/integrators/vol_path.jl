function li(
    integrator::VolPathIntegrator, 
    ray::RayDifferential, 
    scene::Scene,
    depth::Int64,
    sampler::AbstractSampler
)
    
    # Declare state variables for volumetric path sampling
    L = spectrum_from_float(0.0)
    beta = spectrum_from_float(1.0)
    r_u = spectrum_from_float(1.0)
    r_l = spectrum_from_float(1.0)
    specularBounce = false
    anyNonSpecularBounces = false
    depth = 0
    etaScale = 1.0
    
    prevIntrContext = LightSampleContext()
    
    while true
        # Sample segment of volumetric scattering path
        @info "Path tracer depth $depth, current L = $L, beta = $beta\n"
        
        si = Intersect(ray)
        
        if !isnothing(ray.medium)
            # Sample the participating medium
            scattered = false
            terminated = false
            tMax = !isnothing(si) ? si.tHit : typemax(Float64)
                       
            T_maj = SampleT_maj(ray, tMax, Get1D!(sampler), sampler) do p, mp, sigma_maj, T_maj
                # Handle medium scattering event for ray
                if !beta
                    terminated = true
                    return false
                end
                
                volumeInteractions[] += 1
                
                # Add emission from medium scattering event
                if depth < integrator.maxDepth && !isnothing(mp.Le)
                    # Compute β' at new path vertex
                    pdf = sigma_maj[1] * T_maj[1]
                    betap = beta * T_maj / pdf
                    
                    # Compute rescaled path probability for absorption at path vertex
                    r_e = r_u * sigma_maj * T_maj / pdf
                    
                    # Update L for medium emission
                    if r_e
                        L += betap * mp.sigma_a * mp.Le / Average(r_e)
                    end
                end
                
                # Compute medium event probabilities for interaction
                pAbsorb = mp.sigma_a[1] / sigma_maj[1]
                pScatter = mp.sigma_s[1] / sigma_maj[1]
                pNull = max(0.0f0, 1.0f0 - pAbsorb - pScatter)
                
                @assert 1.0f0 - pAbsorb - pScatter >= -1e-6
                
                # Sample medium scattering event type and update path
                um = Get1D!(sampler)
                mode = SampleDiscrete([pAbsorb, pScatter, pNull], um)
                
                if mode == 1
                    # Handle absorption along ray path
                    terminated = true
                    return false
                    
                elseif mode == 2
                    # Handle scattering along ray path
                    # Stop path sampling if maximum depth has been reached
                    depth += 1
                    if depth >= integrator.maxDepth
                        terminated = true
                        return false
                    end
                    
                    # Update beta and r_u for real-scattering event
                    pdf = T_maj[1] * mp.sigma_s[1]
                    beta *= T_maj * mp.sigma_s / pdf
                    r_u *= T_maj * mp.sigma_s / pdf
                    
                    if beta && r_u
                        # Sample direct lighting at volume-scattering event
                        intr = MediumInteraction(p, -ray.d, ray.time, ray.medium, mp.phase)
                        L += SampleLd(intr, nothing, lambda, sampler, beta, r_u)
                        
                        # Sample new direction at real-scattering event
                        u = Get2D!(sampler)
                        ps = Sample_p(intr.phase, -ray.d, u)
                        
                        if isnothing(ps) || ps.pdf == 0
                            terminated = true
                        else
                            # Update ray path state for indirect volume scattering
                            beta *= ps.p / ps.pdf
                            r_l = r_u / ps.pdf
                            prevIntrContext = LightSampleContext(intr)
                            scattered = true
                            ray.o = p
                            ray.d = ps.wi
                            specularBounce = false
                            anyNonSpecularBounces = true
                        end
                    end
                    return false
                    
                else
                    # Handle null scattering along ray path
                    sigma_n = ClampZero(sigma_maj - mp.sigma_a - mp.sigma_s)
                    pdf = T_maj[1] * sigma_n[1]
                    beta *= T_maj * sigma_n / pdf
                    if pdf == 0
                        beta = spectrum_from_float(0.0)
                    end
                    r_u *= T_maj * sigma_n / pdf
                    r_l *= T_maj * sigma_maj / pdf
                    return beta && r_u
                end
            end
            
            # Handle terminated, scattered, and unscattered medium rays
            if terminated || !beta || !r_u
                return L
            end
            if scattered
                continue
            end
            
            beta *= T_maj / T_maj[1]
            r_u *= T_maj / T_maj[1]
            r_l *= T_maj / T_maj[1]
        end
        
        # Handle surviving unscattered rays
        # Add emitted light at volume path vertex or from the environment
        if isnothing(si)
            # Accumulate contributions from infinite light sources
            for light in integrator.infiniteLights
                Le = Le(light, ray, lambda)
                if Le
                    if depth == 0 || specularBounce
                        L += beta * Le / Average(r_u)
                    else
                        # Add infinite light contribution using both PDFs with MIS
                        p_l = PMF(integrator.lightSampler, prevIntrContext, light) *
                              PDF_Li(light, prevIntrContext, ray.d, true)
                        r_l *= p_l
                        L += beta * Le / Average(r_u + r_l)
                    end
                end
            end
            break
        end
        
        isect = si.intr
        Le = Le(isect, -ray.d, lambda)
        if Le
            # Add contribution of emission from intersected surface
            if depth == 0 || specularBounce
                L += beta * Le / Average(r_u)
            else
                # Add surface light contribution using both PDFs with MIS
                areaLight = Light(isect.areaLight)
                p_l = PMF(integrator.lightSampler, prevIntrContext, areaLight) *
                      PDF_Li(areaLight, prevIntrContext, ray.d, true)
                r_l *= p_l
                L += beta * Le / Average(r_u + r_l)
            end
        end
        
        # Get BSDF and skip over medium boundaries
        bsdf = GetBSDF(isect, ray, lambda, integrator.camera, scratchBuffer, sampler)
        if isnothing(bsdf)
            SkipIntersection(isect, ray, si.tHit)
            continue
        end
        
        # Initialize visibleSurf at first intersection
        if depth == 0 && !isnothing(visibleSurf)
            # Estimate BSDF's albedo
            # Define sample arrays ucRho and uRho for reflectance estimate
            nRhoSamples = 16
            ucRho = Float32[0.75741637, 0.37870818, 0.7083487, 0.18935409, 0.9149363, 0.35417435,
                           0.5990858, 0.09467703, 0.8578725, 0.45746812, 0.686759, 0.17708716,
                           0.9674518, 0.2995429, 0.5083201, 0.047338516]
            uRho = [Point2f(0.855985, 0.570367), Point2f(0.381823, 0.851844),
                    Point2f(0.285328, 0.764262), Point2f(0.733380, 0.114073),
                    Point2f(0.542663, 0.344465), Point2f(0.127274, 0.414848),
                    Point2f(0.964700, 0.947162), Point2f(0.594089, 0.643463),
                    Point2f(0.095109, 0.170369), Point2f(0.825444, 0.263359),
                    Point2f(0.429467, 0.454469), Point2f(0.244460, 0.816459),
                    Point2f(0.756135, 0.731258), Point2f(0.516165, 0.152852),
                    Point2f(0.180888, 0.214174), Point2f(0.898579, 0.503897)]
            
            albedo = rho(bsdf, isect.wo, ucRho, uRho)
            visibleSurf[] = VisibleSurface(isect, albedo, lambda)
        end
        
        # Terminate path if maximum depth reached
        depth += 1
        if depth >= integrator.maxDepth
            return L
        end
        
        surfaceInteractions[] += 1
        
        # Possibly regularize the BSDF
        if integrator.regularize && anyNonSpecularBounces
            regularizedBSDFs[] += 1
            Regularize!(bsdf)
        end
        
        # Sample illumination from lights to find attenuated path contribution
        if IsNonSpecular(Flags(bsdf))
            L += SampleLd(isect, bsdf, lambda, sampler, beta, r_u)
            @assert !isinf(y(L, lambda))
        end
        
        prevIntrContext = LightSampleContext(isect)
        
        # Sample BSDF to get new volumetric path direction
        wo = isect.wo
        u = Get1D!(sampler)
        bs = Sample_f(bsdf, wo, u, Get2D!(sampler))
        if isnothing(bs)
            break
        end
        
        # Update beta and rescaled path probabilities for BSDF scattering
        beta *= bs.f * AbsDot(bs.wi, isect.shading.n) / bs.pdf
        if bs.pdfIsProportional
            r_l = r_u / PDF(bsdf, wo, bs.wi)
        else
            r_l = r_u / bs.pdf
        end
        
        @info "Sampled BSDF, f = $(bs.f), pdf = $(bs.pdf) -> beta = $beta"
        @assert !isinf(y(beta, lambda))
        
        # Update volumetric integrator path state after surface scattering
        specularBounce = IsSpecular(bs)
        anyNonSpecularBounces |= !IsSpecular(bs)
        if IsTransmission(bs)
            etaScale *= bs.eta^2
        end
        ray = SpawnRay(isect, ray, bsdf, bs.wi, bs.flags, bs.eta)
        
        # Account for attenuated subsurface scattering, if applicable
        bssrdf = GetBSSRDF(isect, ray, lambda, integrator.camera, scratchBuffer)
        if !isnothing(bssrdf) && IsTransmission(bs)
            # Sample BSSRDF probe segment to find exit point
            uc = Get1D!(sampler)
            up = Get2D!(sampler)
            probeSeg = SampleSp(bssrdf, uc, up)
            if isnothing(probeSeg)
                break
            end
            
            # Sample random intersection along BSSRDF probe segment
            seed = MixBits(FloatToBits(Get1D!(sampler)))
            interactionSampler = WeightedReservoirSampler{SubsurfaceInteraction}(seed)
            
            # Intersect BSSRDF sampling ray against the scene geometry
            base = Interaction(probeSeg.p0, ray.time, Medium())
            while true
                r = SpawnRayTo(base, probeSeg.p1)
                if r.d == Vector3f(0, 0, 0)
                    break
                end
                si_probe = Intersect(r, 1.0f0)
                if isnothing(si_probe)
                    break
                end
                base = si_probe.intr
                if si_probe.intr.material == isect.material
                    Add!(interactionSampler, SubsurfaceInteraction(si_probe.intr), 1.0f0)
                end
            end
            
            if !HasSample(interactionSampler)
                break
            end
            
            # Convert probe intersection to BSSRDFSample
            ssi = GetSample(interactionSampler)
            bssrdfSample = ProbeIntersectionToSample(bssrdf, ssi, scratchBuffer)
            if isnothing(bssrdfSample.Sp) || !bssrdfSample.pdf
                break
            end
            
            # Update path state for subsurface scattering
            pdf = SampleProbability(interactionSampler) * bssrdfSample.pdf[1]
            beta *= bssrdfSample.Sp / pdf
            r_u *= bssrdfSample.pdf / bssrdfSample.pdf[1]
            pi = SurfaceInteraction(ssi)
            pi.wo = bssrdfSample.wo
            prevIntrContext = LightSampleContext(pi)
            
            # Possibly regularize subsurface BSDF
            Sw = bssrdfSample.Sw
            anyNonSpecularBounces = true
            if integrator.regularize
                regularizedBSDFs[] += 1
                Regularize!(Sw)
            else
                totalBSDFs[] += 1
            end
            
            # Account for attenuated direct illumination subsurface scattering
            L += SampleLd(pi, Sw, lambda, sampler, beta, r_u)
            
            # Sample ray for indirect subsurface scattering
            u = Get1D!(sampler)
            bs = Sample_f(Sw, pi.wo, u, Get2D!(sampler))
            if isnothing(bs)
                break
            end
            beta *= bs.f * AbsDot(bs.wi, pi.shading.n) / bs.pdf
            r_l = r_u / bs.pdf
            # Don't increment depth this time...
            @assert !isinf(y(beta, lambda))
            specularBounce = IsSpecular(bs)
            ray = RayDifferential(SpawnRay(pi, bs.wi))
        end
        
        # Possibly terminate volumetric path with Russian roulette
        if !beta
            break
        end
        rrBeta = beta * etaScale / Average(r_u)
        uRR = Get1D!(sampler)
        @info "etaScale $etaScale -> rrBeta $rrBeta"
        if MaxComponentValue(rrBeta) < 1 && depth > 1
            q = max(0.0f0, 1.0f0 - MaxComponentValue(rrBeta))
            if uRR < q
                break
            end
            beta /= 1.0f0 - q
        end
    end
    
    return L
end