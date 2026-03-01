using Dates
using StaticArrays
using LinearAlgebra


const NUM_RAYS = 100
const NUM_TRIANGLES = 1_0 * 1_000

########################################
#### Float32 Structs and Functions #####
########################################
const Maybe{T} = Union{T, Nothing}
abstract type Texture end
abstract type Shape end
abstract type Light end
abstract type Material end
abstract type BSDF end
struct Pnt4 <: FieldVector{4, Float32}
    x::Float32
    y::Float32
    z::Float32
    a::Float32
end
struct Pnt3 <: FieldVector{3, Float32}
    x::Float32
    y::Float32
    z::Float32
end
struct Pnt2 <: FieldVector{2, Float32}
    x::Float32
    y::Float32
end
struct Vec3 <: FieldVector{3, Float32}
    x::Float32
    y::Float32
    z::Float32
end
struct Nml3 <: FieldVector{3, Float32}
    x::Float32
    y::Float32
    z::Float32
end
mutable struct Ray
    origin::Pnt3
    direction::Vec3
    t::Float32
    tMax::Float32
end
const Mat4 = SMatrix{4, 4, Float32}
struct Transformation
    m::Mat4
    inv_m::Mat4
end
function Inv(t::Transformation)::Transformation
    return Transformation(
        t.inv_m,
        t.m
    )
end
function Translate(v::Union{Vec3,Pnt3})::Transformation
    m = Mat4([
        1.0f0 0.0f0 0.0f0 v[1]
        0.0f0 1.0f0 0.0f0 v[2]
        0.0f0 0.0f0 1.0f0 v[3]
        0.0f0 0.0f0 0.0f0 1.0f0
    ])
    m_inv = Mat4([
        1.0f0 0.0f0 0.0f0 -v[1]
        0.0f0 1.0f0 0.0f0 -v[2]
        0.0f0 0.0f0 1.0f0 -v[3]
        0.0f0 0.0f0 0.0f0 1.0f0
    ])
    return Transformation(m, m_inv)
end
struct ShapeCore
    object_to_world::Transformation
    world_to_object::Transformation
    reverse_orientation::Bool
    transform_swaps_handedness::Bool

    function ShapeCore(
        object_to_world=Translate(Pnt3(0,0,0)),
        world_to_object=Inv(Translate(Pnt3(0,0,0))),
        reverse_orientation=false,
        transform_swaps_handedness=false
    )
        return new(
            object_to_world,
            world_to_object,
            reverse_orientation,
            transform_swaps_handedness
        )
    end
end
struct TriangleMesh
    n_triangles::Int64
    n_vertices::Int64
    vertices::Vector{Pnt3}
    indices::Vector{Int64}
    normals::Vector{Nml3}
    uvs::Vector{Pnt2}
    alpha_mask::Maybe{Texture}
    shading_tangent::Nothing

    function TriangleMesh(
        object_to_world::Transformation, 
        n_triangles::Int64, 
        n_vertices::Int64, 
        vertices::Vector{Pnt3}, 
        indices::Vector{Int64}, 
        normals::Vector{Nml3},
        uvs::Vector{Pnt2},
        alpha_mask::Maybe{Texture},
    )
        vertices = object_to_world.(vertices)
        normals = object_to_world.(normals)
        new(
            n_triangles,
            n_vertices,
            vertices,
            indices,
            normals,
            uvs,
            alpha_mask,
            nothing
        )
    end
end
struct Triangle <: Shape
    core::ShapeCore
    mesh::TriangleMesh
    i::Int64
    
    function Triangle(core::ShapeCore, mesh::TriangleMesh, i::Int64)
        new(core, mesh, i*3+1)
    end
end
function construct_triangle_mesh(
    core::ShapeCore, 
    n_triangles::Int64, 
    n_vertices::Int64, 
    vertices::Vector{Pnt3}, 
    indices::Vector{Int64}, 
    normals::Vector{Nml3},
    uvs::Vector{Pnt2},
    alpha_mask::Maybe{Texture},
)
    mesh = TriangleMesh(
        core.object_to_world, 
        n_triangles, 
        n_vertices, 
        vertices, 
        indices, 
        normals, 
        uvs,
        alpha_mask
    )
    return [Triangle(core, mesh, i) for i in 0:n_triangles - 1]
