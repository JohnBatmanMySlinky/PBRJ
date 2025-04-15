
using Test
using BenchmarkTools
using Random
using Base: DevNull

# UGH HACKY AND ANNOYING
function jmfp(fp::String)
	sys_apple = Sys.isapple()
	sys_linux = Sys.islinux()

	if !(sys_apple || sys_linux)
		print("get off windows\n")
		@assert false
	end
	
	fp_apple = occursin("Users", fp)
	fp_linux = occursin("home", fp)

	if !(fp_apple || fp_linux)
		print("bad input string\n")
		@assert false
	end
	

	if fp_apple && sys_linux
		fp = replace(fp, "Users" => "home")
		fp = replace(fp, "johnmyslinski" => "jmyslinski")
		fp = replace(fp, "Documents" => "random_stuff")
	elseif fp_linux && sys_apple
		fp = replace(fp, "home" => "Users")
		fp = replace(fp, "jmyslinski" => "johnmyslinski")
		fp = replace(fp, "random_stuff" => "Documents")
	end
	return fp
end

include(jmfp("/Users/johnmyslinski/Documents/PBRJ/src/RayTracing.jl"))

# # Testing no allocations!
# # This is cool!
const t1 = RayTracing.Translate(RayTracing.Pnt3(1.0, 2.0, 3.0))
const t2 = RayTracing.Scale(RayTracing.Vec3(1.0, 2.0, 3.0))
const t3 = RayTracing.RotateX(45.0)
const t4 = RayTracing.Perspective(45.0, .01, .0001)
const t5 = RayTracing.LookAt(
    RayTracing.Pnt3(0,0,0),
    RayTracing.Pnt3(5,8,9),
    RayTracing.Vec3(0,1,0),
)


