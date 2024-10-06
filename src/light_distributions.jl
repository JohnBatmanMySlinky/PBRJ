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
    voxels::Dict{Tuple{Int64, Int64, Int64}, Distribution1D}
    pMin::Pnt3
    voxel_size::Int64

    function VoxelLightDistribution(name::String, scene::Scene, N_voxels::Int64, n_shadow_rays::Int64)
        sampler = IndependentSampler()
        wbounds = RayTracing.world_bounds(scene.b)
        voxel_size = calc_voxel_size(wbounds, N_voxels)
        X, Y, Z = Int64.(floor.((wbounds.pMax - wbounds.pMin)/voxel_size) .+1)
        voxel_dist = create_voxels_distribution(scene, sampler, X, Y, Z, n_shadow_rays)

        return new(
            voxel_dist, wbounds.pMin, voxel_size
        )
    end
end

function calc_voxel_size(wbounds, N_voxels, max_recursion=100)
    size = floor((prod(wbounds.pMax - wbounds.pMin) / N_voxels)^(1/3))
    N = prod(floor.((wbounds.pMax - wbounds.pMin)/size) .+1)
    depth = 1
    while (N > N_voxels) & (depth <= max_recursion)
        depth += 1
        N = prod(floor.((wbounds.pMax - wbounds.pMin)/(size+depth)) .+1)
    end
    @assert prod(floor.((wbounds.pMax - wbounds.pMin)/(size+depth-1)) .+ 1) >= N_voxels
    return size + depth - 1
end

function sample_point_on_light(
    light::RayTracing.Light, 
    voxel_isect::RayTracing.Interaction, 
    u::RayTracing.Pnt2, 
    scene::RayTracing.BVHAccel
)::RayTracing.Maybe{RayTracing.Pnt3}
    if light.flags == RayTracing.LightArea
        p, n, light_pdf = RayTracing.sample(light.shape, u)
        vis = RayTracing.VisibilityTester(voxel_isect, RayTracing.Interaction(p, 0.0, n))
        check = RayTracing.unoccluded(vis, scene)
        L = check * light.Lemit / RayTracing.distance(vis.p0.p, vis.p1.p)
    elseif light.flags == RayTracing.LightInfinite 
        uv, map_pdf = RayTracing.sample_continuous(light.distribution, uvu)
        theta = uv.y * pi
        phi = uv.x * 2 * pi
        cos_theta = RayTracing.cos(theta)
        sin_theta = RayTracing.sin(theta)
        sin_phi = RayTracing.sin(phi)
        cos_phi = RayTracing.cos(phi)
        wi = il.light_to_world(RayTracing.Vec3(sin_theta * cos_phi, sin_theta * sin_phi, cos_theta))
        vis = RayTracing.VisibilityTester(
            interaction,
            RayTracing.Interaction(
                voxel_isect.p + wi .* 2 * light.world_radius, 
                voxel_isect.t, 
                RayTracing.Nml3(0, 0, 0), 
                RayTracing.Vec3(0, 0, 0),
                RayTracing.MediumInterface(light.medium)
            )
        )
        check = RayTracing.unoccluded(vis, scene)
        radiance = RayTracing.lookup(il.Lmap, uv)
        radiance = RayTracing.spectrum_from_RGB(radiance.a, radiance.b, radiance.c, Illuminant)
        L = vis * radiance / RayTracing.distance(vis.p0.p, vis.p1.p)
    else
        @assert false, "No VoxelLightDistribution for LightDeltaDirection or LightDeltaPosition yet"
    end

    return L
end

function create_voxels_distribution(
    scene::RayTracing.Scene,
    sampler::RayTracing.AbstractSampler,
    voxel_x_dim::Int64,
    voxel_y_dim::Int64,
    voxel_z_dim::Int64,
    n_shadow_rays::Int64
)::Dict{Tuple{Int64, Int64, Int64}, RayTracing.Distribution1D}
    voxels = Dict{Tuple{Int64, Int64, Int64}, RayTracing.Distribution1D}()
    for x in 1:voxel_x_dim
        for y in 1:voxel_y_dim
            for z in 1:voxel_z_dim
                light_samples = zeros(Float64, length(scene.lights))

                # TODO: how to cull voxels functionally outside of the scene
                lcorner = RayTracing.Pnt3(x-1, y-1, z-1) .* size
                center = lcorner .+ size/2
                # TODO: account for mediums
                voxel_isect = RayTracing.Interaction()
                voxel_isect.p = center

                for idx in eachindex(scene.lights)
                    LL = RayTracing.spectrum_from_float(0.0)
                    for n in n_shadow_rays
                        u = RayTracing.get_2D!(sampler)
                        LL += sample_point_on_light(scene.lights[idx], voxel_isect, u, scene.b)
                    end
                    light_samples[idx] = RayTracing.y_spectrum(LL) / n_shadow_rays
                end
                voxels[(x,y,z)] = RayTracing.Distribution1D(light_samples)
            end
        end
    end
    return voxels
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
function LightDistribution(
    name::String, scene::Scene, 
    weight_for_infinites::Float64=0.10, 
    N_voxels::Int64=4^3,
    n_shadow_rays::int64=3
)::AbstractLightDistribution
    if (name == "uniform") || (name == "power")
        return StaticLightDistribution(name, scene)

    elseif name == "spatial"
        @assert false, "spatial light distribution isn't implemented yet"
        return VoxelLightDistribution(name, scene, N_voxels, n_shadow_rays)

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

function lookup(vld::VoxelLightDistribution, p::Pnt3)::Distribution1D
    distance_from_pmin = Int64.(floor.((p - vld.pMin)/vld.voxel_size) .+ 1)
    return vld.voxels[(distance_from_pmin.x, distance_from_pmin.y, distance_from_pmin.z)]
end

function lookup(ld::DistanceLightDistribution, p::Pnt3)::Distribution1D
    distances = Vector{Float64}(undef, length(ld.points))

    # first pass fill with distances
    for (i,(inf_check, point)) in enumerate(zip(ld.infinite_idx, ld.points))
        if inf_check
            distances[i] = 0.0
        else
            distances[i] = 1/distance(p, point)^2
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