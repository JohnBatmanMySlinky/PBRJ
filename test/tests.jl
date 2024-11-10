include("../src/RayTracing.jl")

using Test
using BenchmarkTools
using Random

# @testset "Transformations" begin
#     # simple (translate), (inverse translate), (identity A), (identity B)
#     t = RayTracing.Translate(RayTracing.Pnt3(1,2,3))
#     invt = RayTracing.Inv(t)
#     @test t(RayTracing.Pnt3(1,2,3)) ≈ RayTracing.Pnt3(2,4,6) 
#     @test invt(RayTracing.Pnt3(1,2,3)) ≈ RayTracing.Pnt3(0, 0, 0) 
#     @test invt(t(RayTracing.Pnt3(1,2,3))) ≈ RayTracing.Pnt3(1,2,3)
#     @test t(invt(RayTracing.Pnt3(1,2,3))) ≈ RayTracing.Pnt3(1,2,3)

#     # compound translate
#     t1 = RayTracing.Translate(RayTracing.Pnt3(1,1,1))
#     t2 = RayTracing.Translate(RayTracing.Pnt3(2,-1,2))
#     t = t1 * t2
#     @test  t(RayTracing.Pnt3(1,1,1)) ≈ RayTracing.Pnt3(4,1,4) 
#     invt = RayTracing.Inv(t)
#     @test  invt(t(RayTracing.Pnt3(1,1,1))) ≈ RayTracing.Pnt3(1,1,1) 

#     # simple rotateX
#     r = RayTracing.RotateX(90.0)
#     @test r(RayTracing.Pnt3(1,1,1)) ≈ RayTracing.Pnt3(1,-1,1)
#     invr = RayTracing.Inv(r)
#     @test  invr(r(RayTracing.Pnt3(1,1,1))) ≈ RayTracing.Pnt3(1,1,1) 

#     # simple rotateY
#     r = RayTracing.RotateY(90.0)
#     @test r(RayTracing.Pnt3(1,1,1)) ≈ RayTracing.Pnt3(1,1,-1)
#     invr = RayTracing.Inv(r)
#     @test  invr(r(RayTracing.Pnt3(1,1,1))) ≈ RayTracing.Pnt3(1,1,1) 

#     # compound rotate
#     r1 = RayTracing.RotateY(90.0)
#     r2 = RayTracing.RotateX(90.0) 
#     r3 = RayTracing.RotateZ(-90.0) 
#     r = r1 * r2 * r3
#     @test r(RayTracing.Pnt3(1,1,1)) ≈ RayTracing.Pnt3(-1,-1,-1)
#     invr = RayTracing.Inv(r)
#     @test  invr(r(RayTracing.Pnt3(1,1,1))) ≈ RayTracing.Pnt3(1,1,1) 
# end

# @testset "Robust Triangle Intersection & normals" begin
#     N1 = 5
#     rectmin, rectmax = -10, 10
#     trisize = 5

#     # make a bunch of triangles to ensure we hit every branch of `intrersect(tri, ray)`
#     core = RayTracing.ShapeCore()

#     # variety 1 of normals
#     ### No normals specified
#     tri1 = RayTracing.Triangle(
#         core,
#         RayTracing.TriangleMesh(
#             core.object_to_world,
#             1,
#             3,
#             [RayTracing.Pnt3(0.0, 0.0, -trisize), RayTracing.Pnt3(0.0, trisize, trisize), RayTracing.Pnt3(0.0, 0.0, trisize)],
#             [1, 2, 3],
#             [RayTracing.Nml3(0), RayTracing.Nml3(0), RayTracing.Nml3(0)],
#             [RayTracing.Pnt2(0,0), RayTracing.Pnt2(1,1), RayTracing.Pnt2(0,1)],
#             nothing
#         ),
#         0
#     ) 
#     # variety 2 of normals
#     ### Normals specified
#     tri2 = RayTracing.Triangle(
#         core,
#         RayTracing.TriangleMesh(
#             core.object_to_world,
#             1,
#             3,
#             [RayTracing.Pnt3(0.0, 0.0, -trisize), RayTracing.Pnt3(0.0, trisize, trisize), RayTracing.Pnt3(0.0, 0.0, trisize)],
#             [1, 2, 3],
#             [RayTracing.Nml3(0, 0, 1), RayTracing.Nml3(0, 0, 1), RayTracing.Nml3(0, 0, 1)],
#             [RayTracing.Pnt2(0,0), RayTracing.Pnt2(1,1), RayTracing.Pnt2(0,1)],
#             nothing
#         ),
#         0
#     ) 
#     # variety 3 of normals
#     ### Normals * -1 specified
#     tri3 = RayTracing.Triangle(
#         core,
#         RayTracing.TriangleMesh(
#             core.object_to_world,
#             1,
#             3,
#             [RayTracing.Pnt3(0.0, 0.0, -trisize), RayTracing.Pnt3(0.0, trisize, trisize), RayTracing.Pnt3(0.0, 0.0, trisize)],
#             [1, 2, 3],
#             [RayTracing.Nml3(0, 0, -1), RayTracing.Nml3(0, 0, -1), RayTracing.Nml3(0, 0, -1)],
#             [RayTracing.Pnt2(0,0), RayTracing.Pnt2(1,1), RayTracing.Pnt2(0,1)],
#             nothing
#         ),
#         0
#     ) 
#     # variety 4 of normals
#     ### Normals specified, reverse orientation tho
#     core2 = RayTracing.ShapeCore(RayTracing.Translate(RayTracing.Pnt3(0)), RayTracing.Inv(RayTracing.Translate(RayTracing.Pnt3(0))), true, false)
#     tri4 = RayTracing.Triangle(
#         core2,
#         RayTracing.TriangleMesh(
#             core2.object_to_world,
#             1,
#             3,
#             [RayTracing.Pnt3(0.0, 0.0, -trisize), RayTracing.Pnt3(0.0, trisize, trisize), RayTracing.Pnt3(0.0, 0.0, trisize)],
#             [1, 2, 3],
#             [RayTracing.Nml3(0, 0, -1), RayTracing.Nml3(0, 0, -1), RayTracing.Nml3(0, 0, -1)],
#             [RayTracing.Pnt2(0,0), RayTracing.Pnt2(1,1), RayTracing.Pnt2(0,1)],
#             nothing
#         ),
#         0
#     ) 
#     # tri5 = Triangle() # alpha mask
#     tris = (tri1, tri2, tri3, tri4)

