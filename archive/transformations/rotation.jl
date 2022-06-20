struct Rotate <: Hittable
    p::Union{Hittable, BVHNode}
    mat::SMatrix{3, 3, Float64}
    invmat::SMatrix{3, 3, Float64}
end

function Rotate(p::Union{Hittable, BVHNode}, degrees::Vec3)::Rotate
    mat, invmat = get_rotate_mat(degrees)
    return Rotate(
        p,
        mat,
        invmat
    )
end

function get_rotate_mat(degrees::Vec3)::Tuple{SMatrix{3,3,Float64}, SMatrix{3,3,Float64}}
    #https://en.wikipedia.org/wiki/Rotation_matrix
    gamma = deg2rad(degrees[1])
    beta = deg2rad(degrees[2])
    alpha = deg2rad(degrees[3])

    singamma = sin(gamma)
    sinbeta = sin(beta)
    sinalpha = sin(alpha)

    cosgamma = cos(gamma)
    cosbeta = cos(beta)
    cosalpha = cos(alpha)

    mat = SA[
        cosalpha*cosbeta cosalpha*sinbeta*gamma-sinalpha*cosgamma cosalpha*sinbeta*cosgamma+sinalpha*singamma;
        sinalpha*cosbeta sinalpha*sinbeta*singamma+cosalpha*cosgamma sinalpha*sinbeta*cosgamma-cosalpha*singamma;
        -sinbeta cosbeta*singamma cosbeta*cosgamma
    ]

    invmat = inv(mat)

    return mat, invmat
end

function hit(ro::Rotate, r::Ray, tmin::Float64, tmax::Float64)::Option{HitRecord}
    new_origin = transpose(transpose(r.origin) * ro.mat)
    new_direction = transpose(transpose(r.direction) * ro.mat)
    rotated_r = Ray(new_origin, new_direction, r.time)

    hit_record = hit(ro.p, rotated_r, tmin, tmax)    
    if ismissing(hit_record)
        return missing
    else
        new_p = transpose(transpose(hit_record.p) * ro.invmat)
        new_n = transpose(transpose(hit_record.normal) * ro.invmat)

        if check_face_normal(rotated_r, new_n)
            ff = true
            n = new_n
        else
            ff = false
            n = -new_n
        end
        new_hit_record = HitRecord(
            hit_record.t,
            new_p,
            n,
            hit_record.material,
            ff,
            hit_record.u,
            hit_record.v
        )
    end
end

function bounding_box(ro::Rotate, time0::Float64, time1::Float64)::Option{AABB}
    box = bounding_box(ro.p, 0.0, 1.0)

    vmin = Vec3(typemax(Float64), typemax(Float64), typemax(Float64))
    vmax = Vec3(typemin(Float64), typemin(Float64), typemin(Float64))

    for i = 0:2
        for j = 0:2
            for k = 0:2
                x = i * box.maximum[1] + (1-i) * box.minimum[1]
                y = j * box.maximum[2] + (1-j) * box.minimum[2]
                z = k * box.maximum[3] + (1-k) * box.minimum[3]

                tester = transpose(transpose(Vec3(x,y,z)) * ro.invmat)

                vmin = min.(vmin, tester)
                vmax = max.(vmax, tester)
            end
        end
    end

    return AABB(vmin, vmax)
end