include("../src/RayTracing.jl")

using Test

@testset "Transformations" begin
    # simple translate
    t = RayTracing.Translate(RayTracing.Pnt3(1,1,1))
    @test  t(RayTracing.Pnt3(1,1,1)) ≈ RayTracing.Pnt3(2,2,2) 
    invt = RayTracing.Inv(t)
    @test  invt(t(RayTracing.Pnt3(1,1,1))) ≈ RayTracing.Pnt3(1,1,1) 

    # compound translate
    t1 = RayTracing.Translate(RayTracing.Pnt3(1,1,1))
    t2 = RayTracing.Translate(RayTracing.Pnt3(2,-1,2))
    t = t1 * t2
    @test  t(RayTracing.Pnt3(1,1,1)) ≈ RayTracing.Pnt3(4,1,4) 
    invt = RayTracing.Inv(t)
    @test  invt(t(RayTracing.Pnt3(1,1,1))) ≈ RayTracing.Pnt3(1,1,1) 

    # simple rotateX
    r = RayTracing.RotateX(90.0)
    @test r(RayTracing.Pnt3(1,1,1)) ≈ RayTracing.Pnt3(1,-1,1)
    invr = RayTracing.Inv(r)
    @test  invr(r(RayTracing.Pnt3(1,1,1))) ≈ RayTracing.Pnt3(1,1,1) 

    # simple rotateY
    r = RayTracing.RotateY(90.0)
    @test r(RayTracing.Pnt3(1,1,1)) ≈ RayTracing.Pnt3(1,1,-1)
    invr = RayTracing.Inv(r)
    @test  invr(r(RayTracing.Pnt3(1,1,1))) ≈ RayTracing.Pnt3(1,1,1) 

    # compound rotate
    r1 = RayTracing.RotateY(90.0)
    r2 = RayTracing.RotateX(90.0) 
    r3 = RayTracing.RotateZ(-90.0) 
    r = r1 * r2 * r3
    @test r(RayTracing.Pnt3(1,1,1)) ≈ RayTracing.Pnt3(-1,-1,-1)
    invr = RayTracing.Inv(r)
    @test  invr(r(RayTracing.Pnt3(1,1,1))) ≈ RayTracing.Pnt3(1,1,1) 
end

@testset "Distributions1D --> continuous sampling" begin
    # tests stolein from PBRT :)
    x = Float64[1.0, 1.0, 2.0, 4.0, 8.0]
    d = RayTracing.Distribution1D(x)

    # test 1: u=0.0, lower bound
    val, val_pdf, val_offset = RayTracing.sample_continuous(d, 0.0)
    @test val ≈ 0.0
    @test val_pdf ≈ length(x) / 16.0
    @test val_offset ≈ 1

    # test 2: u=0.5, on the cut point
    val, val_pdf, val_offset = RayTracing.sample_continuous(d, 0.5)
    @test val ≈ 0.8    

    # test 3: u = .75, middle of section
    val, val_pdf, val_offset = RayTracing.sample_continuous(d, 0.75)
    @test val ≈ 0.9
    @test val_pdf ≈ length(x) * 8.0 / 16.0
    @test val_offset ≈ 5

    # test 4: u = 1.0, upper bound
    val, val_pdf, val_offset = RayTracing.sample_continuous(d, 1.0)
    @test val ≈ 1.0
end

@testset "Distributions1D --> discrete sampling" begin
    # tests stolein from PBRT :)
    x = Float64[0.0, 1.0, 0.0, 3.0]
    d = RayTracing.Distribution1D(x)

    @test 0.00 ≈ RayTracing.discrete_pdf(d, 1)
    @test 0.25 ≈ RayTracing.discrete_pdf(d, 2)
    @test 0.00 ≈ RayTracing.discrete_pdf(d, 3)
    @test 0.75 ≈ RayTracing.discrete_pdf(d, 4)

    val, val_pdf, val_offset = RayTracing.sample_discrete(d, 0.0)
    @test val ≈ 2
    @test val_pdf ≈ 0.25
    val, val_pdf, val_offset = RayTracing.sample_discrete(d, 0.125)
    @test val ≈ 2
    @test val_pdf ≈ 0.25
    @test val_offset ≈ 0.5
    val, val_pdf, val_offset = RayTracing.sample_discrete(d, 0.24999)
    @test val ≈ 2
    @test val_pdf ≈ 0.25
    val, val_pdf, val_offset = RayTracing.sample_discrete(d, 0.250001)
    @test val ≈ 4
    @test val_pdf ≈ 0.75
    val, val_pdf, val_offset = RayTracing.sample_discrete(d, 0.625)
    @test val ≈ 4
    @test val_pdf ≈ 0.75
    @test val_offset ≈ 0.5
    val, val_pdf, val_offset = RayTracing.sample_discrete(d, 1-eps(Float64))
    @test val ≈ 4
    @test val_pdf ≈ 0.75
    val, val_pdf, val_offset = RayTracing.sample_discrete(d, 1.0)
    @test val ≈ 4
    @test val_pdf ≈ 0.75
end