end
function random_on_sphere(u::Pnt2)::Pnt3
    z = 1.0f0 - 2.0f0 * u.x
    r = sqrt(max(0.0f0, 1.0f0 - z^2))
    phi = 2.0f0 * Float32(pi) * u.y
    return Vec3(r * cos(phi), r * sin(phi), z)
end
function (t::Transformation)(p::Pnt3)::Pnt3
    tmp = Pnt4(p...,1.0f0)
    ph = Mat4([tmp tmp tmp tmp])
    pt = t.m * ph
    pr = Pnt3(pt[SA[1,2,3]])
    if pt[4] == 1.0f0
        return pr
    end
    return pr ./ pt[4]
end
function (t::Transformation)(v::Vec3)::Vec3
    return t.m[SA[1,2,3], SA[1,2,3]] * v
end
function (t::Transformation)(n::Nml3)::Nml3
    return transpose(t.inv_m[SA[1,2,3], SA[1,2,3]]) * n
end
@inline function get_vertices(t::Triangle)::Tuple{Pnt3, Pnt3, Pnt3}
    return t.mesh.vertices[t.mesh.indices[t.i + 0]], t.mesh.vertices[t.mesh.indices[t.i + 1]], t.mesh.vertices[t.mesh.indices[t.i + 2]]
end
@inline function get_normals(t::Triangle)::Tuple{Nml3, Nml3, Nml3}
    # TODO implement ability to NOT have normals
    return t.mesh.normals[t.mesh.indices[t.i + 0]], t.mesh.normals[t.mesh.indices[t.i + 1]], t.mesh.normals[t.mesh.indices[t.i + 2]]
end
@inline function get_uvs(t::Triangle)::Tuple{Pnt2, Pnt2, Pnt2}
    # TODO implement ability to NOT have UVs
    return t.mesh.uvs[t.mesh.indices[t.i + 0]], t.mesh.uvs[t.mesh.indices[t.i + 1]], t.mesh.uvs[t.mesh.indices[t.i + 2]]
end
struct Primitive
    shape::Shape
    material::Material
    area_light::Maybe{Light}
end
mutable struct Interaction
    # world coordinates
    p::Pnt3
    # time of intersection
    t::Float32
    # negative of ray direciton
    # direction from intersection to viewer
    wo::Vec3
    # surface normal in world coordinates
    n::Nml3
end
mutable struct ShadingInteraction
    n::Nml3
    dpdu::Vec3
    dpdv::Vec3
    dndu::Nml3
    dndv::Nml3
end
mutable struct SurfaceInteraction
    core::Interaction
    shading::ShadingInteraction
    uv::Pnt2

    dpdu::Vec3
    dpdv::Vec3
    dndu::Nml3
    dndv::Nml3

    shape::Maybe{Shape}
    primitive::Maybe{Primitive}
    bsdf::Maybe{AbstractBSDF}

    # more partials
    dudx::Float32
    dudy::Float32
    dvdx::Float32
    dvdy::Float32
    dpdx::Vec3
    dpdy::Vec3
end
function empty_surface_interation(s::Shape)::SurfaceInteraction
    return InstantiateSurfaceInteraction(
        Pnt3(1,1,1), 
        0.0f0,
        Vec3(1,1,1),
        Pnt2(.5, .5),
        Vec3(1,0,0),
        Vec3(0,1,0),
        Nml3(1,0,0),
        Nml3(0,1,0),
        s,
        nothing,
        nothing,
    )
end

function InstantiateSurfaceInteraction(
    p::Pnt3, 
    t::Float32,
    wo::Vec3,
    uv::Pnt2,
    dpdu::Vec3,
    dpdv::Vec3,
    dndu::Nml3,
    dndv::Nml3,
    shape::Maybe{Shape}=nothing,
    primitive::Maybe{Primitive}=nothing,
    bsdf::Maybe{AbstractBSDF}=nothing,
)::SurfaceInteraction
    n = Nml3(normalize(cross(dpdu, dpdv)))

    core = Interaction(p, t, wo, n)
    shading = ShadingInteraction(n, dpdu, dpdv, dndu, dndv)

    if !(shape isa Nothing)
        if shape.core.reverse_orientation
            core.n = core.n * -1.0f0
            shading.n = shading.n * -1.0f0
        end
    end

    return SurfaceInteraction(
        core, 
        shading,
        uv,
        dpdu,
        dpdv,
        dndu,
        dndv,
        shape,
        primitive,
        bsdf,
        0,
        0,
        0,
        0,
        Vec3(0, 0, 0),
        Vec3(0, 0, 0),
    )
