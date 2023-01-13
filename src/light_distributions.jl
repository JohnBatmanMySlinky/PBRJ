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
    infinite_idx::Vector{Bool}
    weight_for_infinites::Float64
    weight_for_each_infinite::Float64


    # JOHGN HACK
    # GIVE INFINITES x% split evenly????

    function DistanceLightDistribution(name::String, scene::Scene, weight_for_infinites::Float64)
        points = Vector{Pnt3}(undef, length(scene.lights))
        infinite_idx = Vector{UInt8}(undef, length(scene.lights)) # 1 means inf 0 means not inf

        weight_for_each_infinite = weight_for_infinites / sum([1 for l in scene.lights if is_infinite_light(l)])

        for (i, l) in enumerate(scene.lights)
            # area lights
            if is_area_light(l)
                points[i] = centroid(world_bounds(l.shape))
                infinite_idx[i] = false
                
            # spot & point lights
            elseif is_delta_pos_light(l)
                points[i] = l.light_position
                infinite_idx[i] = false

            # infinite and distant
            elseif is_infinite_light(l) || is_delta_dir_light(l)
                points[i] = Pnt3(0)
                infinite_idx[i] = true
                
            else
                @assert false, "your light flags suck"
            end
        end

        return new(
            points,
            infinite_idx,
            weight_for_infinites,
            weight_for_each_infinite
        )
    end
end

##### The constructor
function LightDistribution(name::String, scene::Scene, weight_for_infinites::Float64=0.10)::AbstractLightDistribution
    if (name == "uniform") || (name == "power")
        return StaticLightDistribution(name, scene)

    elseif name == "spatial"
        @assert false, "spatial light distribution isn't implemented yet"
        return VoxelLightDistribution(name, scene)

    elseif name == "centroid_distance"
        return DistanceLightDistribution(name, scene, weight_for_infinites)

    else
        @assert false, "please pick one of uniform, power, spatial, or centroid_distance"
    end
end

### Light distributions are created via lookup
# trivial for static, less trivial for voxel & distant

function lookup(ld::StaticLightDistribution, p::Pnt3)::Distribution1D
    return ld.distr
end

function lookup(ld::VoxelLightDistribution, p::Pnt3)::Distribution1D
    @assert false, "NOT IMPLEMENTED"
    return Distribution1D(ones(5))
end

function lookup(ld::DistanceLightDistribution, p::Pnt3)::Distribution1D
    distances = Vector{Float64}(undef, length(ld.points))

    # first pass fill with distances
    for (i,(inf_check, point)) in enumerate(zip(ld.infinite_idx, ld.points))
        if inf_check
            distances[i] = 0.0
        else
            distances[i] = 1/distance(p, point)
        end
    end

    # if no infinites, no need to account for them
    if sum(ld.infinite_idx) == 0
        return Distribution1D(distances)
    else
        # normalize distances to 1-weight_for_infinites
        norm_factor = sum(distances)/(1-ld.weight_for_infinites)
        distances ./= norm_factor

        # plop in weight_for_each_infinites
        for (i, inf_check) in enumerate(ld.infinite_idx)
            if inf_check
                distances[i] = ld.weight_for_each_infinite
            end
        end

        return Distribution1D(distances)
    end
end