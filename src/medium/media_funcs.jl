###############
### Generic ###
###############
function get_medium(inter::Interaction, w::Vec3)::Maybe{AbstractMedium}
    @info "\t\t Get Medium: $(w), $(inter.n)"
    return dot(w, inter.n) > 0.0 ? inter.mi.outside : inter.mi.inside
end

function get_medium(inter::Interaction)::Maybe{AbstractMedium}
    @assert inter.mi.inside == inter.mi.outside
    return inter.mi.inside
end

function is_transition_medium(mi::MediumInterface)::Bool
    return mi.inside != mi.outside
end

##################
### Homogenous ###
##################
function tr(m::HomogenousMedium, ray::AbstractRay, sampler::AbstractSampler)::Spectrum
    return exp.(-m.sigma_t * min(ray.tMax * length_pbrt(ray.direction), typemax(Float64)))
end

function sample(m::HomogenousMedium, ray::AbstractRay, sampler::AbstractSampler)::Tuple{Spectrum, Maybe{MediumInteraction}}
    # sample a channel and distance along the ray
    channel = min(Int64(floor(get_1D!(sampler) * nSpectralSamples)), nSpectralSamples - 1)
    dist = -log(1.0 - get_1D!(sampler)) / m.sigma_t[channel + 1]
    t = min(dist * length_pbrt(ray.direction), ray.tMax)
    sampled_medium = t < ray.tMax
    mi = nothing
    if sampled_medium
        mi = MediumInteraction(at(ray, t), ray.t, -ray.direction, m, HenyeyGreenstein(m.g))
    end

    # compute the transmittance and sampling density
    Tr = exp.(-m.sigma_t * min(t, typemax(Float64)) * length_pbrt(ray.direction))

    # return weighting factor for scattering from homogenous medium
    density = sampled_medium ? (m.sigma_t * Tr) : Tr
    pdf_val = 0.0
    for i in 1:nSpectralSamples
        pdf_val += density[i]
    end
    pdf_val *= 1.0 / nSpectralSamples
    return (sampled_medium ? (Tr * m.sigma_s / pdf_val) : (Tr / pdf_val), mi)
end

####################
### Heterogenous ###
####################

function D(gdm::GridDensityMedium, p::Pnt3)::Float64
    sample_bounds = Bounds3(Pnt3(0,0,0), Pnt3(gdm.nx, gdm.ny, gdm.nz))
    if !inside_exclusive(p, sample_bounds)
        return 0.0
    else
        return gdm.density[Int((p.z * gdm.ny + p.y) * gdm.nx + p.x + 1)]
    end
end

function density(gdm::GridDensityMedium, p::Pnt3)::Float64
    psample = Pnt3(p.x * gdm.nx - 0.5, p.y * gdm.ny - 0.5, p.z * gdm.nz - 0.5)
    pfloor = floor.(psample)
    d = psample - pfloor

    d00 = lerp(d.x, D(gdm, pfloor),               D(gdm, pfloor + Pnt3(1,0,0)))
    d10 = lerp(d.x, D(gdm, pfloor + Pnt3(0,1,0)), D(gdm, pfloor + Pnt3(1,1,0)))
    d01 = lerp(d.x, D(gdm, pfloor + Pnt3(0,0,1)), D(gdm, pfloor + Pnt3(1,0,1)))
    d11 = lerp(d.x, D(gdm, pfloor + Pnt3(0,1,1)), D(gdm, pfloor + Pnt3(1,1,1)))
    d0  = lerp(d.y, d00, d10)
    d1  = lerp(d.y, d01, d11)
    return lerp(d.z, d0, d1)
end