end
function orthonormal_basis(v::Vec3)::Tuple{Vec3, Vec3, Vec3}
    if abs(v.x) > abs(v.y)
        v2 = Vec3(-v.z, 0.0f0, v.x) / sqrt(v.x^2 + v.z^2)
    else
        v2 = Vec3(0.0f0, v.z, -v.y) / sqrt(v.y^2 + v.z^2)
    end
    return v, v2, cross(v, v2)
end

# for implicit surface normal reverse engineering
function orthonormal_basis(v::Nml3)::Tuple{Nml3, Vec3, Vec3}
    if abs(v.x) > abs(v.y)
        v2 = Vec3(-v.z, 0.0f0, v.x) / sqrt(v.x^2 + v.z^2)
    else
        v2 = Vec3(0.0f0, v.z, -v.y) / sqrt(v.y^2 + v.z^2)
    end
    return v, v2, Vec3(cross(v, v2)) # cross product is anti-commutative so need to be v * v2 then cast
end

#################################
#### intersection functions #####
#################################

function intersect(tri::Triangle, ray::Ray, ::Bool=false)::Tuple{Bool, Maybe{Float32}, Maybe{SurfaceInteraction}}
    # get triangle vertices
    p0, p1, p2 = get_vertices(tri)
    
    # perform ray-triangle intersection test
    ## transform vertices to ray coord space
    p0t = Pnt3(p0 - Vec3(ray.origin))
    p1t = Pnt3(p1 - Vec3(ray.origin))
    p2t = Pnt3(p2 - Vec3(ray.origin))
    kz = argmax(abs.(ray.direction))
    kx = kz + 1
    if kx == 4
        kx = 1
    end
    ky = kx + 1
    if ky == 4
        ky = 1
    end
    permute = SVector(kx, ky, kz)
    d = Vec3(ray.direction[permute])
    p0t = Vec3(p0t[permute])
    p1t = Vec3(p1t[permute])
    p2t = Vec3(p2t[permute])
    Sx = -d.x / d.z
    Sy = -d.y / d.z
    Sz =  1.0f0 / d.z
    p0t = Vec3(p0t.x + Sx * p0t.z, p0t.y + Sy * p0t.z, p0t.z)
    p1t = Vec3(p1t.x + Sx * p1t.z, p1t.y + Sy * p1t.z, p1t.z)
    p2t = Vec3(p2t.x + Sx * p2t.z, p2t.y + Sy * p2t.z, p2t.z)

    ## compute edge function
    e0 = p1t.x * p2t.y - p1t.y * p2t.x
    e1 = p2t.x * p0t.y - p2t.y * p0t.x
    e2 = p0t.x * p1t.y - p0t.y * p1t.x
    
    ## fall back to double precision
    # TODO

    ## perform edge & det tests
    if (e0 < 0.0f0 || e1 < 0.0f0 || e2 < 0.0f0) && (e0 > 0.0f0 || e1 > 0.0f0 || e2 > 0.0f0)
        return false, 0.0, empty_surface_interation(tri)
    end
    det = e0 + e1 + e2
    if det == 0.0f0
        return false, 0.0f0, empty_surface_interation(tri)
    end

    ## compute scaled sitance to triangle and test against rayt
    p0t = Vec3(p0t.x, p0t.y, p0t.z * Sz)
    p1t = Vec3(p1t.x, p1t.y, p1t.z * Sz)
    p2t = Vec3(p2t.x, p2t.y, p2t.z * Sz)
    t_scaled = e0 * p0t.z + e1 * p1t.z + e2 * p2t.z
    if (det < 0.0f0 && (t_scaled >= 0.0f0 || t_scaled < ray.tMax * det))
        return false, 0.0, empty_surface_interation(tri)
    end
    if (det > 0.0f0 && (t_scaled <= 0.0f0 || t_scaled > ray.tMax * det))
        return false, 0.0f0, empty_surface_interation(tri)
    end

    ## compute barycentric coords and t for intesection
    inv_det = 1 / det
    b0 = e0 * inv_det
    b1 = e1 * inv_det
    b2 = e2 * inv_det
    t = t_scaled * inv_det

    # Compute triangle partial derivatives
    uv = get_uvs(tri)
    duv13 = uv[1] - uv[3]
    duv23 = uv[2] - uv[3]
    dp13 = p0 - p2
    dp23 = p1  - p2
    determinate = duv13[1] * duv23[2] - duv13[2] * duv23[1]
    degenerateUV = abs(determinate) < 1e-8
    if !degenerateUV
        invdet = 1.0f0/determinate
        dpdu = Vec3(( duv23[2]*dp13 - duv13[2]*dp23) * inv_det)
        dpdv = Vec3((-duv23[1]*dp13 + duv13[1]*dp23) * inv_det)
    end
    if degenerateUV || norm(cross(dpdu, dpdv))^2==0
        # Handle zero determinant for triangle partial derivative matrix
        ng = cross(p2 - p0, p1 - p0)
        if norm(ng)^2 == 0.0f0
            return false, 0.0f0, empty_surface_interation(tri)
        end
        _, dpu, dpv = orthonormal_basis(Vec3(ng))
        dpdu = Vec3(dpu)
        dpdv = Vec3(dpv)
    end

    # interpolate uv coords and hit point
    phit = b0 * p0 + b1 * p1 + b2 * p2
    uvhit = b0 * uv[1] + b1 * uv[2] + b2 * uv[3]

    # Test intersection against alpha texture, if present
    if !(tri.mesh.alpha_mask isa Nothing)
        si = InstantiateSurfaceInteraction(
                phit,
                0.0f0,
                Vec3(1,1,1),
                uvhit,
                Vec3(1,1,1),
                Vec3(1,1,1),
                Nml3(1,1,1),
                Nml3(1,1,1),
                tri,
                nothing,
                nothing
            )
        if tri.mesh.alpha_mask(si) == spectrum_from_float(1, 1, 1)
            return false, 0.0f0, si
        end
    end

    # Fill in _SurfaceInteraction_ from triangle hit
    interaction = InstantiateSurfaceInteraction(phit, ray.t, -ray.direction, uvhit, dpdu, dpdv, Nml3(0,0,0), Nml3(0,0,0), tri)

    # Override surface normal in _isect_ for triangle
    interaction.core.n = interaction.shading.n = Nml3(normalize(cross(dp13, dp23)))
    if tri.core.reverse_orientation ⊻ tri.core.transform_swaps_handedness
        interaction.core.n = interaction.shading.n = -interaction.core.n    
    end

    # TODO making shading tangents real
    # TODO JOHN HACK FOR NORMAL FLAG
    normal_flag = sum(sum.(tri.mesh.normals)) == 0.0
    if !(normal_flag) || !(tri.mesh.shading_tangent isa Nothing)
        # Initialize _Triangle_ shading geometry

        # Compute shading normal _ns_ for triangle
        if !(tri.mesh.normals isa Nothing)
            n1, n2, n3 = get_normals(tri)
            ns = normalize(
                b0 * n1 + b1 * n2 + b2 * n3
            )
            if norm(ns)^2 > 0.0f0
                ns = normalize(ns)
            else
                ns = interaction.core.n
            end
        else
            ns = interaction.core.n
        end

        # Compute shading tangent _ss_ for triangle
        if !(tri.mesh.shading_tangent isa Nothing)
            s1, s2, s3 = get_shading_tangents(tri)
            ss = b0 * s1 + b1 * s2 + b2 * s3
            if norm(ss)^2 > 0.0f0
                ss = normalize(ss)
            else
                ss = normalize(interaction.dpdu)
            end
        else
            ss = normalize(interaction.dpdu)
        end

        # Compute shading bitangent _ts_ for triangle and adjust _ss_
        ts = cross(ss, ns)
        if length_squared(ts) > 0.0f0
            ts = normalize(ts)
            ss = cross(ts, ns)
        else
            _, ss, ts = orthonormal_basis(Vec3(ns))
        end

        # Compute $\dndu$ and $\dndv$ for triangle shading geometry
        if !(tri.mesh.normals isa Nothing)
            n1, n2, n3 = get_normals(tri)
            # Compute deltas for triangle partial derivatives of normal
            duv02 = uv[1] - uv[3]
            duv12 = uv[2] - uv[3]
            dn1 = n1 - n3
            dn2 = n2 - n3
            determinant = duv02[1] * duv12[2] - duv02[2] * duv12[1]
            degenerateUV = abs(determinant) < Float32(1e-8)
            if degenerateUV
                dn = cross(
                    Vec3(n3-n1),
                    Vec3(n2-n1)
                )
                if norm(dn)^2 == 0.0f0
                    dndu = dndv = Nml3(0,0,0)
                else
                    _, dnu, dnv = orthonormal_basis(dn)
                    dndu = Nml3(dnu)
                    dndv = Nml3(dnv)
                end
            else
                inv_det = 1.0f0 / determinant
                dndu = (duv12[2] * dn1 - duv02[2] * dn2) * inv_det
                dndv = (-duv12[1] * dn1 + duv02[1] * dn2) * inv_det
            end
        else
            dndu = dndv = Nml3(0,0,0)
        end
        if tri.core.reverse_orientation
            ts = -ts
        end
        set_shading_geomerty!(interaction, ss, ts, dndu, dndv, true)
    end
    return true, t, interaction 
