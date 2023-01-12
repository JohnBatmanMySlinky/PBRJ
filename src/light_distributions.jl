# PBRT GITHUB
# /src/core/lightdistrib.{h, cpp}
# LightDistribution defines a general interface for classes that provide
# probability distributions for sampling light sources at a given point in
# space.

# JOHN 
"""
1) Uniform(scene::Scene) --> Distribution1D
2) Power(scene::Scene) --> Distribution1D
3) Spatial(scene::Scene) --> looks up Distribution1D w/ p
4) Distance(scene::Scene) --> calculates Distribution1D @ p
"""

#######################################################
### The different flavors of light distributions
### All acros created via constructor `LightDistribution`
### all are queried via a specialized `lookup` fn
#######################################################

# this covers Uniform and Power
struct StaticLightDistribution <: AbstractLightDistribution
    distr::Distribution1D

    function StaticLightDistribution(name::String, scene::Scene)
        if name == "uniform"
            return new(
                Distribution1D(ones(length(scene.lights)))
            )
        elseif name == "power"
            return new(
                Distribution1D([mean(power(l) for l in scene.lights)])
            )
        else
            @assert false
        end
    end
end

# this covers Spatial
struct VoxelLightDistribution <: AbstractLightDistribution
    hash::Dict{Tuple{Int64, Int64, Int64}, Distribution1D}

    function VoxelLightDistribution(name::String, scene::Scene)
        return new(
            Dict(Pnt3(0) => Distribution1D(ones(length(scene.lights)))) # DUMMY CODE
        )
    end
end

# this covers Distance
struct DistanceLightDistribution <: AbstractLightDistribution
    points::Vector{Pnt3}
    aabb::Vector{Bounds3}
    points_idx::Vector{UInt8} # 1 means points 0 means aabb

    function DistanceLightDistribution(name::String, scene::Scene)
        points = Vector{Pnt3}(undef, len(scene.lights))
        aabb = Vector{Bounds3}(undef, len(scene.lights))
        points_idx = Vector{UInt8}(undef, len(scene.lights))

        for (i, l) in enumerate(scene.lights)
            if is_area_light(l)
                points[i] = Pnt3(0)
                aabb[i] = bounding_box(l.shape)
                points_idx[i] = UInt8(0)

            elseif is_delta_light(l)
                points[i] = l.light_position # TODO make point and spot consistent
                aabb[i] = scene.bounds
                points_idx[i] = UInt8(1)

            elseif is_infinite_light(l)
                points[i] = Pnt3(0)
                aabb[i] = scene.bounds # TODO make distant light sampling smarter
                points_idx[i] = UInt8(0)

            else
                @assert false, "your light flags suck"
            end
        end

        return new(
            points,
            aabb,
            points_idx
        )
    end
end

##### The constructor
function LightDistribution(name::String, scene::Scene)::AbstractLightDistribution
    if (name == "uniform") || (name == "power")
        return StaticLightDistribution(name, scene)

    elseif name == "spatial"
        @assert false, "spatial light distribution isn't implemented yet"
        return VoxelLightDistribution(name, scene)

    elseif name == "centriod_distance"
        return DistanceLightDistribution(name, scene)

    else
        @assert false, "please pick one of uniform, power, spatial, or centriod_distance"
    end
end

### Light distributions are created via lookup
# trivial for static, less trivial for voxel & distant