#     # Low Hanging Fruit
#     ### sample a random point on the XZ plane, sample a random point on the triangle
#     ### build a ray, intersect. N1 times.
#     for i in 1:N1 
#         # 4 randoms for sampling
#         Random.seed!(9)
#         u1, u2, u3, u4 = rand(), rand(), rand(), rand()
        
#         # rect coord
#         rectx = u1 * (rectmax - rectmin) + rectmin
#         rectz = u2 * (rectmax - rectmin) + rectmin
#         from = RayTracing.Pnt3(rectx, 0, rectz)
        
#         # tri coord
#         for tri in tris
#             # create ray & intersect
#             to, n = RayTracing.sample(tri, RayTracing.Pnt2(u3, u4))
#             ray = RayTracing.Ray(from, RayTracing.normalize(RayTracing.Vec3(to - from)), 0.0, typemax(Float64))
#             check, t, inter = RayTracing.intersect(tri, ray)
            
#             # test intersection precision
#             @test isapprox(inter.core.p, to, atol=1e-14)

#             # calculate flip for normals
#             flip = tri.core.reverse_orientation ? -1.0 : 1.0

#             # testing geometric normals
#             @test inter.core.n == RayTracing.Nml3(1, 0, 0) * flip

#             # testing shading normals
#             # if we have normals
#             if sum(sum(tri.mesh.normals)) == 0.0
#                 # if no normals are specified we end up here
#                 n = RayTracing.Nml3(1, 0, 0) * flip
#             else
#                 # if normals are specified we need to check where we're coming from
#                 # THIS SEEMS LIKE IT SHOULD BE SWAPPED: FUCK
#                 if tri.mesh.normals[1].z == -1.0
#                     # 'forward' facing specified normals
#                     tmpdir = rectz < 0 ? -1.0 : 1.0
#                 else
#                     # 'backward' facing specified normals
#                     tmpdir = rectz < 0 ? 1.0 : -1.0
#                 end
#                 n = RayTracing.Nml3(0, 0, 1) * tmpdir * flip
#             end
#             @test inter.shading.n == n
#         end
#     end
# end

# @testset "Distributions1D --> continuous sampling" begin
#     # tests stolein from PBRT :)
#     x = Float64[1.0, 1.0, 2.0, 4.0, 8.0]
#     d = RayTracing.Distribution1D(x)

#     # test 1: u=0.0, lower bound
#     val, val_pdf, val_offset = RayTracing.sample_continuous(d, 0.0)
#     @test val ≈ 0.0
#     @test val_pdf ≈ length(x) / 16.0
#     @test val_offset ≈ 1

#     # test 2: u=0.5, on the cut point
#     val, val_pdf, val_offset = RayTracing.sample_continuous(d, 0.5)
#     @test val ≈ 0.8    

#     # test 3: u = .75, middle of section
#     val, val_pdf, val_offset = RayTracing.sample_continuous(d, 0.75)
#     @test val ≈ 0.9
#     @test val_pdf ≈ length(x) * 8.0 / 16.0
#     @test val_offset ≈ 5

#     # test 4: u = 1.0, upper bound
#     val, val_pdf, val_offset = RayTracing.sample_continuous(d, 1.0)
#     @test val ≈ 1.0
# end

# @testset "Distributions1D --> discrete sampling" begin
#     # tests stolein from PBRT :)
#     x = Float64[0.0, 1.0, 0.0, 3.0]
#     d = RayTracing.Distribution1D(x)