end

function intersect_p(tri::Triangle, ray::Ray, ::Bool=false)::Bool
    # get triangle vertices
    p0, p1, p2 = get_vertices(tri)
    
    # perform ray-triangle intersection test
    ## transform vertices to ray coord space
    p0t = Pnt3(p0 - Vec3(ray.origin))
    p1t = Pnt3(p1 - Vec3(ray.origin))
    p2t = Pnt3(p2 - Vec3(ray.origin))
    kz = argmax(abs.(ray.direction))
    kx = kz + 1
    if kx == 4
        kx = 1
    end
    ky = kx + 1
    if ky == 4
        ky = 1
    end
    permute = SVector(kx, ky, kz)
    d = Vec3(ray.direction[permute])
    p0t = Vec3(p0t[permute])
    p1t = Vec3(p1t[permute])
    p2t = Vec3(p2t[permute])
    Sx = -d.x / d.z
    Sy = -d.y / d.z
    Sz =  1.0f0 / d.z
    p0t = Vec3(p0t.x + Sx * p0t.z, p0t.y + Sy * p0t.z, p0t.z)
    p1t = Vec3(p1t.x + Sx * p1t.z, p1t.y + Sy * p1t.z, p1t.z)
    p2t = Vec3(p2t.x + Sx * p2t.z, p2t.y + Sy * p2t.z, p2t.z)

    ## compute edge function
    e0 = p1t.x * p2t.y - p1t.y * p2t.x
    e1 = p2t.x * p0t.y - p2t.y * p0t.x
    e2 = p0t.x * p1t.y - p0t.y * p1t.x
    
    ## fall back to double precision
    # TODO

    ## perform edge & det tests
    if (e0 < 0.0f0 || e1 < 0.0f0 || e2 < 0.0f0) && (e0 > 0.0f0 || e1 > 0.0f0 || e2 > 0.0f0)
        return false
    end
    det::Float32 = e0 + e1 + e2
    if det == 0.0f0
        return false
    end

    ## compute scaled sitance to triangle and test against rayt
    p0t = Vec3(p0t.x, p0t.y, p0t.z * Sz)
    p1t = Vec3(p1t.x, p1t.y, p1t.z * Sz)
    p2t = Vec3(p2t.x, p2t.y, p2t.z * Sz)
    t_scaled::Float32 = e0 * p0t.z + e1 * p1t.z + e2 * p2t.z
    if (det < 0.0f0 && (t_scaled >= 0.0f0 || t_scaled < ray.tMax * det))
        return false
    end
    if (det > 0.0f0 && (t_scaled <= 0.0f0 || t_scaled > ray.tMax * det))
        return false
    end

    return true