function sample(gdm::GridDensityMedium, ray_world::AbstractRay, sampler::AbstractSampler)::Tuple{Spectrum, Maybe{MediumInteraction}}
    @info "Medium Sample Time:\n\tRay Entering: $(ray_world)\n"
    @info "wtf is this transform: $(gdm.world_to_medium)"
    ray = gdm.world_to_medium(Ray(ray_world.origin, normalize(ray_world.direction), 0.0, ray_world.tMax * length_pbrt(ray_world.direction)))
    @info "\tRay Transformed: $(ray)\n" 

    # JOHN HACK
    mi = nothing

    # compute the [t_min, t_max] interval of ray's overlap with the medium bounds
    b = Bounds3(Pnt3(0,0,0), Pnt3(1,1,1))
    check, tmin, tmax = intersect_p(b, ray)
    if !check
        return spectrum_from_float(1.0), mi
    end

    @info "we are within bounds"

    t = tmin
    while true
        t -= log(1 - get_1D!(sampler)) * gdm.inv_max_density / gdm.sigma_t
        # @info "medium sample: $(t)"
        if t >= tmax
            break
        end
        density_value = density(gdm, at(ray, t))
        # @info "Density at $(at(ray, t)) is $(density_value)"
        if density_value * gdm.inv_max_density > get_1D!(sampler)
            # populate mi with medium interaction information and return
            mi = MediumInteraction(at(ray_world, t), ray_world.t, -ray_world.direction, gdm, HenyeyGreenstein(gdm.g))
            @info "Exiting with $(gdm.sigma_s / gdm.sigma_t)"
            return gdm.sigma_s / gdm.sigma_t, mi
        end
    end
    @info "Exiting with 1.0"
    return spectrum_from_float(1.0), mi
end

function tr(gdm::GridDensityMedium, ray_world::AbstractRay, sampler::AbstractSampler)::Spectrum
    @info "Medium Tr Time:\n\tRay Entering: $(ray_world)\n"
    ray = gdm.world_to_medium(Ray(ray_world.origin, normalize(ray_world.direction), 0.0, ray_world.tMax * length_pbrt(ray_world.direction)))
    @info "\tRay Transformed: $(ray)\n"    

    # Compute $[\tmin, \tmax]$ interval of _ray_'s overlap with medium bounds
    b = Bounds3(Pnt3(0,0,0), Pnt3(1,1,1))
    check, tmin, tmax = intersect_p(b, ray)
    if !check
        return spectrum_from_float(1.0)
    end

    # Perform ratio tracking to estimate transmittance value

    Tr = 1.0
    t = tmin
    while true
        t -= log(1-get_1D!(sampler)) * gdm.inv_max_density / gdm.sigma_t
        if t >= tmax
            break
        end
        density_val = density(gdm, at(ray, t))
        @info "\tRay Density at $(at(ray, t)) is $(density_val)"
        Tr *= 1.0 - max(0.0, density_val * gdm.inv_max_density)
        rr_threshold = 0.1
        if Tr < rr_threshold
            q = max(.05, 1.0 - Tr)
            if get_1D!(sampler) < q
                @info "Exiting with 0.0"
                return spectrum_from_float(0.0)
            end
            Tr /= (1.0 - q)
        end
    end
    @info "Exiting with $(spectrum_from_float(Tr))"
    return spectrum_from_float(Tr)
end


###############
### NanoVDB ###
###############

