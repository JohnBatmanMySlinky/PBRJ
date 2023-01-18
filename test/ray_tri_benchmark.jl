include("../src/RayTracing.jl")

using Dates

const NUM_RAYS = 100
const NUM_TRIANGLES = 1_000 * 1000

# instantiate vector of Rays
# instantiate vector of Triangles

function make_rays(N::Int64)::Vector{RayTracing.Ray}
    rays = Vector{RayTracing.Ray}(undef, N)
    for n in 1:N
        ro = RayTracing.random_on_sphere(RayTracing.Pnt2(rand(), rand()))
        rd = RayTracing.normalize(RayTracing.random_on_sphere(RayTracing.Pnt2(rand(), rand())) - ro)
        rays[n] = RayTracing.Ray(ro, rd, 0, typemax(Float64))
    end
    return rays
end

function random_vertex()::RayTracing.Pnt3
    return RayTracing.Pnt3(
        rand()*2.0-1.0,
        rand()*2.0-1.0,
        rand()*2.0-1.0
    )
end

function make_tris(N::Int64)::Vector{RayTracing.Triangle}
    tris = Vector{RayTracing.Triangle}(undef, N)
    tri_core = RayTracing.ShapeCore(RayTracing.Translate(RayTracing.Pnt3(0,0,0)), RayTracing.Translate(RayTracing.Pnt3(0,0,0)), false, false)
    for n in 1:N
        tris[n] = RayTracing.construct_triangle_mesh(
            tri_core,
            1,
            3,
            [random_vertex(), random_vertex(), random_vertex()],
            [1,2,3],
            [RayTracing.Nml3(0,0,0), RayTracing.Nml3(0,0,0), RayTracing.Nml3(0,0,0)],
        )[1]
    end
    return tris
end


function run_p(tri_vec::Vector{RayTracing.Triangle}, ray_vec::Vector{RayTracing.Ray})::Tuple{Millisecond, Int64}
    hit = 0
    t0 = now()
    for ri in 1:length(ray_vec)
        r = ray_vec[ri]
        for ti in 1:length(tri_vec)
            t = tri_vec[ti]
            RayTracing.intersect_p(t, r) && (hit += 1)
        end
    end
    t1 = now()
    return t1-t0, hit
end

function run_p_MT(tri_vec::Vector{RayTracing.Triangle}, ray_vec::Vector{RayTracing.Ray})::Tuple{Millisecond, Int64}
    hit = 0
    t0 = now()
    for ri in 1:length(ray_vec)
        r = ray_vec[ri]
        for ti in 1:length(tri_vec)
            t = tri_vec[ti]
            RayTracing.intersect_p_MT(t, r) && (hit += 1)
        end
    end
    t1 = now()
    return t1-t0, hit
end

function run(tri_vec::Vector{RayTracing.Triangle}, ray_vec::Vector{RayTracing.Ray})::Tuple{Millisecond, Int64}
    hit = 0
    t0 = now()
    for ri in 1:length(ray_vec)
        r = ray_vec[ri]
        for ti in 1:length(tri_vec)
            t = tri_vec[ti]
            check, _, _ = RayTracing.intersect(t, r)
            check && (hit += 1)
        end
    end
    t1 = now()
    return t1-t0, hit
end

# test intersection: set up
print("Generating Rays & Triangles\n")
tri_vec = make_tris(NUM_TRIANGLES)
ray_vec = make_rays(NUM_RAYS)

print("Running FAST tests...\n")
t, hit = run_p(tri_vec, ray_vec)
print("intersection test took: ", t, "\n")
print("number of intersections tested: ", RayTracing.num2str(NUM_RAYS * NUM_TRIANGLES), "\n")
print(round(hit / (NUM_RAYS * NUM_TRIANGLES) * 100, digits=3), "% of rays intersected\n")
print(round((NUM_RAYS * NUM_TRIANGLES) / t.value / 1_000, digits=3), " million intersections per second\n")

print("Running FAST MT tests...\n")
t, hit = run_p(tri_vec, ray_vec)
print("intersection test took: ", t, "\n")
print("number of intersections tested: ", RayTracing.num2str(NUM_RAYS * NUM_TRIANGLES), "\n")
print(round(hit / (NUM_RAYS * NUM_TRIANGLES) * 100, digits=3), "% of rays intersected\n")
print(round((NUM_RAYS * NUM_TRIANGLES) / t.value / 1_000, digits=3), " million intersections per second\n")

print("\n")
print("Running SLOW tests...\n")
t, hit = run(tri_vec, ray_vec)
print("intersection test took: ", t, "\n")
print("number of intersections tested: ", RayTracing.num2str(NUM_RAYS * NUM_TRIANGLES), "\n")
print(round(hit / (NUM_RAYS * NUM_TRIANGLES) * 100, digits=3), "% of rays intersected\n")
print(round((NUM_RAYS * NUM_TRIANGLES) / t.value / 1_000, digits=3), " million intersections per second\n")


"""
Generating Rays & Triangles
Running FAST tests...
intersection test took: 4 milliseconds
number of intersections tested: 100,000
8.702% of rays intersected
25.0 million intersections per second

Running SLOW tests...
intersection test took: 5 milliseconds
number of intersections tested: 100,000
8.702% of rays intersected
20.0 million intersections per second
"""

"""
Generating Rays & Triangles
Running FAST tests...
intersection test took: 43 milliseconds
number of intersections tested: 1,000,000
8.615% of rays intersected
23.256 million intersections per second

Running SLOW tests...
intersection test took: 64 milliseconds
number of intersections tested: 1,000,000
8.615% of rays intersected
15.625 million intersections per second
"""

"""
Generating Rays & Triangles
Running FAST tests...
intersection test took: 854 milliseconds
number of intersections tested: 10,000,000
9.512% of rays intersected
11.71 million intersections per second

Running SLOW tests...
intersection test took: 1220 milliseconds
number of intersections tested: 10,000,000
9.512% of rays intersected
8.197 million intersections per second
"""

"""
Generating Rays & Triangles
Running FAST tests...
intersection test took: 9555 milliseconds
number of intersections tested: 100,000,000
8.912% of rays intersected
10.466 million intersections per second

Running SLOW tests...
intersection test took: 13726 milliseconds
number of intersections tested: 100,000,000
8.912% of rays intersected
7.285 million intersections per second
"""