#     @test 0.00 ≈ RayTracing.discrete_pdf(d, 1)
#     @test 0.25 ≈ RayTracing.discrete_pdf(d, 2)
#     @test 0.00 ≈ RayTracing.discrete_pdf(d, 3)
#     @test 0.75 ≈ RayTracing.discrete_pdf(d, 4)

#     val, val_pdf, val_offset = RayTracing.sample_discrete(d, 0.0)
#     @test val ≈ 2
#     @test val_pdf ≈ 0.25
#     val, val_pdf, val_offset = RayTracing.sample_discrete(d, 0.125)
#     @test val ≈ 2
#     @test val_pdf ≈ 0.25
#     @test val_offset ≈ 0.5
#     val, val_pdf, val_offset = RayTracing.sample_discrete(d, 0.24999)
#     @test val ≈ 2
#     @test val_pdf ≈ 0.25
#     val, val_pdf, val_offset = RayTracing.sample_discrete(d, 0.250001)
#     @test val ≈ 4
#     @test val_pdf ≈ 0.75
#     val, val_pdf, val_offset = RayTracing.sample_discrete(d, 0.625)
#     @test val ≈ 4
#     @test val_pdf ≈ 0.75
#     @test val_offset ≈ 0.5
#     val, val_pdf, val_offset = RayTracing.sample_discrete(d, 1-eps(Float64))
#     @test val ≈ 4
#     @test val_pdf ≈ 0.75
#     val, val_pdf, val_offset = RayTracing.sample_discrete(d, 1.0)
#     @test val ≈ 4
#     @test val_pdf ≈ 0.75
# end

# @testset "LightDistribution --> centroid_distance distribution" begin
#     # Case 1: Four point lights equally far away fom p
#     mat1 = RayTracing.Matte(
#         RayTracing.ConstantTexture(RayTracing.Vec3(.4, .4, .4)),
#         RayTracing.ConstantTexture(RayTracing.Vec3(0, 0, 0)),
#         nothing
#     )
#     ball1 = RayTracing.Sphere(
#         RayTracing.ShapeCore(RayTracing.Translate(RayTracing.Pnt3(0)), RayTracing.Inv(RayTracing.Translate(RayTracing.Pnt3(0))), false, false),
#         5.0
#     )
#     bvh = RayTracing.BVH(RayTracing.Primitive[
#         RayTracing.Primitive(ball1, mat1, nothing),
#     ])
#     lights = RayTracing.Light[
#         RayTracing.PointLight(RayTracing.Translate(RayTracing.Pnt3(0, 10,0)), RayTracing.spectrum_from_float(10.0, 10.0, 10.0)),
#         RayTracing.PointLight(RayTracing.Translate(RayTracing.Pnt3(10, 0,0)), RayTracing.spectrum_from_float(10.0, 10.0, 10.0)),
#         RayTracing.PointLight(RayTracing.Translate(RayTracing.Pnt3(-10, 0,0)), RayTracing.spectrum_from_float(10.0, 10.0, 10.0)),
#         RayTracing.PointLight(RayTracing.Translate(RayTracing.Pnt3(0, -10,0)), RayTracing.spectrum_from_float(10.0, 10.0, 10.0)),
#     ]
#     fake_scene = RayTracing.Scene(lights, bvh)
#     ld_generator = RayTracing.LightDistribution("centroid_distance", fake_scene)
#     ld = RayTracing.lookup(ld_generator, RayTracing.Pnt3(0,0,0))
#     @test ld.cdf ≈ [0.0, 0.25, 0.5, 0.75, 1.0]

#     val, val_pdf, val_offset = RayTracing.sample_discrete(ld, 1.0)
#     @test val ≈ 4
#     @test val_pdf ≈ 0.25

#     val, val_pdf, val_offset = RayTracing.sample_discrete(ld, 0.1)
#     @test val ≈ 1
#     @test val_pdf ≈ 0.25

#     # Case 2: Four point lights NOT equally far away fom p
#     a, b, c, d = 10, 20, 40, 80
#     lights = RayTracing.Light[
#         RayTracing.PointLight(RayTracing.Translate(RayTracing.Pnt3(0, a, 0)), RayTracing.spectrum_from_float(10.0, 10.0, 10.0)),
#         RayTracing.PointLight(RayTracing.Translate(RayTracing.Pnt3(0, b, 0)), RayTracing.spectrum_from_float(10.0, 10.0, 10.0)),
#         RayTracing.PointLight(RayTracing.Translate(RayTracing.Pnt3(0, c, 0)), RayTracing.spectrum_from_float(10.0, 10.0, 10.0)),
#         RayTracing.PointLight(RayTracing.Translate(RayTracing.Pnt3(0, d, 0)), RayTracing.spectrum_from_float(10.0, 10.0, 10.0)),
#     ]
#     fake_scene = RayTracing.Scene(lights, bvh)
#     ld_generator = RayTracing.LightDistribution("centroid_distance", fake_scene)
#     ld = RayTracing.lookup(ld_generator, RayTracing.Pnt3(0,0,0))

