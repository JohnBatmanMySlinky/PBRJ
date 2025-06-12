struct VolPathIntegrator <: AbstractIntegrator
    camera::C where C <: Camera
    sampler::S where S <: AbstractSampler
    max_depth::Int64
    regularize::Bool
end


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
        
        check, t, si = intersect!(scene.b, ray)
        
        if !(ray.medium isa Nothing)
            # Sample the participating medium
            scattered = false
            terminated = false
            tMax = (si isa Nothing) ? typemax(Float64) : si.tHit
                       
            T_maj = SampleT_maj(ray, tMax, Get1D!(sampler), sampler) do p, mp, sigma_maj, T_maj
                # Handle medium scattering event for ray
                if !beta
                    terminated = true
                    return false
                end
                
                # Add emission from medium scattering event
                if depth < integrator.max_depth && !(mp.Le isa Nothing)
                    # Compute β' at new path vertex
                    pdf_val = sigma_maj[0 + 1] * T_maj[0 + 1]
                    betap = beta * T_maj / pdf_val
                    
                    # Compute rescaled path probability for absorption at path vertex
                    r_e = r_u * sigma_maj * T_maj / pdf_val
                    
                    # Update L for medium emission
                    if r_e
                        L += betap * mp.sigma_a * mp.Le / y_spectrum(r_e)
                    end
                end
                
                # Compute medium event probabilities for interaction
                pAbsorb = mp.sigma_a[0 + 1] / sigma_maj[0 + 1]
                pScatter = mp.sigma_s[0 + 1] / sigma_maj[0 + 1]
                pNull = max(0.0, 1.0 - pAbsorb - pScatter)
                
                @assert 1.0 - pAbsorb - pScatter >= -1e-6
                
                # Sample medium scattering event type and update path
                um = Get1D!(sampler)
                mode = sample_discrete(Distribution1D([pAbsorb, pScatter, pNull]), um)
                
                if mode == 1
                    # Handle absorption along ray path
                    terminated = true
                    return false
                    
                elseif mode == 2
                    # Handle scattering along ray path
                    # Stop path sampling if maximum depth has been reached
                    depth += 1
                    if depth >= integrator.max_depth
                        terminated = true
                        return false
                    end
                    
                    # Update beta and r_u for real-scattering event
                    pdf_val = T_maj[0 + 1] * mp.sigma_s[0 + 1]
                    beta *= T_maj * mp.sigma_s / pdf_val
                    r_u *= T_maj * mp.sigma_s / pdf_val
                    
                    if beta && r_u
                        # Sample direct lighting at volume-scattering event
                        intr = MediumInteraction(p, -ray.d, ray.time, ray.medium, mp.phase)
                        L += sample_ld(intr, nothing, sampler, beta, r_u)
                        
                        # Sample new direction at real-scattering event
                        u = Get2D!(sampler)
                        ps = sample_p(intr.phase, -ray.d, u)
                        
                        if (ps isa Nothing) || ps.pdf_val == 0.0
                            terminated = true
                        else
                            # Update ray path state for indirect volume scattering
                            beta *= ps.p / ps.pdf_val
                            r_l = r_u / ps.pdf_val
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
                    sigma_n = clamp.(sigma_maj - mp.sigma_a - mp.sigma_s, 0.0, 1.0)
                    pdf_val = T_maj[0 + 1] * sigma_n[0 + 1]
                    beta *= T_maj * sigma_n / pdf_val
                    if pdf_val == 0.0
                        beta = spectrum_from_float(0.0)
                    end
                    r_u *= T_maj * sigma_n / pdf_val
                    r_l *= T_maj * sigma_maj / pdf_val
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
            
            beta *= T_maj / T_maj[0 + 1]
            r_u *= T_maj / T_maj[0 + 1]
            r_l *= T_maj / T_maj[0 + 1]
        end
        
        # Handle surviving unscattered rays
        # Add emitted light at volume path vertex or from the environment
        if (si isa Nothing)
            # Accumulate contributions from infinite light sources
            for light in integrator.infiniteLights
                Le = le(light, ray)
                if Le
                    if depth == 0 || specularBounce
                        L += beta * Le / y_spectrum(r_u)
                    else
                        # Add infinite light contribution using both pdf_vals with MIS
                        p_l = pmf(integrator.lightSampler, prevIntrContext, light) *
                              pdf_val_Li(light, prevIntrContext, ray.d, true)
                        r_l *= p_l
                        L += beta * Le / y_spectrum(r_u + r_l)
                    end
                end
            end
            break
        end
        
        isect = si.intr
        Le = le(isect, -ray.d)
        if Le
            # Add contribution of emission from intersected surface
            if depth == 0 || specularBounce
                L += beta * Le / y_spectrum(r_u)
            else
                # Add surface light contribution using both pdf_vals with MIS
                areaLight = Light(isect.areaLight)
                p_l = pmf(integrator.lightSampler, prevIntrContext, areaLight) *
                      pdf_val_Li(areaLight, prevIntrContext, ray.d, true)
                r_l *= p_l
                L += beta * Le / y_spectrum(r_u + r_l)
            end
        end
        
        # Get BSDF and skip over medium boundaries
        bsdf = GetBSDF(isect, ray, integrator.camera, scratchBuffer, sampler)
        if (bsdf isa Nothing)
            SkipIntersection(isect, ray, si.tHit)
            continue
        end
        
        # Initialize visibleSurf at first intersection
        # if depth == 0.0 && !(visibleSurf isa Nothing)
        #     # Estimate BSDF's albedo
        #     # Define sample arrays ucRho and uRho for reflectance estimate
        #     nRhoSamples = 16
        #     ucRho = Float32[0.75741637, 0.37870818, 0.7083487, 0.18935409, 0.9149363, 0.35417435,
        #                    0.5990858, 0.09467703, 0.8578725, 0.45746812, 0.686759, 0.17708716,
        #                    0.9674518, 0.2995429, 0.5083201, 0.047338516]
        #     uRho = [Point2f(0.855985, 0.570367), Point2f(0.381823, 0.851844),
        #             Point2f(0.285328, 0.764262), Point2f(0.733380, 0.114073),
        #             Point2f(0.542663, 0.344465), Point2f(0.127274, 0.414848),
        #             Point2f(0.964700, 0.947162), Point2f(0.594089, 0.643463),
        #             Point2f(0.095109, 0.170369), Point2f(0.825444, 0.263359),
        #             Point2f(0.429467, 0.454469), Point2f(0.244460, 0.816459),
        #             Point2f(0.756135, 0.731258), Point2f(0.516165, 0.152852),
        #             Point2f(0.180888, 0.214174), Point2f(0.898579, 0.503897)]
            
        #     albedo = rho(bsdf, isect.wo, ucRho, uRho)
        #     visibleSurf[] = VisibleSurface(isect, albedo)
        # end
        
        # # Terminate path if maximum depth reached
        # depth += 1
        # if depth >= integrator.maxDepth
        #     return L
        # end
        
        # Possibly regularize the BSDF
        if integrator.regularize && anyNonSpecularBounces
            Regularize!(bsdf)
        end
        
        # Sample illumination from lights to find attenuated path contribution
        if IsNonSpecular(Flags(bsdf))
            L += SampleLd(isect, bsdf, sampler, beta, r_u)
            @assert !isinf(y(L))
        end
        
        prevIntrContext = LightSampleContext(isect)
        
        # Sample BSDF to get new volumetric path direction
        wo = isect.wo
        u = Get1D!(sampler)
        bs = sample_f(bsdf, wo, u, Get2D!(sampler))
        if (bs isa Nothing)
            break
        end
        
        # Update beta and rescaled path probabilities for BSDF scattering
        beta *= bs.f * abs(dot(bs.wi, isect.shading.n)) / bs.pdf_val
        if bs.pdf_valIsProportional
            r_l = r_u / pdf(bsdf, wo, bs.wi)
        else
            r_l = r_u / bs.pdf_val
        end
        
        @info "Sampled BSDF, f = $(bs.f), pdf_val = $(bs.pdf_val) -> beta = $beta"
        @assert !isinf(y(beta))
        
        # Update volumetric integrator path state after surface scattering
        specularBounce = IsSpecular(bs)
        anyNonSpecularBounces |= !IsSpecular(bs)
        if IsTransmission(bs)
            etaScale *= bs.eta^2
        end
        ray = SpawnRay(isect, ray, bsdf, bs.wi, bs.flags, bs.eta)
        
        # Account for attenuated subsurface scattering, if applicable
        # bssrdf = GetBSSRDF(isect, ray, integrator.camera, scratchBuffer)
        # if !(bssrdf isa Nothing) && IsTransmission(bs)
        #     # Sample BSSRDF probe segment to find exit point
        #     uc = Get1D!(sampler)
        #     up = Get2D!(sampler)
        #     probeSeg = SampleSp(bssrdf, uc, up)
        #     if (probeSeg isa Nothing)
        #         break
        #     end
            
        #     # Sample random intersection along BSSRDF probe segment
        #     seed = MixBits(FloatToBits(Get1D!(sampler)))
        #     interactionSampler = WeightedReservoirSampler{SubsurfaceInteraction}(seed)
            
        #     # Intersect BSSRDF sampling ray against the scene geometry
        #     base = Interaction(probeSeg.p0, ray.time, Medium())
        #     while true
        #         r = SpawnRayTo(base, probeSeg.p1)
        #         if r.d == Vector3f(0, 0, 0)
        #             break
        #         end
        #         si_probe = Intersect(r, 1.0)
        #         if (si_probe isa Nothing)
        #             break
        #         end
        #         base = si_probe.intr
        #         if si_probe.intr.material == isect.material
        #             Add!(interactionSampler, SubsurfaceInteraction(si_probe.intr), 1.0)
        #         end
        #     end
            
        #     if !HasSample(interactionSampler)
        #         break
        #     end
            
        #     # Convert probe intersection to BSSRDFSample
        #     ssi = GetSample(interactionSampler)
        #     bssrdfSample = ProbeIntersectionToSample(bssrdf, ssi, scratchBuffer)
        #     if (bssrdfSample.Sp isa Nothing) || !bssrdfSample.pdf_val
        #         break
        #     end
            
        #     # Update path state for subsurface scattering
        #     pdf_val = SampleProbability(interactionSampler) * bssrdfSample.pdf_val[0 + 1]
        #     beta *= bssrdfSample.Sp / pdf_val
        #     r_u *= bssrdfSample.pdf_val / bssrdfSample.pdf_val[0 + 1]
        #     pi = SurfaceInteraction(ssi)
        #     pi.wo = bssrdfSample.wo
        #     prevIntrContext = LightSampleContext(pi)
            
        #     # Possibly regularize subsurface BSDF
        #     Sw = bssrdfSample.Sw
        #     anyNonSpecularBounces = true
        #     if integrator.regularize
        #         regularizedBSDFs[] += 1
        #         Regularize!(Sw)
        #     else
        #         totalBSDFs[] += 1
        #     end
            
        #     # Account for attenuated direct illumination subsurface scattering
        #     L += SampleLd(pi, Sw, sampler, beta, r_u)
            
        #     # Sample ray for indirect subsurface scattering
        #     u = Get1D!(sampler)
        #     bs = Sample_f(Sw, pi.wo, u, Get2D!(sampler))
        #     if (bs isa Nothing)
        #         break
        #     end
        #     beta *= bs.f * AbsDot(bs.wi, pi.shading.n) / bs.pdf_val
        #     r_l = r_u / bs.pdf_val
        #     # Don't increment depth this time...
        #     @assert !isinf(y(beta))
        #     specularBounce = IsSpecular(bs)
        #     ray = RayDifferential(SpawnRay(pi, bs.wi))
        # end
        
        # Possibly terminate volumetric path with Russian roulette
        if !beta
            break
        end
        rrBeta = beta * etaScale / y_spectrum(r_u)
        uRR = Get1D!(sampler)
        @info "etaScale $etaScale -> rrBeta $rrBeta"
        if MaxComponentValue(rrBeta) < 1 && depth > 1
            q = max(0.0, 1.0 - MaxComponentValue(rrBeta))
            if uRR < q
                break
            end
            beta /= 1.0 - q
        end
    end
    
    return L
end