end

# instantiate vector of Rays
# instantiate vector of Triangles

function make_rays(N::Int64)::Vector{Ray}
    rays = Vector{Ray}(undef, N)
    for n in 1:N
        ro = random_on_sphere(Pnt2(Float32(rand()), Float32(rand())))
        rd = normalize(random_on_sphere(Pnt2(Float32(rand()), Float32(rand()))) - ro)
        rays[n] = Ray(ro, rd, 0, typemax(Float32))
    end
    return rays
end

function random_vertex()::Pnt3
    return Pnt3(
        Float32(rand())*2.0f0-1.0f0,
        Float32(rand())*2.0f0-1.0f0,
        Float32(rand())*2.0f0-1.0f0,
    )
end

function make_tris(N::Int64)::Vector{Triangle}
    tris = Vector{Triangle}(undef, N)
    tri_core = ShapeCore(Translate(Pnt3(0,0,0)), Translate(Pnt3(0,0,0)), false, false)
    for n in 1:N
        tris[n] = construct_triangle_mesh(
            tri_core,
            1,
            3,
            [random_vertex(), random_vertex(), random_vertex()],
            [1,2,3],
            [Nml3(0,0,0), Nml3(0,0,0), Nml3(0,0,0)],
            [Pnt2(0,0), Pnt2(0,0), Pnt2(0,0)],
            nothing
        )[1]
    end
    return tris