#     norm = 1/a^2 + 1/b^2 + 1/c^2 + 1/d^2
#     @test ld.cdf ≈ [0.0, (1/a^2)/norm, (1/a^2)/norm + (1/b^2)/norm, (1/a^2)/norm + (1/b^2)/norm + (1/c^2)/norm, 1.0]

#     val, val_pdf, val_offset = RayTracing.sample_discrete(ld, 0.5)
#     @test val ≈ 1
#     @test val_pdf ≈ (1/a^2)/norm
# end

# @testset "Distributions2 --> discrete sampling" begin
#     x = reshape([
#         [4.0, 5.0, 4.0, 3.0, 3.0, 4.0, 1.0]
#         [3.0, 1.0, 7.0, 6.0, 3.0, 5.0, 2.0]
#         [1.0, 7.0, 7.0, 7.0, 4.0, 7.0, 1.0]
#         [0.0, 8.0, 9.0, 13.0, 9.0, 7.0, 1.0]
#         [5.0, 7.0, 10.0, 13.0, 9.0, 5.0, 0.0]
#         [0.0, 5.0, 12.0, 15.0, 15.0, 9.0, 1.0]
#         [1.0, 7.0, 12.0, 15.0, 11.0, 4.0, 2.0]
#         [1.0, 4.0, 7.0, 9.0, 6.0, 7.0, 4.0]
#         [0.0, 5.0, 5.0, 11.0, 8.0, 5.0, 1.0]
#         [4.0, 2.0, 6.0, 4.0, 2.0, 5.0, 4.0]
#         [4.0, 3.0, 5.0, 3.0, 3.0, 0.0, 5.0]
#     ], 7, 11)
#     d = RayTracing.Distribution2D(x)
#     uv, pdf_val = RayTracing.sample_continuous(d, RayTracing.Pnt2(0.5, 0.5))
# end

# # @testset "Infinite Area Light" begin
# #     mi = 0
# #     ma = 10
# #     env_light = RayTracing.InfiniteLight(
# #         RayTracing.Bounds3(RayTracing.Pnt3(mi), RayTracing.Pnt3(ma)), 
# #         RayTracing.RotateX(0.0), 
# #         RayTracing.spectrum_from_float(1.0), 
# #         "../ref/sky.exr"
# #     )
# #     #########################
# #     ### test: world sphere ###
# #     #########################

# #     # test world_sphere
# #     @test env_light.world_center ≈ RayTracing.Pnt3((mi+ma)/2)
# #     @test env_light.world_radius ≈ sqrt(3 * ((ma-mi)/2)^2)

# #     ######################
# #     ### test: sampling ###
# #     ######################

# #     # lets get the brightest pixel manually
# #     height, width = size(env_light.Lmap)
# #     _, max_coords = findmax(Float64.(RayTracing.Gray.(env_light.map)))

# #     known_u = max_coords[2]/width
# #     known_v = max_coords[1]/height
# #     @test known_u ≈ 0.25
# #     @test known_v ≈ 0.27783203125
    
# #     # and test we can recover it
# #     known_u_idx = RayTracing._uv_map(known_u, width)
# #     known_v_idx = RayTracing._uv_map(known_v, height)
# #     tmp = env_light.map[known_v_idx, known_u_idx]
# #     @test RayTracing.spectrum_from_float(Float64(tmp.r), Float64(tmp.g), Float64(tmp.b)) ≈ RayTracing.spectrum_from_float(19008.0, 20320.0, 19680.0)


# #     # now let's test the sampling and pdf functions
# #     inter = RayTracing.Interaction(
# #         RayTracing.Pnt3(1,1,1),
# #         0.5,
# #         RayTracing.Vec3(1,1,1),
# #         RayTracing.Nml3(0,1,0)
# #     )
# #     # when we sample li with 0.5, 0.5 we should get our brightest pixel
# #     sampled_li, wi, pdf_from_sample_li, vis, _, _ = RayTracing.sample_li(env_light, inter, RayTracing.Pnt2(0.5, 0.5))
# #     @test sampled_li ≈ RayTracing.spectrum_from_float(19008.0, 20320.0, 19680.0)

# #     # uv should be recoverable from sampling the distribution
# #     sampled_uv, pdf_from_sample_continuous = RayTracing.sample_continuous(env_light.pdf, RayTracing.Pnt2(0.5, 0.5))
# #     @test isapprox(sampled_uv.x, known_u, rtol=3)
# #     @test isapprox(sampled_uv.y, known_v, rtol=3)
    
# #     # pdf should be recoverable no matter how we sampled
# #     pdf_adj_factor = 1.0/(2*pi*pi*RayTracing.sin(sampled_uv.y * pi))
# #     @test pdf_from_sample_continuous * pdf_adj_factor ≈ pdf_from_sample_li