function sample(nvm::NanoVDBMedium, ray_world::AbstractRay, sampler::AbstractSampler)::Tuple{Spectrum, Maybe{MediumInteraction}}
    @info "Medium Sample Time:\n\tRay Entering: $(ray_world)\n"
    ray = nvm.medium_to_unit(
        Ray(
            ray_world.origin, 
            normalize(ray_world.direction), 
            0.0, ray_world.tMax * length_pbrt(ray_world.direction)
        )
    )
    @info "\tRay Transformed: $(ray)\n" 
    @info "\tInv Max Density: $(nvm.inv_max_density) :: $(nvm.sigma_s) :: $(nvm.sigma_t)"

    # JOHN HACK
    mi = nothing

    # compute the [t_min, t_max] interval of ray's overlap with the medium bounds
    check, tmin, tmax = intersect_p(Bounds3(Pnt3(0,0,0), Pnt3(1,1,1)), ray)
    if !check
        return spectrum_from_float(1.0), mi
    end
    @info "we are within bounds. tmin $(tmin), tmax $(tmax)"

    # john hack - getting this ray into world space
    ray = Inv(nvm.medium_to_unit)(ray)
    @info "\tRay NanoVDB Space: $(ray)\n" 

    # print("BEGINNING MEDIA SAMPLING\n")
    flag, new_t = NanoVDB.sample_NanoVDBWrapper(
        nvm.density_float_grid,
        tmin, tmax, 
        nvm.inv_max_density, nvm.sigma_t, 
        ray.origin.x, ray.origin.y, ray.origin.z, 
        ray.direction.x, ray.direction.y, ray.direction.z
    )
    # print("ENDING MEDIA SAMPLING\n")
    if Bool(flag)
        @info "Exiting with 1.0\n"
        return spectrum_from_float(1.0), mi
    else
        mi = MediumInteraction(at(ray_world, new_t), ray_world.t, -ray_world.direction, nvm, HenyeyGreenstein(nvm.g))
        @info "Exiting with $(nvm.sigma_s / nvm.sigma_t)\n"
        return nvm.sigma_s / nvm.sigma_t, mi
    end
end

function tr(nvm::NanoVDBMedium, ray_world::AbstractRay, sampler::AbstractSampler)::Spectrum
    @info "Medium Tr Time:\n\tRay Entering: $(ray_world)\n"
    ray = nvm.medium_to_unit(
        Ray(
            ray_world.origin, 
            normalize(ray_world.direction), 
            0.0, ray_world.tMax * length_pbrt(ray_world.direction)
        )
    )
    @info "\tRay Transformed: $(ray)\n"    

    # Compute $[\tmin, \tmax]$ interval of _ray_'s overlap with medium bounds
    b = Bounds3(Pnt3(0,0,0), Pnt3(1,1,1))
    check, tmin, tmax = intersect_p(b, ray)
    if !check
        return spectrum_from_float(1.0)
    end

    @info "we are within bounds - $(tmin), $(tmax)\n"

    ray = Inv(nvm.medium_to_unit)(ray)

    # print("BEGINNING MEDIA TRANSMITTANCE\n")    
    Tr = NanoVDB.transmittance_NanoVDBWrapper(
        nvm.density_float_grid,
        tmin, tmax, 
        nvm.inv_max_density, nvm.sigma_t, 
        ray.origin.x, ray.origin.y, ray.origin.z, 
        ray.direction.x, ray.direction.y, ray.direction.z
    )
    # print("ENDING MEDIA TRANSMITTANCE\n")
    return spectrum_from_float(Tr)
end


# function D(nvm::NanoVDBMedium, p::Pnt3)::Float64
#     return NanoVDB.get_value_pls(nvm.accessor, NanoVDB.Coord(Int64(p.x), Int64(p.y), Int64(p.z)))
# end

# function density(nvm::NanoVDBMedium, p::Pnt3)::Float64
#     psample = Pnt3(p.x - 0.5, p.y - 0.5, p.z - 0.5)
#     pfloor = floor.(psample)
#     d = psample - pfloor

#     d00 = lerp(d.x, D(nvm, pfloor),               D(nvm, pfloor + Pnt3(1,0,0)))
#     d10 = lerp(d.x, D(nvm, pfloor + Pnt3(0,1,0)), D(nvm, pfloor + Pnt3(1,1,0)))
#     d01 = lerp(d.x, D(nvm, pfloor + Pnt3(0,0,1)), D(nvm, pfloor + Pnt3(1,0,1)))
#     d11 = lerp(d.x, D(nvm, pfloor + Pnt3(0,1,1)), D(nvm, pfloor + Pnt3(1,1,1)))
#     d0  = lerp(d.y, d00, d10)
#     d1  = lerp(d.y, d01, d11)
#     return lerp(d.z, d0, d1)
# end