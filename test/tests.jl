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

@testset "Distributions - 1D" begin
    x = Float64[1.0, 2.0, 3.0, 4.0]
    d = RayTracing.Distribution1D(x)
    @test d.pdf ≈ Float64[0.1, 0.2, 0.3, 0.4]
    @test d.cdf ≈ Float64[0.0, 0.1, 0.3, 0.6, 1.0]
    @test d.len ≈ 4

    val, val_pdf = RayTracing.sample_continuous(d, 0.05)
    @test val ≈ 0.125
    @test val_pdf ≈ 0.1

    val, val_pdf = RayTracing.sample_continuous(d, 0.75)
    @test val ≈ 0.84375
    @test val_pdf ≈ 0.4

    val, val_pdf = RayTracing.sample_continuous(d, 0.3)
    @test val ≈ 0.5
    @test val_pdf ≈ 0.2
end