# #     # more pdf recoverability testing
# #     pdf_from_pdf_li = RayTracing.pdf_li(env_light, RayTracing.empty_surface_interation(), wi)
# #     @test pdf_from_pdf_li ≈ pdf_from_sample_li

# #     # for infinite light, sample_li and sample_le are very similar barring a sign on wi
# #     sampled_le, ray, _, _, pdf_from_sample_le = RayTracing.sample_le(env_light, RayTracing.Pnt2(0.5, 0.5), RayTracing.Pnt2(0.5, 0.5), 0.5)
# #     @test sampled_le ≈ sampled_li
# #     @test ray.direction ≈ -wi
# #     @test pdf_from_sample_le ≈ pdf_from_sample_li
# # end


# @testset "samplers v2" begin
#     @test stratum = RayTracing.permutation_element(UInt32(0), UInt32(36), 400) == 26
#     @test stratum = RayTracing.permutation_element(UInt32(0), UInt32(36), 4032212079371261838) == 15
#     @test stratum = RayTracing.permutation_element(UInt32(5), UInt32(36), 4032212079371261838) == 10
#     @test stratum = RayTracing.permutation_element(UInt32(50), UInt32(99), 0xf8d73f61d81b95bb) == 98
#     @test stratum = RayTracing.permutation_element(UInt32(5000), UInt32(990000), 0xcfc42f87b1d87f0e) == 221513
#     @test stratum = RayTracing.permutation_element(UInt32(3), UInt32(990000), 400) == 245588
# end


# @testset "Fresnel Dielectric" begin
#     # Vacuum gives no reflectance.
#     @test isapprox(RayTracing.fresnel_dielectric(1.0, 1.0, 1.0), 0.0, rtol=4)
#     @test isapprox(RayTracing.fresnel_dielectric(0.5, 1.0, 1.0), 0.0, rtol=4)
# end

# @testset "Fresnel Conductor" begin
#     s = RayTracing.spectrum_from_float(1.0)
#     @test RayTracing.fresnel_conductor(0.0, s, s, s) == s
#     @test all(RayTracing.fresnel_conductor(cos(π / 4.0), s, s, s) .> 0.0)
#     @test all(RayTracing.fresnel_conductor(1.0, s, s, s) .> 0.0)
# end

# @testset "SpecularReflection" begin
#     sr = RayTracing.SpecularReflection(RayTracing.spectrum_from_float(1.0), RayTracing.FresnelNoOp())
#     @test sr & (RayTracing.BSDF_SPECULAR | RayTracing.BSDF_REFLECTION)
# end

# # @testset "SpecularTransmission" begin
# #     st = RayTracing.SpecularTransmission(
# #         RayTracing.spectrum_from_float(1.0), 1.0, 1.0,
# #         RayTracing.Radiance,
# #     )
# #     @test st & (RayTracing.BSDF_SPECULAR | RayTracing.BSDF_TRANSMISSION)
# # end

# @testset "FresnelSpecular" begin
#     f = RayTracing.FresnelSpecular(
#         RayTracing.spectrum_from_float(1.0), RayTracing.spectrum_from_float(1.0),
#         1.0, 1.0, RayTracing.Radiance,
#     )
#     @test f & (RayTracing.BSDF_SPECULAR | RayTracing.BSDF_REFLECTION | RayTracing.BSDF_TRANSMISSION)

#     wo = RayTracing.Vec3(0, 0, 1)
#     u = RayTracing.Pnt2(0, 0)
#     wi, bxdf_value, pdf,  sampled_type = RayTracing.sample_f(f, wo, u)
#     @test wi ≈ -wo
#     @test pdf ≈ 1.0
#     @test sampled_type == RayTracing.BSDF_SPECULAR | RayTracing.BSDF_TRANSMISSION
# end

# # @testset "MicrofacetReflection" begin
# #     m = RayTracing.MicrofacetReflection(
# #         RayTracing.spectrum_from_float(1.0),
# #         RayTracing.TrowbridgeReitzDistribution(1.0, 1.0),
# #         RayTracing.FresnelNoOp(),
# #         # RayTracing.Radiance,
# #     )
# #     @test m & (RayTracing.BSDF_REFLECTION | RayTracing.BSDF_GLOSSY)
# #     wo = RayTracing.Vec3(0, 0, 1)
# #     u = RayTracing.Pnt2(0, 0)
# #     wi, pdf, bxdf_value, sampled_type = RayTracing.sample_f(m, wo, u)
# #     @test wi ≈ RayTracing.Vec3(0, 0, 1)
# # end

# # @testset "MicrofacetTransmission" begin
# #     m = RayTracing.MicrofacetTransmission(
# #         RayTracing.spectrum_from_float(1.0),
# #         RayTracing.TrowbridgeReitzDistribution(1.0, 1.0),
# #         1.0, 2.0,
# #         RayTracing.Radiance,
# #     )
# #     @test m & (RayTracing.BSDF_TRANSMISSION | RayTracing.BSDF_GLOSSY)
# #     wo = RayTracing.Vec3(0, 0, 1)
# #     u = RayTracing.Pnt2(0, 0)
# #     wi, pdf, bxdf_value, sampled_type = RayTracing.sample_f(m, wo, u)
# #     @test wi ≈ RayTracing.Vec3(0, 0, -1)
# # end

