struct BilinearPatchMesh
        n_patches::Int64
        n_vertices::Int64
        indices::Vector{Int64}
        p::Vector{Pnt3}
        n::Vector{Nml3}
        uv::Vector{Pnt2}
        alpha_mask::Maybe{Texture}
    
    function BilinearPatchMesh(
        object_to_world::Transformation,
        n_patches::Int64,
        n_vertices::Int64,
        indices::Vector{Int64},
        p::Vector{Pnt3},
        n::Vector{Nml3},
        uv::Vector{Pnt2},
        alpha_mask::Maybe{Texture},
    )
        p = object_to_world.(p)
        n = object_to_world.(n)
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

    function BilinearPatch(core::ShapeCore, mesh::BilinearPatchMesh, i::Int64)
        # Store area of bilinear patch in area
        # Get bilinear patch vertices in p00, p01, p10, and p11
        p00 = mesh.p[mesh.indices[i+0]]
        p10 = mesh.p[mesh.indices[i+1]]
        p01 = mesh.p[mesh.indices[i+2]]
        p11 = mesh.p[mesh.indices[i+3]]
        if is_rectangle(p00, p10, p10, p11)
            area = distance(p00, p01) * distance(p00, p10)
        else
            # TODO implement!
            @assert false
        end
        new(core, mesh, i*4+1, area, 1e-4)
    end
end

