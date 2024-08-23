struct BilinearPatchMesh
        n_patches::Int64
        n_vertices::Int64
        indices::Vector{Int64}
        p::Vector{Pnt3}
        n::Maybe{Vector{Nml3}}
        uv::Maybe{Vector{Pnt2}}
        alpha_mask::Maybe{Texture}
    
    function BilinearPatchMesh(
        object_to_world::Transformation,
        n_patches::Int64,
        n_vertices::Int64,
        indices::Vector{Int64},
        p::Vector{Pnt3},
        n::Maybe{Vector{Nml3}},
        uv::Maybe{Vector{Pnt2}},
        alpha_mask::Maybe{Texture},
    )
        p = object_to_world.(p)
        if !(n isa Nothing)
            n = object_to_world.(n)
        end
        return new(
            n_patches,
            n_vertices,
            indices,
            p,
            n,
            uv,
            alpha_mask
        )
        
    end
end

struct BilinearPatch <: Shape
    core::ShapeCore
    mesh::BilinearPatchMesh
    i::Int64
    area::Float64
    min_spherical_sample_area::Float64
end

function BilinearPatchGenerator(
    core::ShapeCore,
    n_patches::Int64,
    n_vertices::Int64,
    indices::Vector{Int64},
    p::Vector{Pnt3},
    n::Maybe{Vector{Nml3}},
    uv::Maybe{Vector{Pnt2}},
    alpha_mask::Maybe{Texture},
)::Vector{BilinearPatch}
    mesh = BilinearPatchMesh(
        core.object_to_world,
        n_patches,
        n_vertices,
        indices,
        p,
        n,
        uv,
        alpha_mask,
    )

    patches = BilinearPatch[]
    for i in 0:(n_patches-1)
        # Store area of bilinear patch in area
        # Get bilinear patch vertices in p00, p01, p10, and p11
        p00 = mesh.p[mesh.indices[i+0+1]+1]
        p10 = mesh.p[mesh.indices[i+1+1]+1]
        p01 = mesh.p[mesh.indices[i+2+1]+1]
        p11 = mesh.p[mesh.indices[i+3+1]+1]
        if is_rectangle(p00, p10, p01, p11)
            area = distance(p00, p01) * distance(p00, p10)
        else
            # TODO implement!
            @assert false
        end

        patch = BilinearPatch(core, mesh, i*4+1, area, 1e-4)

        push!(patches, patch)
    end
    @assert length(patches) == n_patches
    return patches
end

function ObjectBounds(blp::BilinearPatch)::Bounds3
    # TODO
    # BLP have their vertices already in world space so go backwards because
    # results of this function are transformed back
    # ugh
    p00, p10, p01, p11 = blp.core.world_to_object.(get_p(blp))
    # TODO why must I do this
    buffer = Float64[0, 0, 0]
    for i in 1:3
        if p00[i] == p10[i] == p01[i] == p11[i]
            buffer[i] = .0001
        end
    end
    return world_bounds(
            world_bounds(
                    Bounds3(p00-buffer, p00+buffer), 
                    Bounds3(p10-buffer, p10+buffer)
                ), 
            world_bounds(
                Bounds3(p01-buffer, p01+buffer),
                Bounds3(p11-buffer, p11+buffer)
            )
        )
end

function is_rectangle(p00::Pnt3, p10::Pnt3, p01::Pnt3, p11::Pnt3)::Bool
    if (p00 == p01) || (p01 == p11) || (p11 == p10) || (p10 == p00)
        return false # cause the above implies it's a triangle!!
    end

    # Check if bilinear patch vertices are coplanar
    n = normalize(cross(p10 - p00, p01 - p00))
    if abs(dot(normalize(p11 - p00), n)) > 1e-5
        return false
    end

    # Check if planar vertices form a rectangle>> 
    p_center = Pnt3(p00 + p01 + p10 + p11) / 4.0
    d2 = Float64[
        distance_squared(p00, p_center), 
        distance_squared(p01, p_center), 
        distance_squared(p10, p_center), 
        distance_squared(p11, p_center)
    ]
    for i in 1:3
        if abs(d2[i+1] - d2[0+1]) / d2[0+1] > 1e-4
            return false
        end
    end
    return true
end

function area(blp::BilinearPatch)::Float64
    return blp.area
end

@inline function get_p(blp::BilinearPatch)::Tuple{Pnt3, Pnt3, Pnt3, Pnt3}
    return (blp.mesh.p[blp.mesh.indices[blp.i + 0] + 1],
        blp.mesh.p[blp.mesh.indices[blp.i + 1] + 1], 
        blp.mesh.p[blp.mesh.indices[blp.i + 2] + 1], 
        blp.mesh.p[blp.mesh.indices[blp.i + 3] + 1]
    )