# @testset "PermutationElement - Unit Tests" begin
#     @test RayTracing.permutation_element(UInt32(0), UInt32(36), 400) == 26
#     @test RayTracing.permutation_element(UInt32(0), UInt32(36), 4032212079371261838) == 15
#     @test RayTracing.permutation_element(UInt32(5), UInt32(36), 4032212079371261838) == 10
#     @test RayTracing.permutation_element(UInt32(50), UInt32(99), 0xf8d73f61d81b95bb) == 98
#     @test RayTracing.permutation_element(UInt32(5000), UInt32(990000), 0xcfc42f87b1d87f0e) == 221513
#     @test RayTracing.permutation_element(UInt32(3), UInt32(990000), 400) == 245588
# end

# # taken from pbrt
# @testset "Permutation Element - Valid" begin
#     for len in 2:1024
#         for iter in 0:10
#             seen = falses(len)
#             for i in 0:(len-1)
#                 offset = RayTracing.permutation_element(UInt32(i), UInt32(len), RayTracing.mix_bits(1+iter))
#                 @test (offset >= 0) && (offset < len)
#                 @test seen[offset+1] == 0
#                 seen[offset+1] = 1
#             end
#         end
#     end
# end

# # taken from pbrt
# @testset "Permutation Element - Uniform" begin
#     for n in (2, 3, 4, 5, 9, 14, 16, 22, 27, 36)
#         cnt = zeros(n*n)
    
#         num_iters = 60_000 * n
#         for seed in 0:(num_iters-1)
#             for i in 0:(n-1)
#                 ip = RayTracing.permutation_element(UInt32(i), UInt32(n), RayTracing.mix_bits(seed))
#                 offset = ip * n + i
#                 cnt[offset+1] += 1
#             end
#         end
    
#         for i in 0:(n-1)
#             for j in 0:(n-1)
#                 tol = 0.03
#                 offset = j * n + i
#                 @test (cnt[offset+1] >= (1-tol) * num_iters / n) && (cnt[offset+1] <= (1+tol) * num_iters / n)
#             end
#         end
#     end
# end

# # taken from pbrt
# @testset "Permutation Element - Delta Uniform" begin
#     for n in (2, 3, 4, 5, 9, 14, 16, 22, 27, 36)
#         cnt = zeros(n*n)
    
#         num_iters = 60_000 * n
#         for seed in 0:(num_iters-1)
#             for i in 0:(n-1)
#                 ip = RayTracing.permutation_element(UInt32(i), UInt32(n), RayTracing.mix_bits(seed))
#                 delta = ip-i
#                 if delta < 0
#                     delta += n
#                 end
#                 offset = delta * n + i
#                 cnt[offset+1] += 1
#             end
#         end
    
#         for i in 0:(n-1)
#             for j in 0:(n-1)
#                 tol = 0.03
#                 offset = j * n + i
#                 @test (cnt[offset+1] >= (1-tol) * num_iters / n) && (cnt[offset+1] <= (1+tol) * num_iters / n)
#             end
#         end
#     end
# end

# @testset "Low Discrepancy Stuff - radical_inverse" begin
#     # manually verified!
#     @test isapprox(RayTracing.radical_inverse(0, UInt64(500)), 0.185547, atol=1e-5)
#     @test isapprox(RayTracing.radical_inverse(16, UInt64(500)), 0.476874, atol=1e-5)
#     @test isapprox(RayTracing.radical_inverse(9, UInt64(12345678)), 0.0608663, atol=1e-5)
#     @test isapprox(RayTracing.radical_inverse(8, UInt64(8)), 0.347826, atol=1e-5)
#     @test isapprox(RayTracing.radical_inverse(5, UInt64(1)), 0.0769231, atol=1e-5)
# end

# @testset "Low Discrepancy Stuff - sobol_interval_to_index" begin
#     # manually verified
#     @test RayTracing.sobol_interval_to_index(UInt32(5), UInt64(6), RayTracing.Pnt2(7, 8)) == 6524
#     @test RayTracing.sobol_interval_to_index(UInt32(8), UInt64(7), RayTracing.Pnt2(0, 0)) == 460544
#     @test RayTracing.sobol_interval_to_index(UInt32(25), UInt64(0), RayTracing.Pnt2(36, 36)) == 20100753653760
# end

# @testset "Low Discrepancy Stuff - reverse_bits_32" begin
#     # manually verified
#     @test RayTracing.reverse_bits_32(UInt32(8)) == 268435456
#     @test RayTracing.reverse_bits_32(UInt32(1944)) == 434110464
# end