@testset "LightDistribution --> centroid_distance distribution" begin
    # Case 1: Four point lights equally far away fom p
    mat1 = RayTracing.Matte(
        RayTracing.ConstantTexture(RayTracing.Vec3(.4, .4, .4)),
        RayTracing.ConstantTexture(RayTracing.Vec3(0, 0, 0)),
        nothing
    )
    ball1 = RayTracing.Sphere(
        RayTracing.ShapeCore(RayTracing.Translate(RayTracing.Pnt3(0)), RayTracing.Inv(RayTracing.Translate(RayTracing.Pnt3(0))), false, false),
        5.0
    )
    bvh = RayTracing.BVH(RayTracing.Primitive[
        RayTracing.Primitive(ball1, mat1, nothing),
    ])
    lights = RayTracing.Light[
        RayTracing.PointLight(RayTracing.Translate(RayTracing.Pnt3(0, 10,0)), RayTracing.Spectrum(10,10,10)),
        RayTracing.PointLight(RayTracing.Translate(RayTracing.Pnt3(10, 0,0)), RayTracing.Spectrum(10,10,10)),
        RayTracing.PointLight(RayTracing.Translate(RayTracing.Pnt3(-10, 0,0)), RayTracing.Spectrum(10,10,10)),
        RayTracing.PointLight(RayTracing.Translate(RayTracing.Pnt3(0, -10,0)), RayTracing.Spectrum(10,10,10)),
    ]
    fake_scene = RayTracing.Scene(lights, bvh)
    ld_generator = RayTracing.LightDistribution("centroid_distance", fake_scene)
    ld = RayTracing.lookup(ld_generator, RayTracing.Pnt3(0,0,0))
    @test ld.cdf ≈ [0.0, 0.25, 0.5, 0.75, 1.0]

    val, val_pdf, val_offset = RayTracing.sample_discrete(ld, 1.0)
    @test val ≈ 4
    @test val_pdf ≈ 0.25

    val, val_pdf, val_offset = RayTracing.sample_discrete(ld, 0.1)
    @test val ≈ 1
    @test val_pdf ≈ 0.25

    # Case 2: Four point lights NOT equally far away fom p
    a, b, c, d = 10, 20, 40, 80
    lights = RayTracing.Light[
        RayTracing.PointLight(RayTracing.Translate(RayTracing.Pnt3(0, a, 0)), RayTracing.Spectrum(10,10,10)),
        RayTracing.PointLight(RayTracing.Translate(RayTracing.Pnt3(0, b, 0)), RayTracing.Spectrum(10,10,10)),
        RayTracing.PointLight(RayTracing.Translate(RayTracing.Pnt3(0, c, 0)), RayTracing.Spectrum(10,10,10)),
        RayTracing.PointLight(RayTracing.Translate(RayTracing.Pnt3(0, d, 0)), RayTracing.Spectrum(10,10,10)),
    ]
    fake_scene = RayTracing.Scene(lights, bvh)
    ld_generator = RayTracing.LightDistribution("centroid_distance", fake_scene)
    ld = RayTracing.lookup(ld_generator, RayTracing.Pnt3(0,0,0))

    norm = 1/a^2 + 1/b^2 + 1/c^2 + 1/d^2
    @test ld.cdf ≈ [0.0, (1/a^2)/norm, (1/a^2)/norm + (1/b^2)/norm, (1/a^2)/norm + (1/b^2)/norm + (1/c^2)/norm, 1.0]

    val, val_pdf, val_offset = RayTracing.sample_discrete(ld, 0.5)
    @test val ≈ 1
    @test val_pdf ≈ (1/a^2)/norm
end

@testset "Distributions2 --> discrete sampling" begin
    # tests stolein from PBRT :)
    x = reshape([
        [4.0, 5.0, 4.0, 3.0, 3.0, 4.0, 1.0]
        [3.0, 1.0, 7.0, 6.0, 3.0, 5.0, 2.0]
        [1.0, 7.0, 7.0, 7.0, 4.0, 7.0, 1.0]
        [0.0, 8.0, 9.0, 13.0, 9.0, 7.0, 1.0]
        [5.0, 7.0, 10.0, 13.0, 9.0, 5.0, 0.0]
        [0.0, 5.0, 12.0, 15.0, 15.0, 9.0, 1.0]
        [1.0, 7.0, 12.0, 15.0, 11.0, 4.0, 2.0]
        [1.0, 4.0, 7.0, 9.0, 6.0, 7.0, 4.0]
        [0.0, 5.0, 5.0, 11.0, 8.0, 5.0, 1.0]
        [4.0, 2.0, 6.0, 4.0, 2.0, 5.0, 4.0]
        [4.0, 3.0, 5.0, 3.0, 3.0, 0.0, 5.0]
    ], 7, 11)
    d = RayTracing.Distribution2D(x)
    uv, pdf_val = RayTracing.sample_discrete(d, RayTracing.Pnt2(0.5, 0.5))
    @test uv == RayTracing.Pnt2(6.0, 4.0)
    @test pdf_val ≈ 15.0 / 99.0 * 99.0 / 413.0

    uv, pdf_val = RayTracing.sample_continuous(d, RayTracing.Pnt2(0.5, 0.5))
end