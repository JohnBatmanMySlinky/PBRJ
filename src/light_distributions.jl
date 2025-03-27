# PBRT GITHUB
# /src/core/lightdistrib.{h, cpp}
# LightDistribution defines a general interface for classes that provide
# probability distributions for sampling light sources at a given point in
# space.


#######################################################
### The different flavors of light distributions
### All acros created via constructor `LightDistribution`
### all are queried via a specialized `lookup` fn
#######################################################

# this covers Uniform and Power
struct StaticLightDistribution <: AbstractLightDistribution
    distr::Distribution1D

    function StaticLightDistribution(name::String, scene::Scene)
        if (name == "uniform") || (length(scene.lights) == 1)
            return new(
                Distribution1D(ones(length(scene.lights)))
            )
        elseif name == "power"
            return new(
                Distribution1D([y_spectrum(power(l)) for l in scene.lights])
            )
        else
            @assert false
        end
    end
end

# this covers Spatial
struct SpatialLightDistribution <: AbstractLightDistribution
    voxel_dists::Dict{Tuple{Int64, Int64, Int64}, Distribution1D}
    voxel_size::Pnt3
    n_voxels::Pnt3
    wbounds::Bounds3

    function SpatialLightDistribution(
        scene::Scene,
        max_voxels::Int64,
    )
        wbounds = scene.bounds
        diag = diagonal(wbounds)
        bmax = maximum(diag)
        n_voxels = max.(1, Int.(round.(diag / bmax * max_voxels)))
        voxel_size = (wbounds.pMax .- wbounds.pMin) ./ n_voxels
        n_samples = UInt64(128)
        
        # Create a shared dictionary with locks to avoid race conditions
        voxel_dists = Dict{Tuple{Int64, Int64, Int64}, Distribution1D}()
        dict_lock = ReentrantLock()
        
        # Create a flat array of voxel coordinates for parallelization
        voxel_coords = [(x, y, z) for x in 0:(n_voxels.x - 1), 
                                  y in 0:(n_voxels.y - 1), 
                                  z in 0:(n_voxels.z - 1)]
        
        # Parallelize over the flattened array
        Threads.@threads for coord in vec(voxel_coords)
            x, y, z = coord
            
            voxel_bounds = Bounds3(
                wbounds.pMin + voxel_size .* Pnt3(x, y, z),
                wbounds.pMin + voxel_size .* Pnt3(x+1, y+1, z+1),
            )
            
            light_contribution = zeros(Float64, length(scene.lights))
            
            for i in UInt64(1):n_samples
                po = lerp(
                    Pnt3(
                        radical_inverse(0, i),
                        radical_inverse(1, i),
                        radical_inverse(2, i)
                    ),
                    voxel_bounds
                )
                @assert inside(po, voxel_bounds)
                
                intr = Interaction()
                intr.p = po
                u = Pnt2(
                    radical_inverse(3, i),
                    radical_inverse(4, i)
                )
                
                for j in 1:length(scene.lights)
                    radiance, _, pdf_val, _, _, _ = sample_li(scene.lights[j], intr, u)
                    if pdf_val > 0.0
                        light_contribution[j] += y_spectrum(radiance) / pdf_val
                    end
                end
            end
            
            # Compute contribution statistics once for each voxel
            avg_contrib = mean(light_contribution)
            min_contrib = avg_contrib > 0 ? avg_contrib * .001 : 1.0
            light_contribution = max.(light_contribution, min_contrib)
            
            # Add to shared dictionary with lock protection
            lock(dict_lock) do
                voxel_dists[(Int64(x), Int64(y), Int64(z))] = Distribution1D(light_contribution)
            end
        end
        
        return new(voxel_dists, voxel_size, n_voxels, wbounds)
    end
end


##### The constructor
function LightDistribution(
    name::String, 
    scene::Scene, 
    max_voxels::Int64=4^3
)::AbstractLightDistribution
    if (name == "uniform") || (name == "power") || (length(scene.lights) == 1)
        return StaticLightDistribution(name, scene)

    elseif name == "spatial"
        return SpatialLightDistribution(scene, max_voxels)

    else
        @assert false, "please pick one of uniform, power, spatial, or centroid_distance"
    end
end

### Light distributions are created via lookup
# trivial for static, less trivial for voxel & distant

function lookup(ld::StaticLightDistribution, p::Pnt3)::Distribution1D
    return ld.distr
end

function lookup(ld::SpatialLightDistribution, p::Pnt3)::Distribution1D
    # JOHN HACK
    # apparently this is more necessary than I was expecting?
    pp = Int64.(clamp.(trunc.((p - ld.wbounds.pMin) ./ ld.voxel_size), 0, ld.n_voxels .- 1))
    return ld.voxel_dists[(pp.x, pp.y, pp.z)]
end