end

function intersect(blp::BilinearPatch, ray::AbstractRay, ::Bool=false)::Tuple{Bool, Maybe{Float64}, Maybe{SurfaceInteraction}}
    check, uv, t = intersect_bilinear_patch(blp, ray)
    if !check
        return false, nothing, nothing
    end

    p00, p10, p01, p11 = get_p(blp)
    
    # The barrier between function calls in pbrt-v4

    p::Pnt3 = lerp(u, Lerp(v, p00, p01), lerp(v, p10, p11))
    dpdu::Vec3 = lerp(v, p10, p11) - lerp(v, p00, p01)
    dpdv::Vec3 = lerp(u, p01, p11) - lerp(u, p00, p10)

    # Compute $(s,t)$ texture coordinates at bilinear patch $(u,v)$
    st = Pnt2(u, v)
    duds = 1.0
    dudt = 0.0
    dvds = 0.0
    dvdt = 1.0

    if !(blp.mesh.uv isa Nothing)
        @assert false # don't be here
        # # Compute texture coordinates for bilinear patch intersection point
        # uv00, uv10, uv01, uv11 = get_uvs(blp)
        # st = lerp(uv.x, lerp(uv.y, uv00, uv01), lerp(uv.y, uv10, uv11))

        # # Update bilinear patch $\dpdu$ and $\dpdv$ accounting for $(s,t)$
        # # Compute partial derivatives of $(u,v)$ with respect to $(s,t)$
        # dstdu::Vec2 = lerp(uv.y, uv10, uv11) - lerp(uv.y, uv00, uv01)
        # dstdv::Vec2 = lerp(uv.x, uv01, uv11) - lerp(uv.x, uv00, uv10)
        # duds = abs(dstdu.x) < 1e-8 ? 0.0 : 1.0 / dstdu.x
        # dvds = abs(dstdv.x) < 1e-8 ? 0.0 : 1.0 / dstdv.x
        # dudt = abs(dstdu.y) < 1e-8 ? 0.0 : 1.0 / dstdu.y
        # dvdt = abs(dstdv.y) < 1e-8 ? 0.0 : 1.0 / dstdv.y

        # # Compute partial derivatives of $\pt{}$ with respect to $(s,t)$
        # dpds::Vec3 = dpdu * duds + dpdv * dvds
        # dpdt::Vec3 = dpdu * dudt + dpdv * dvdt

        # # Set _dpdu_ and _dpdv_ to updated partial derivatives
        # if (cross(dpds, dpdt) != Vec3(0, 0, 0))
        #     if (dot(cross(dpdu, dpdv), cross(dpds, dpdt)) < 0.0)
        #         dpdt = -dpdt
        #     # @assert dot(normalize(cross(dpdu, dpdv)), normalize(cross(dpds, dpdt))) > -1e-3
        #     dpdu = dpds
        #     dpdv = dpdt
        # end
    end

    # Find partial derivatives $\dndu$ and $\dndv$ for bilinear patch
    d2Pduu = Vec3(0, 0, 0)
    d2Pdvv = Vec3(0, 0, 0)
    d2Pduv::Vec3 = (p00 - p01) + (p11 - p10)
    # Compute coefficients for fundamental forms
    E = dot(dpdu, dpdu)
    F = dot(dpdu, dpdv)
    G = dot(dpdv, dpdv)
    n::Vec3 = normalize(cross(dpdu, dpdv))
    e = dot(n, d2Pduu)
    f = dot(n, d2Pduv)
    g = dot(n, d2Pdvv)

    # Compute $\dndu$ and $\dndv$ from fundamental form coefficients
    EGF2 = difference_of_products(E, G, F, F)
    invEGF2 = (EGF2 == 0.0) ? 0.0 : 1.0 / EGF2
    dndu::Nml3 = (f * F - e * G) * invEGF2 * dpdu + (e * F - f * E) * invEGF2 * dpdv
    dndv::Nml3 = (g * F - f * G) * invEGF2 * dpdu + (f * F - g * E) * invEGF2 * dpdv

    # Update $\dndu$ and $\dndv$ to account for $(s,t)$ parameterization
    dnds = dndu * duds + dndv * dvds
    dndt = dndu * dudt + dndv * dvdt
    dndu = dnds
    dndv = dndt

    # Initialize bilinear patch intersection point error _pError_
    pAbsSum::Pnt3 = abs.(p00) + abs.(p01) + abs.(p10) + abs.(p11)

    # Initialize _SurfaceInteraction_ for bilinear patch intersection
    flipNormal = blp.core.reverse_orientation ^ blp.core.swap_handedness
    isect = SurfaceInteraction(
        p, 
        st, 
        wo, 
        dpdu, 
        dpdv, 
        dndu, 
        dndv,
        time, 
        flipNormal, 
        faceIndex
    )

    # Compute bilinear patch shading normal if necessary
    if !(blp.mesh.n isa Nothing)
        @assert false # don't be here
        # # Compute shading normals for bilinear patch intersection point
        # n00, n10, n01, n11 = get_n(blp)
        # ns::Nml3 = lerp(uv.x, lerp(uv.y, n00, n01), lerp(uv.y, n10, n11))
        # if (length_squared(ns) > 0.0)
        #     ns = normalize(ns)
        #     # Set shading geometry for bilinear patch intersection
        #     dndu::Nml3 = lerp(uv.y, n10, n11) - lerp(uv.y, n00, n01)
        #     dndv::Nml3 = lerp(uv.x, n01, n11) - lerp(uv.x, n00, n10)
        #     # Update $\dndu$ and $\dndv$ to account for $(s,t)$ parameterization
        #     dnds::Nml3 = dndu * duds + dndv * dvds
        #     dndt::Nml3 = dndu * dudt + dndv * dvdt
        #     dndu = dnds
        #     dndv = dndt

        #     set_shading_geomerty!(isect, dpdu, dpdv, dndus, dndvs, true)
        # end
    end
    return true, time, isect
