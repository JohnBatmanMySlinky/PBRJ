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