const p = RayTracing.Pnt3(10, 0.5, 3.0)
const v = RayTracing.Vec3(10, 0.5, 3.0)
const n = RayTracing.Nml3(10, 0.5, 3.0)
const b = RayTracing.Bounds3(
    RayTracing.Pnt3(10, 0.5, 3.0),
    RayTracing.Pnt3(0, 0, 0)
)
const r = RayTracing.Ray(
    RayTracing.Pnt3(-1,-1,-1),
    RayTracing.Vec3(1,1,1),
    0.0,
    typemax(Float64)
)
@testset "Testing none of these functions produce allocations" begin
    #####################
    ### rand_utils.jl ###
    #####################
    @test @ballocated(RayTracing.random_in_concentric_disk(RayTracing.Pnt2(0.5, 0.5))) == 0
    @test @ballocated(RayTracing.random_in_cosine_hemisphere(RayTracing.Pnt2(0.48, 0.92))) == 0
    @test @ballocated(RayTracing.random_on_sphere(RayTracing.Pnt2(0.233, 0.45367))) == 0
    @test @ballocated(RayTracing.cosine_sample_hemisphere(RayTracing.Pnt2(0.44, 0.656))) == 0
    @test @ballocated(RayTracing.uniform_sample_cone(RayTracing.Pnt2(0.11, 0.456), 0.27)) == 0
    @test @ballocated(RayTracing.cosine_hemisphere_pdf(0.45)) == 0
    @test @ballocated(RayTracing.uniform_cone_pdf(0.568)) == 0
    @test @ballocated(RayTracing.sample_linear(0.568, 0.2, 0.8)) == 0
    @test @ballocated(RayTracing.sample_bilinear(
        RayTracing.Pnt2(0.34, 0.56),
        RayTracing.Vec4(.2, .4, .6, .8)
    )) == 0
    @test @ballocated(RayTracing.bilinear_pdf(
        RayTracing.Pnt2(0.34, 0.56),
        RayTracing.Vec4(.2, .4, .6, .8)
    )) == 0
    @test @ballocated(RayTracing.bilinear_pdf(
        RayTracing.Pnt2(0.34, 0.56),
        RayTracing.Vec4(.2, .4, .6, .8)
    )) == 0
    @test @ballocated(RayTracing.sample_spherical_triangle(
        RayTracing.Pnt3(5, 5, 5),
        RayTracing.Pnt3(-5, -5, -5),
        RayTracing.Pnt3(-3, 3, 4),
        RayTracing.Pnt3(0, 0, 0),
        RayTracing.Pnt2(0.4, 0.6),
    )) == 0

    #####################
    ### math_utils.jl ###
    #####################
    @test @ballocated(RayTracing.safe_sqrt(-.05)) == 0

    # do this one twice
    @test @ballocated(RayTracing.solve_quadratic(3.0, 4.0, 5.0)) == 0
    @test @ballocated(RayTracing.solve_quadratic(3.0, 4.0, 10.0)) == 0

    @test @ballocated(RayTracing.distance(
        RayTracing.Pnt3(1.0, 2.0, 3.0),
        RayTracing.Pnt3(11.0, 21.0, 31.0),
    )) == 0
    @test @ballocated(RayTracing.distance_squared(
        RayTracing.Pnt3(1.0, 2.0, 3.0),
        RayTracing.Pnt3(11.0, 21.0, 31.0),
    )) == 0
    @test @ballocated(RayTracing.length_squared(RayTracing.Vec3(1.0, 2.0, 3.0))) == 0
    @test @ballocated(RayTracing.length_pbrt(RayTracing.Vec3(1.0, 2.0, 3.0))) == 0
    @test @ballocated(RayTracing.angle_between(
        RayTracing.Vec3(1.0, 2.0, 3.0),
        RayTracing.Vec3(11.0, 21.0, 31.0),
    )) == 0
    @test @ballocated(RayTracing.safe_asin(-.05)) == 0
    @test @ballocated(RayTracing.difference_of_products(-.05, .2, -.5, 1.0)) == 0
    @test @ballocated(RayTracing.sum_of_products(-.05, .2, -.5, 1.0)) == 0
    @test @ballocated(RayTracing.gram_schmidt(
        RayTracing.Vec3(1.0, 2.0, 3.0),
        RayTracing.Vec3(11.0, 21.0, 31.0),
    )) == 0
    @test @ballocated(RayTracing.spherical_phi(RayTracing.Vec3(.1, .2, .3))) == 0
    @test @ballocated(RayTracing.spherical_theta(RayTracing.Vec3(.4, .5, .6))) == 0
    @test @ballocated(RayTracing.spherical_direction(
        2.5,
        3.5,
        4.5,
        RayTracing.Vec3(1, 2, 3),
        RayTracing.Vec3(4, 5, 6),
        RayTracing.Vec3(7, 8, 9),
    )) == 0
    @test @ballocated(RayTracing.orthonormal_basis(RayTracing.Vec3(.4, .5, .6))) == 0
    @test @ballocated(RayTracing.orthonormal_basis(RayTracing.Nml3(.4, .5, .6))) == 0
    @test @ballocated(RayTracing.orthonormal_basis(RayTracing.Nml3(.4, .5, .6))) == 0
    @test @ballocated(RayTracing.same_hemisphere(RayTracing.Vec3(.4, .5, .6), RayTracing.Vec3(1, 2, 43))) == 0
    @test @ballocated(RayTracing.power_heuristic(1.0, 3.0, 4.0, 9.0)) == 0
    @test @ballocated(RayTracing.do_tile(1.0, 3.0)) == 0
    @test @ballocated(RayTracing.multiplicative_inverse(1, 3)) == 0

    ##########################
    ### Transformations.jl ###
    ##########################
    @test @ballocated(RayTracing.Translate(RayTracing.Pnt3(1.0, 2.0, 3.0))) == 0
    @test @ballocated(RayTracing.Scale(RayTracing.Vec3(1.0, 2.0, 3.0))) == 0
    @test @ballocated(RayTracing.RotateX(45.0)) == 0
    @test @ballocated(RayTracing.RotateY(45.0)) == 0
    @test @ballocated(RayTracing.RotateZ(45.0)) == 0
    @test @ballocated(RayTracing.Perspective(45.0, .01, .0001)) == 0
    @test @ballocated(RayTracing.LookAt(
        RayTracing.Pnt3(0,0,0),
        RayTracing.Pnt3(5,8,9),
        RayTracing.Vec3(0,1,0),
    )) == 0

    @test @ballocated(t1(p)) == 0
    @test @ballocated(t2(p)) == 0
    @test @ballocated(t3(p)) == 0
    @test @ballocated(t4(p)) == 0
    @test @ballocated(t5(p)) == 0

    @test @ballocated(t1(v)) == 0
    @test @ballocated(t2(v)) == 0
    @test @ballocated(t3(v)) == 0
    @test @ballocated(t4(v)) == 0
    @test @ballocated(t5(v)) == 0

    @test @ballocated(t1(n)) == 0
    @test @ballocated(t2(n)) == 0
    @test @ballocated(t3(n)) == 0
    @test @ballocated(t4(n)) == 0
    @test @ballocated(t5(n)) == 0

    @test @ballocated(t1(b)) == 0
    @test @ballocated(t2(b)) == 0
    @test @ballocated(t3(b)) == 0
    @test @ballocated(t4(b)) == 0
    @test @ballocated(t5(b)) == 0

    ##########################
    ### Intersections.jl #####
    ##########################
    @test @ballocated(RayTracing.intersect_p(b, r)) == 0
    @test @ballocated(RayTracing.intersect_p(b, r, 1.0 ./ r.direction, RayTracing.is_dir_negative(r.direction))) == 0
end