# # Testing no allocations!
# # This is cool!
# @testset "Testing none of these functions produce allocations" begin
#     #####################
#     ### rand_utils.jl ###
#     #####################
#     @test @ballocated(RayTracing.random_in_concentric_disk(RayTracing.Pnt2(0.5, 0.5))) == 0
#     @test @ballocated(RayTracing.random_in_cosine_hemisphere(RayTracing.Pnt2(0.48, 0.92))) == 0
#     @test @ballocated(RayTracing.random_on_sphere(RayTracing.Pnt2(0.233, 0.45367))) == 0
#     @test @ballocated(RayTracing.cosine_sample_hemisphere(RayTracing.Pnt2(0.44, 0.656))) == 0
#     @test @ballocated(RayTracing.uniform_sample_cone(RayTracing.Pnt2(0.11, 0.456), 0.27)) == 0
#     @test @ballocated(RayTracing.cosine_hemisphere_pdf(0.45)) == 0
#     @test @ballocated(RayTracing.uniform_cone_pdf(0.568)) == 0
#     @test @ballocated(RayTracing.sample_linear(0.568, 0.2, 0.8)) == 0
#     @test @ballocated(RayTracing.sample_bilinear(
#         RayTracing.Pnt2(0.34, 0.56),
#         RayTracing.Vec4(.2, .4, .6, .8)
#     )) == 0
#     @test @ballocated(RayTracing.bilinear_pdf(
#         RayTracing.Pnt2(0.34, 0.56),
#         RayTracing.Vec4(.2, .4, .6, .8)
#     )) == 0
#     @test @ballocated(RayTracing.bilinear_pdf(
#         RayTracing.Pnt2(0.34, 0.56),
#         RayTracing.Vec4(.2, .4, .6, .8)
#     )) == 0
#     @test @ballocated(RayTracing.sample_spherical_triangle(
#         RayTracing.Pnt3(5, 5, 5),
#         RayTracing.Pnt3(-5, -5, -5),
#         RayTracing.Pnt3(-3, 3, 4),
#         RayTracing.Pnt3(0, 0, 0),
#         RayTracing.Pnt2(0.4, 0.6),
#     )) == 0

#     #####################
#     ### math_utils.jl ###
#     #####################
#     @test @ballocated(RayTracing.safe_sqrt(-.05)) == 0

#     # do this one twice
#     @test @ballocated(RayTracing.solve_quadratic(3.0, 4.0, 5.0)) == 0
#     @test @ballocated(RayTracing.solve_quadratic(3.0, 4.0, 10.0)) == 0

#     @test @ballocated(RayTracing.distance(
#         RayTracing.Pnt3(1.0, 2.0, 3.0),
#         RayTracing.Pnt3(11.0, 21.0, 31.0),
#     )) == 0
#     @test @ballocated(RayTracing.distance_squared(
#         RayTracing.Pnt3(1.0, 2.0, 3.0),
#         RayTracing.Pnt3(11.0, 21.0, 31.0),
#     )) == 0
#     @test @ballocated(RayTracing.length_squared(RayTracing.Vec3(1.0, 2.0, 3.0))) == 0
#     @test @ballocated(RayTracing.length_pbrt(RayTracing.Vec3(1.0, 2.0, 3.0))) == 0
#     @test @ballocated(RayTracing.angle_between(
#         RayTracing.Vec3(1.0, 2.0, 3.0),
#         RayTracing.Vec3(11.0, 21.0, 31.0),
#     )) == 0
#     @test @ballocated(RayTracing.safe_asin(-.05)) == 0
#     @test @ballocated(RayTracing.difference_of_products(-.05, .2, -.5, 1.0)) == 0
#     @test @ballocated(RayTracing.sum_of_products(-.05, .2, -.5, 1.0)) == 0
#     @test @ballocated(RayTracing.gram_schmidt(
#         RayTracing.Vec3(1.0, 2.0, 3.0),
#         RayTracing.Vec3(11.0, 21.0, 31.0),
#     )) == 0
#     @test @ballocated(RayTracing.spherical_phi(RayTracing.Vec3(.1, .2, .3))) == 0
#     @test @ballocated(RayTracing.spherical_theta(RayTracing.Vec3(.4, .5, .6))) == 0
#     @test @ballocated(RayTracing.spherical_direction(
#         2.5,
#         3.5,
#         4.5,
#         RayTracing.Vec3(1, 2, 3),
#         RayTracing.Vec3(4, 5, 6),
#         RayTracing.Vec3(7, 8, 9),
#     )) == 0
#     @test @ballocated(RayTracing.orthonormal_basis(RayTracing.Vec3(.4, .5, .6))) == 0
#     @test @ballocated(RayTracing.orthonormal_basis(RayTracing.Nml3(.4, .5, .6))) == 0
#     @test @ballocated(RayTracing.orthonormal_basis(RayTracing.Nml3(.4, .5, .6))) == 0
#     @test @ballocated(RayTracing.same_hemisphere(RayTracing.Vec3(.4, .5, .6), RayTracing.Vec3(1, 2, 43))) == 0
#     @test @ballocated(RayTracing.power_heuristic(1.0, 3.0, 4.0, 9.0)) == 0
#     @test @ballocated(RayTracing.do_tile(1.0, 3.0)) == 0
#     @test @ballocated(RayTracing.multiplicative_inverse(1, 3)) == 0

