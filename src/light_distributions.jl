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
    voxels::Dict{Tuple{Int64, Int64, Int64}, Distribution1D}
    n_voxels::Pnt3

    function SpatialLightDistribution(
        scene::Scene,
        max_voxels::Int64
    )
        diag = RayTracing.diagonal(wbounds)
        bmax = maximum(diag)
        n_voxels = max.(1, Int.(round.(diag / bmax * max_voxels)))

        # if we were fancy, like the book we'd stop our constructor here and build the spatial dist as we render. 
        # But we're not.
        # so we build the whole thing meow (and not parallelized)
        # TODO 
        return new()
    end
end


##### The constructor
function LightDistribution(
    name::String, 
    scene::Scene, 
    N_voxels::Int64=4^3
)::AbstractLightDistribution
    if (name == "uniform") || (name == "power") || (length(scene.lights) == 1)
        return StaticLightDistribution(name, scene)

    elseif name == "spatial"
        return SpatialLightDistribution(scene, N_voxels)

    else
        @assert false, "please pick one of uniform, power, spatial, or centroid_distance"
    end
end

### Light distributions are created via lookup
# trivial for static, less trivial for voxel & distant

function lookup(ld::StaticLightDistribution, p::Pnt3)::Distribution1D
    return ld.distr
end