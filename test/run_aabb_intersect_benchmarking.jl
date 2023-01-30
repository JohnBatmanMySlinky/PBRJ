include("../src/RayTracing.jl")

using Dates


function intersect_p_1(b::RayTracing.Bounds3, r::RayTracing.Ray)::Bool
    tmin = 0
    tmax = r.tMax
    for a = 1:3
        @inbounds t0 = min(
            (b.pMin[a] - r.origin[a]) / r.direction[a],
            (b.pMax[a] - r.origin[a]) / r.direction[a]
        )
        @inbounds t1 = max(
            (b.pMin[a] - r.origin[a]) / r.direction[a],
            (b.pMax[a] - r.origin[a]) / r.direction[a]
        )
        tmin = max(t0, tmin)
        tmax = min(t1, tmax)
        if tmax <= tmin
            return false
        end
    end
    return true
end

function intersect_p_2(b::RayTracing.Bounds3, r::RayTracing.Ray)::Bool
    tmin = 0
    tmax = r.tMax
    for a = 1:3
        t0 = min(
            (b.pMin[a] - r.origin[a]) / r.direction[a],
            (b.pMax[a] - r.origin[a]) / r.direction[a]
        )
        t1 = max(
            (b.pMin[a] - r.origin[a]) / r.direction[a],
            (b.pMax[a] - r.origin[a]) / r.direction[a]
        )
        tmin = max(t0, tmin)
        tmax = min(t1, tmax)
        if tmax <= tmin
            return false
        end
    end
    return true
end

function intersect_p_3(b::RayTracing.Bounds3, r::RayTracing.Ray)::Bool
    tmin = 0
    tmax = r.tMax
    for i = 1:3
        x = (b.pMin[i] - r.origin[i]) / r.direction[i]
        y = (b.pMax[i] - r.origin[i]) / r.direction[i]
        t0 = min(x,y)
        t1 = max(x,y)
        tmin = max(t0, tmin)
        tmax = min(t1, tmax)
        if tmax <= tmin
            return false
        end
    end
    return true
end

function rand_unit()::Float64
    return rand()*2.0-1
end

function make_boxes(N::Int64)::Vector{RayTracing.Bounds3}
    v = Vector{RayTracing.Bounds3}(undef, N)
    for n in 1:N
        a, b, c, d, e, f = rand_unit(), rand_unit(), rand_unit(), rand_unit(), rand_unit(), rand_unit()
        minx = min(a,b)
        maxx = max(a,b)
        miny = min(c,d)
        maxy = max(c,d)
        minz = min(e,f)
        maxz = max(e,f)
        v[n] = RayTracing.Bounds3(RayTracing.Pnt3(minx, miny, minz), RayTracing.Pnt3(maxx, maxy, maxz))
    end
    return v
end

function make_rays(N::Int64)::Vector{RayTracing.Ray}
    rays = Vector{RayTracing.Ray}(undef, N)
    for n in 1:N
        ro = RayTracing.random_on_sphere(RayTracing.Pnt2(rand(), rand()))
        rd = RayTracing.normalize(RayTracing.random_on_sphere(RayTracing.Pnt2(rand(), rand())) - ro)
        rays[n] = RayTracing.Ray(ro, rd, 0, typemax(Float64))
    end
    return rays
end

function run_1(B::Vector{RayTracing.Bounds3}, R::Vector{RayTracing.Ray})::Tuple{Millisecond, Int64}
    hit = 0
    t0 = now()
    for ri in 1:length(R)
        r = R[ri]
        for bi in 1:length(B)
            b = B[bi]
            check = intersect_p_1(b, r)
            check && (hit += 1)
        end
    end
    t1 = now()
    return t1-t0, hit
end
function run_2(B::Vector{RayTracing.Bounds3}, R::Vector{RayTracing.Ray})::Tuple{Millisecond, Int64}
    hit = 0
    t0 = now()
    for ri in 1:length(R)
        r = R[ri]
        for bi in 1:length(B)
            b = B[bi]
            check = intersect_p_2(b, r)
            check && (hit += 1)
        end
    end
    t1 = now()
    return t1-t0, hit
end
function run_3(B::Vector{RayTracing.Bounds3}, R::Vector{RayTracing.Ray})::Tuple{Millisecond, Int64}
    hit = 0
    t0 = now()
    for ri in 1:length(R)
        r = R[ri]
        for bi in 1:length(B)
            b = B[bi]
            check = intersect_p_3(b, r)
            check && (hit += 1)
        end
    end
    t1 = now()
    return t1-t0, hit
end
function run_4(B::Vector{RayTracing.Bounds3}, R::Vector{RayTracing.Ray})::Tuple{Millisecond, Int64}
    hit = 0
    t0 = now()
    for ri in 1:length(R)
        r = R[ri]
        for bi in 1:length(B)
            b = B[bi]

            inv_dir = 1.0 ./ r.direction
            dir_is_neg = RayTracing.is_dir_negative(r.direction)


            check = RayTracing.intersect_p(b, r, inv_dir, dir_is_neg)
            check && (hit += 1)
        end
    end
    t1 = now()
    return t1-t0, hit
end

const NUM_RAYS = 1_000 * 10
const NUM_BOXES = 1_000 * 10

print("Generating Rays & Boxes\n")
rays = make_rays(NUM_RAYS)
boxes = make_boxes(NUM_BOXES)

print("inbounded\n")
t, hit = run_1(boxes, rays)
print("intersection test took: ", t, "\n")
print("number of intersections tested: ", RayTracing.num2str(NUM_RAYS * NUM_BOXES), "\n")
print(round(hit / (NUM_RAYS * NUM_BOXES) * 100, digits=3), "% of rays intersected\n")
print(round((NUM_RAYS * NUM_BOXES) / t.value / 1_000, digits=3), " million intersections per second\n")

print("\n\n")
print("baseline\n")
t, hit = run_2(boxes, rays)
print("intersection test took: ", t, "\n")
print("number of intersections tested: ", RayTracing.num2str(NUM_RAYS * NUM_BOXES), "\n")
print(round(hit / (NUM_RAYS * NUM_BOXES) * 100, digits=3), "% of rays intersected\n")
print(round((NUM_RAYS * NUM_BOXES) / t.value / 1_000, digits=3), " million intersections per second\n")

print("\n\n")
print("baseline+pre-compute\n")
t, hit = run_3(boxes, rays)
print("intersection test took: ", t, "\n")
print("number of intersections tested: ", RayTracing.num2str(NUM_RAYS * NUM_BOXES), "\n")
print(round(hit / (NUM_RAYS * NUM_BOXES) * 100, digits=3), "% of rays intersected\n")
print(round((NUM_RAYS * NUM_BOXES) / t.value / 1_000, digits=3), " million intersections per second\n")

print("\n\n")
print("pxlth\n")
t, hit = run_4(boxes, rays)
print("intersection test took: ", t, "\n")
print("number of intersections tested: ", RayTracing.num2str(NUM_RAYS * NUM_BOXES), "\n")
print(round(hit / (NUM_RAYS * NUM_BOXES) * 100, digits=3), "% of rays intersected\n")
print(round((NUM_RAYS * NUM_BOXES) / t.value / 1_000, digits=3), " million intersections per second\n")