#     ##########################
#     ### Transformations.jl ###
#     ##########################
#     # Transformation instantiatio
#     # @test @ballocated(RayTracing.Translate(RayTracing.Pnt3(1.0, 2.0, 3.0))) == 288
#     # @test @ballocated(RayTracing.Scale(RayTracing.Vec3(1.0, 2.0, 3.0))) == 288
#     # @test @ballocated(RayTracing.RotateX(45.0)) == 288
#     # @test @ballocated(RayTracing.RotateY(45.0)) == 288
#     # @test @ballocated(RayTracing.RotateZ(45.0)) == 288
#     # @test @ballocated(RayTracing.Perspective(45.0, .01, .0001)) == 1184
#     # @test @ballocated(RayTracing.LookAt(
#     #     RayTracing.Pnt3(0,0,0),
#     #     RayTracing.Pnt3(5,8,9),
#     #     RayTracing.Vec3(0,1,0),
#     # )) == 288

#     # # Transformation application
#     # t1 = RayTracing.Translate(RayTracing.Pnt3(1.0, 2.0, 3.0))
#     # t2 = RayTracing.Scale(RayTracing.Vec3(1.0, 2.0, 3.0))
#     # t3 = RayTracing.RotateX(45.0)

#     # p = RayTracing.Pnt3(10, 0.5, 3.0)
#     # v = RayTracing.Vec3()
# end

# function get_random_triangle(v_in::Vector{Float64})::Tuple{Bool, RayTracing.Maybe{RayTracing.Triangle}}
#     v = RayTracing.Pnt3[]
#     for i in 1:3
#         push!(v, RayTracing.Pnt3(v_in[(i-1)*3+1], v_in[(i-1)*3+2], v_in[(i-1)*3+3]))
#     end

#     if RayTracing.length_squared(RayTracing.Vec3(RayTracing.cross(v[2] - v[1], v[3] - v[1]))) < 1e-20
#         return false, nothing
#     end

#     mesh = RayTracing.construct_triangle_mesh(
#         RayTracing.ShapeCore(),
#         1,
#         3,
#         v,
#         Int64[1,2,3],
#         RayTracing.Nml3[RayTracing.Nml3(0), RayTracing.Nml3(0), RayTracing.Nml3(0)],
#         RayTracing.Pnt2[RayTracing.Pnt2(0,0), RayTracing.Pnt2(1,0), RayTracing.Pnt2(1,1)],
#     nothing
#     )
#     return true, mesh[1]
# end

# function p_unif(a::Int64)::Float64
#     return RayTracing.lerp(rand(), -Float64(a), Float64(a))
# end

# function error(a::Float64, b::Float64)::Float64
#     if (abs(a) < 1e-4) || (abs(b) < 1e-4)
#         return abs(a-b)
#     else
#         return abs((a-b)/b)
#     end
# end

# # Checks the closed-form solid angle computation for triangles against a
# # Monte Carlo estimate of it.
# # From PBRTv4
# @testset "Triangle - Solid Angle Sampling" begin
#     RayTracing.Random.seed!(123789)
#     for i in 1:50
#         range = 10
#         check, tri = get_random_triangle([p_unif(range) for _ in 1:9])
#         if !check
#             continue
#         end

#         # Ensure that the reference point isn't too close to the
#         # triangle's surface (which makes the Monte Carlo stuff have more
#         # variance, thus requiring more samples).
#         tmp = [p_unif(range), p_unif(range), p_unif(range)]
#         tmp[rand(1:3)] = rand() > 0.5 ? (-range - 3.0) : (range + 3.0)        
#         pc = RayTracing.Pnt3(tmp)

#         # Compute a reference value using Triangle::Sample()
#         count = 64 * 1_024
#         intr = RayTracing.Interaction(pc, 0.0, RayTracing.Vec3(0), RayTracing.Nml3(0))
#         tri_sample_estimate = 0
#         for j in 1:count
#             u = RayTracing.Pnt2(RayTracing.radical_inverse(0,UInt64(j)), RayTracing.radical_inverse(1, UInt64(j)))
#             ss_p, ss_n, ss_pdf = RayTracing.sample(tri, intr, u)
#             @assert ss_pdf > 0.0
#             tri_sample_estimate += 1.0 / (count * ss_pdf)
#         end

#         # now compute the subtended solid angle of the triangle in closed from
#         p0, p1, p2 = RayTracing.get_vertices(tri)
#         spherical_area = RayTracing.solid_angle(p0, p1, p2, pc)
#         @test error(spherical_area, tri_sample_estimate) < 0.15
#     end
# end