function ObjectBounds(blp::BilinearPatch)::Bounds3
    # TODO
    # BLP have their vertices already in world space so go backwards because
    # results of this function are transformed back
    # ugh
    p00, p10, p01, p11 = blp.core.world_to_object.(get_p(blp))
    # TODO why must I do this
    buffer = Float64[0, 0, 0, 0]
    for i in 1:4
        if p00[i] == p10[i] == p01[i] == p11[i]
            buffer[i] = .0001
        end
    end
    return 
        world_bounds(
            world_bounds(
                    Bounds3(p0-buffer, p0+buffer), 
                    Bounds3(p1-buffer, p1+buffer)
                ), 
            world_bounds(
                Bounds3(p2-buffer, p2+buffer),
                Bounds3(p3-buffer, p3+buffer)
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
        distance_squared(p00, p_center), distance_squared(p01, p_center), 
        distance_squared(p10, p_center), distance_squared(p11, p_center)
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
    return 
        blp.mesh.p[blp.mesh.indices[blp.i + 0]], 
        blp.mesh.p[blp.mesh.indices[blp.i + 1]], 
        blp.mesh.p[blp.mesh.indices[blp.i + 2]],
        blp.mesh.p[blp.mesh.indices[blp.i + 3]]
end

function intersect(blp::BilinearPatch, ray::AbstractRay, ::Bool=false)::Tuple{Bool, Maybe{Float64}, Maybe{SurfaceInteraction}}
    p00, p10, p01, p11 = get_p(blp)
    #  Find quadratic coefficients for distance from ray to $u$ iso-lines
    a = dot(cross(p10 - p00, p01 - p11), ray.direction)
    c = dot(cross(p00 - ray.origin, ray.ddirection), p01 - p00)
    b = dot(cross(p10 - ray..origin, ray.direction), p11 - p10) - (a + c)

    #  Solve quadratic for bilinear patch $u$ intersection
    exists, u1, u2 = solve_quadratic(a, b, c)
    if !exists
        return false, nothing, nothing
    end

    # Find epsilon _eps_ to ensure that candidate $t$ is greater than zero
    eps = gamma(10) * (max(abs.(ray.o)) + 
        max(abs.(ray.d)) + 
        max(abs.(p00)) + 
        max(abs.(p10)) + 
        max(abs.(p01)) + 
        max(abs.(p11)))

    # Compute $v$ and $t$ for the first $u$ intersection
    t = ray.tMax
    u, v = 0.0, 0.0
    if (0.0 <= u1 && u1 <= 1.0)
        #  Precompute common terms for $v$ and $t$ computation
        uo::Pnt3 = lerp(u1, p00, p10)
        ud::Vec3 = lerp(u1, p01, p11) - uo
        deltao::Vec3 = uo - ray.o
        perp::Vec3 = cross(ray.d, ud)
        p2 = length_squared(perp)

        # Compute matrix determinants for $v$ and $t$ numerators
        v1 = Determinant(SquareMatrix<3>(deltao.x, ray.d.x, perp.x, deltao.y, ray.d.y, perp.y, deltao.z, ray.d.z, perp.z))
        t1 = Determinant(SquareMatrix<3>(deltao.x, ud.x, perp.x, deltao.y, ud.y, perp.y, deltao.z, ud.z, perp.z))

        #  Set _u_, _v_, and _t_ if intersection is valid
        if (t1 > p2 * eps && 0 <= v1 && v1 <= p2)
            u = u1
            v = v1 / p2
            t = t1 / p2
        end
    end

    # Compute $v$ and $t$ for the second $u$ intersection
    if (0 <= u2 && u2 <= 1 && u2 != u1)
        uo::Pnt3 = lerp(u2, p00, p10)
        ud::Vec3 = lerp(u2, p01, p11) - uo
        deltao::Vec3 = uo - ray.o
        perp::Vec3 = cross(ray.d, ud)
        p2 = length_squared(perp)
        v2 = Determinant(SquareMatrix<3>(deltao.x, ray.d.x, perp.x, deltao.y, ray.d.y, perp.y, deltao.z, ray.d.z, perp.z))
        t2 = Determinant(SquareMatrix<3>(deltao.x, ud.x, perp.x, deltao.y, ud.y, perp.y, deltao.z, ud.z, perp.z))
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
    
    # OK construct intersection from 
    # https://github.com/mmp/pbrt-v4/blob/39e01e61f8de07b99859df04b271a02a53d9aeb2/src/pbrt/shapes.h#L1396

    p::Pnt3 = lerp(u, Lerp(v, p00, p01), lerp(v, p10, p11))
    dpdu::Vec3 = lerp(v, p10, p11) - lerp(v, p00, p01)
    dpdv::Vec3 = lerp(u, p01, p11) - lerp(u, p00, p10)

    # Compute $(s,t)$ texture coordinates at bilinear patch $(u,v)$
    st = Pnt2(u, v)
    duds = 1.0, dudt = 0.0, dvds = 0.0, dvdt = 1.0

    if !(blp.mesh.uv isa Nothing)
        # Compute texture coordinates for bilinear patch intersection point
        uv00, uv10, uv01, uv11 = get_uvs(blp)
        st = lerp(uv.x, lerp(uv.y, uv00, uv01), lerp(uv.y, uv10, uv11))

        # Update bilinear patch $\dpdu$ and $\dpdv$ accounting for $(s,t)$
        # Compute partial derivatives of $(u,v)$ with respect to $(s,t)$
        dstdu::Vec2 = lerp(uv.y, uv10, uv11) - lerp(uv.y, uv00, uv01)
        dstdv::Vec2 = lerp(uv.x, uv01, uv11) - lerp(uv.x, uv00, uv10)
        duds = abs(dstdu.x) < 1e-8f ? 0 : 1 / dstdu.x
        dvds = abs(dstdv.x) < 1e-8f ? 0 : 1 / dstdv.x
        dudt = abs(dstdu.y) < 1e-8f ? 0 : 1 / dstdu.y
        dvdt = abs(dstdv.y) < 1e-8f ? 0 : 1 / dstdv.y

        # Compute partial derivatives of $\pt{}$ with respect to $(s,t)$
        dpds::Vec3 = dpdu * duds + dpdv * dvds
        dpdt::Vec3 = dpdu * dudt + dpdv * dvdt

        # Set _dpdu_ and _dpdv_ to updated partial derivatives
        if (cross(dpds, dpdt) != Vec3(0, 0, 0))
            if (dot(cross(dpdu, dpdv), cross(dpds, dpdt)) < 0.0)
                dpdt = -dpdt
            # @assert dot(normalize(cross(dpdu, dpdv)), normalize(cross(dpds, dpdt))) > -1e-3
            dpdu = dpds
            dpdv = dpdt
        end
    end

    # Find partial derivatives $\dndu$ and $\dndv$ for bilinear patch
    Vector3f d2Pduu(0, 0, 0), d2Pdvv(0, 0, 0);
    Vector3f d2Pduv = (p00 - p01) + (p11 - p10);
    # Compute coefficients for fundamental forms
    Float E = Dot(dpdu, dpdu), F = Dot(dpdu, dpdv), G = Dot(dpdv, dpdv);
    Vector3f n = Normalize(Cross(dpdu, dpdv));
    Float e = Dot(n, d2Pduu), f = Dot(n, d2Pduv), g = Dot(n, d2Pdvv);

    # Compute $\dndu$ and $\dndv$ from fundamental form coefficients
    Float EGF2 = DifferenceOfProducts(E, G, F, F);
    Float invEGF2 = (EGF2 == 0) ? Float(0) : 1 / EGF2;
    Normal3f dndu =
        Normal3f((f * F - e * G) * invEGF2 * dpdu + (e * F - f * E) * invEGF2 * dpdv);
    Normal3f dndv =
        Normal3f((g * F - f * G) * invEGF2 * dpdu + (f * F - g * E) * invEGF2 * dpdv);

    # Update $\dndu$ and $\dndv$ to account for $(s,t)$ parameterization
    Normal3f dnds = dndu * duds + dndv * dvds;
    Normal3f dndt = dndu * dudt + dndv * dvdt;
    dndu = dnds;
    dndv = dndt;

    # Initialize bilinear patch intersection point error _pError_
    Point3f pAbsSum = Abs(p00) + Abs(p01) + Abs(p10) + Abs(p11);
    Vector3f pError = gamma(6) * Vector3f(pAbsSum);

    # Initialize _SurfaceInteraction_ for bilinear patch intersection
    int faceIndex = mesh->faceIndices ? mesh->faceIndices[blpIndex] : 0;
    bool flipNormal = mesh->reverseOrientation ^ mesh->transformSwapsHandedness;
    SurfaceInteraction isect(Point3fi(p, pError), st, wo, dpdu, dpdv, dndu, dndv,
                             time, flipNormal, faceIndex);

    # Compute bilinear patch shading normal if necessary
    if (mesh->n) {
        # Compute shading normals for bilinear patch intersection point
        Normal3f n00 = mesh->n[v[0]], n10 = mesh->n[v[1]];
        Normal3f n01 = mesh->n[v[2]], n11 = mesh->n[v[3]];
        Normal3f ns = Lerp(uv[0], Lerp(uv[1], n00, n01), Lerp(uv[1], n10, n11));
        if (LengthSquared(ns) > 0) {
            ns = Normalize(ns);
            # Set shading geometry for bilinear patch intersection
            Normal3f dndu = Lerp(uv[1], n10, n11) - Lerp(uv[1], n00, n01);
            Normal3f dndv = Lerp(uv[0], n01, n11) - Lerp(uv[0], n00, n10);
            # Update $\dndu$ and $\dndv$ to account for $(s,t)$ parameterization
            Normal3f dnds = dndu * duds + dndv * dvds;
            Normal3f dndt = dndu * dudt + dndv * dvdt;
            dndu = dnds;
            dndv = dndt;

            Transform r = RotateFromTo(Vector3f(Normalize(isect.n)), Vector3f(ns));
            isect.SetShadingGeometry(ns, r(dpdu), r(dpdv), dndu, dndv, true);
        }
    }

    return isect;
end

function intersect_p(blp::BilinearPatch, ray::AbstractRay, ::Bool=false)::Bool
    
end