end


function run_p(tri_vec::Vector{Triangle}, ray_vec::Vector{Ray})::Tuple{Millisecond, Int64}
    hit = 0
    t0 = now()
    for ri in 1:length(ray_vec)
        r = ray_vec[ri]
        for ti in 1:length(tri_vec)
            t = tri_vec[ti]
            intersect_p(t, r) && (hit += 1)
        end
    end
    t1 = now()
    return t1-t0, hit
end

function run(tri_vec::Vector{Triangle}, ray_vec::Vector{Ray})::Tuple{Millisecond, Int64}
    hit = 0
    t0 = now()
    for ri in 1:length(ray_vec)
        r = ray_vec[ri]
        for ti in 1:length(tri_vec)
            t = tri_vec[ti]
            check, _, _ = intersect(t, r)
            check && (hit += 1)
        end
    end
    t1 = now()
    return t1-t0, hit
end

function num2str(num::Number; delim=",")
    decimal_point = "."
    str = string(num)
    strs = split(str, decimal_point)
    left_str = strs[1]
    right_str = length(strs) > 1 ? strs[2] : ""
    left_str = replace(left_str, r"(?<=[0-9])(?=(?:[0-9]{3})+(?![0-9]))" => delim)
    decimal_point = occursin(decimal_point, str) ? decimal_point : ""
    return left_str * decimal_point * right_str
 end

# # test intersection: set up
# print("Generating Rays & Triangles\n")
# tri_vec = make_tris(NUM_TRIANGLES)
# ray_vec = make_rays(NUM_RAYS)

# print("Running FAST tests...\n")
# t, hit = run_p(tri_vec, ray_vec)
# print("intersection test took: ", t, "\n")
# print("number of intersections tested: ", num2str(NUM_RAYS * NUM_TRIANGLES), "\n")
# print(round(hit / (NUM_RAYS * NUM_TRIANGLES) * 100, digits=3), "% of rays intersected\n")
# print(round((NUM_RAYS * NUM_TRIANGLES) / t.value / 1_000, digits=3), " million intersections per second\n")

# print("\n")
# print("Running SLOW tests...\n")
# t, hit = run(tri_vec, ray_vec)
# print("intersection test took: ", t, "\n")
# print("number of intersections tested: ", num2str(NUM_RAYS * NUM_TRIANGLES), "\n")
# print(round(hit / (NUM_RAYS * NUM_TRIANGLES) * 100, digits=3), "% of rays intersected\n")
# print(round((NUM_RAYS * NUM_TRIANGLES) / t.value / 1_000, digits=3), " million intersections per second\n")


# ROUND 0: changing as little as possible to get this to run
"""
Generating Rays & Triangles
Running FAST tests...
intersection test took: 72 milliseconds
number of intersections tested: 1,000,000
9.362% of rays intersected
13.889 million intersections per second

Running SLOW tests...
intersection test took: 389 milliseconds
number of intersections tested: 1,000,000
9.362% of rays intersected
2.571 million intersections per second
"""

# matrix explicitly float32
"""
Generating Rays & Triangles
Running FAST tests...
intersection test took: 64 milliseconds
number of intersections tested: 1,000,000
7.617% of rays intersected
15.625 million intersections per second

Running SLOW tests...
intersection test took: 278 milliseconds
number of intersections tested: 1,000,000
7.617% of rays intersected
3.597 million intersections per second
"""