end

function intersect_p(blp::BilinearPatch, ray::AbstractRay, ::Bool=false)::Bool
    check, _, _ = intersect_bilinear_patch(blp, ray)
    return check
end

function intersect_bilinear_patch(blp::BilinearPatch, ray::AbstractRay, ::Bool=false)::Tuple{Bool, Maybe{Pnt2}, Maybe{Float64}}
    p00, p10, p01, p11 = get_p(blp)
    #  Find quadratic coefficients for distance from ray to $u$ iso-lines
    a = dot(cross(p10 - p00, p01 - p11), ray.direction)
    c = dot(cross(p00 - ray.origin, ray.direction), p01 - p00)
    b = dot(cross(p10 - ray.origin, ray.direction), p11 - p10) - (a + c)

    #  Solve quadratic for bilinear patch $u$ intersection
    exists, u1, u2 = solve_quadratic(a, b, c)
    if !exists
        return false, nothing, nothing
    end

    # Find epsilon _eps_ to ensure that candidate $t$ is greater than zero
    eps = gamma(10) * (maximum(abs.(ray.origin)) + 
        maximum(abs.(ray.direction)) + 
        maximum(abs.(p00)) + 
        maximum(abs.(p10)) + 
        maximum(abs.(p01)) + 
        maximum(abs.(p11)))

    # Compute $v$ and $t$ for the first $u$ intersection
    t = ray.tMax
    u, v = 0.0, 0.0
    if ((0.0 <= u1) && (u1 <= 1.0))
        #  Precompute common terms for $v$ and $t$ computation
        uo = lerp(u1, p00, p10)
        ud = lerp(u1, p01, p11) - uo
        deltao = uo - ray.origin
        perp = cross(ray.direction, ud)
        p2 = length_squared(perp)

        # Compute matrix determinants for $v$ and $t$ numerators
        v1 = det(Mat3([deltao.x ray.direction.x perp.x deltao.y ray.direction.y perp.y deltao.z ray.direction.z perp.z]))
        t1 = det(Mat3([deltao.x ud.x perp.x deltao.y ud.y perp.y deltao.z ud.z perp.z]))

        #  Set _u_, _v_, and _t_ if intersection is valid
        if ((t1 > p2 * eps) && (0.0 <= v1) && (v1 <= p2))
            u = u1
            v = v1 / p2
            t = t1 / p2
        end
    end

    # Compute $v$ and $t$ for the second $u$ intersection
    if ((0.0 <= u2) && (u2 <= 1.0) && (u2 != u1))
        uo = lerp(u2, p00, p10)
        ud = lerp(u2, p01, p11) - uo
        deltao = uo - ray.origin
        perp = cross(ray.direction, ud)
        p2 = length_squared(perp)
        v2 = det(Mat3([deltao.x ray.direction.x perp.x deltao.y ray.direction.y perp.y deltao.z ray.direction.z perp.z]))
        t2 = det(Mat3([deltao.x ud.x perp.x deltao.y ud.y perp.y deltao.z ud.z perp.z]))
        t2 /= p2
        if (0.0 <= v2 && v2 <= p2 && t > t2 && t2 > eps)
            t = t2
            u = u2
            v = v2 / p2
        end
    end

    # TODO: reject hits with sufficiently small t that we're not sure.
    # Check intersection $t$ against _tMax_ and possibly return intersection
    if (t >= ray.tMax)
        return false, nothing, nothing
    end
    return true, uv, t
end