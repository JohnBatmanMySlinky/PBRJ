include("../src/RayTracing.jl")

using Test


@testset "Creating conversion constants" begin
    @test sum(RayTracing.rgbRefl2SpectWhite - [1.0623, 1.06166, 1.06249, 1.06124]) < .01
    @test sum(RayTracing.rgbRefl2SpectCyan - [1.03195, 1.05198, 0.577821, 0.00287357]) < .01
    @test sum(RayTracing.rgbRefl2SpectMagenta - [1.00789, 0.2194, 0.533892, 0.941869]) < .01
    @test sum(RayTracing.rgbRefl2SpectYellow - [0.0546859, 0.826093, 1.05141, 1.05051]) < .01
    @test sum(RayTracing.rgbRefl2SpectRed - [0.0473866, -0.00415798, 0.501113, 0.99376]) < .01
    @test sum(RayTracing.rgbRefl2SpectGreen - [0.013564, 0.881334, 0.563789, -0.00667087]) < .01
    @test sum(RayTracing.rgbRefl2SpectBlue - [0.988841, 0.251697, 0.00503804, 0.0402184]) < .01

    @test sum(RayTracing.rgbIllum2SpectWhite - [1.15645, 1.14794, 1.00406, 0.887115]) < .01
    @test sum(RayTracing.rgbIllum2SpectCyan - [1.13583, 1.13585, 0.606187, -0.00927071]) < .01
    @test sum(RayTracing.rgbIllum2SpectMagenta - [1.0766, 0.365246, 0.381516, 1.04655]) < .01
    @test sum(RayTracing.rgbIllum2SpectYellow - [0.0223417, 0.963893, 1.03094, 0.670829]) < .01
    @test sum(RayTracing.rgbIllum2SpectRed - [0.0306278, 8.94049e-06, 0.384173, 0.982426]) < .01
    @test sum(RayTracing.rgbIllum2SpectGreen - [0.0116823, 0.938951, 0.594614, 0.00460501]) < .01
    @test sum(RayTracing.rgbIllum2SpectBlue - [1.05672, 0.328836, 0.000490442, 0.123488]) < .01
end

@testset "Spectral Conversions" begin
    for x in [[0.75, 0.75, 0.75], [1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [1.0, 1.0, 1.0], [0.0, 0.0, 0.0], [.05, .9, .05], [20.0, 20.0, 20.0]]
        print("input: $(x)\n")
        a::RayTracing.Spectrum = RayTracing.spectrum_from_float(x...)
        print("spectral: $(a)\n")
        b = RayTracing.to_XYZ(a)
        print("xyz: $(b)\n")
        c = RayTracing.XYZ_to_RGB(b)
        print("rgb: $(c)\n")
        print("\n")
    end
end

CopperSamples = 56
CopperWavelengths = Float64[
    298.7570554, 302.4004341, 306.1337728, 309.960445,  313.8839949,
    317.9081487, 322.036826,  326.2741526, 330.6244747, 335.092373,
    339.6826795, 344.4004944, 349.2512056, 354.2405086, 359.374429,
    364.6593471, 370.1020239, 375.7096303, 381.4897785, 387.4505563,
    393.6005651, 399.9489613, 406.5055016, 413.2805933, 420.2853492,
    427.5316483, 435.0322035, 442.8006357, 450.8515564, 459.2006593,
    467.8648226, 476.8622231, 486.2124627, 495.936712,  506.0578694,
    516.6007417, 527.5922468, 539.0616435, 551.0407911, 563.5644455,
    576.6705953, 590.4008476, 604.8008683, 619.92089,   635.8162974,
    652.5483053, 670.1847459, 688.8009889, 708.4810171, 729.3186941,
    751.4192606, 774.9011125, 799.8979226, 826.5611867, 855.0632966,
    885.6012714]
CopperN = Float64[
        1.400313, 1.38,  1.358438, 1.34,  1.329063, 1.325, 1.3325,   1.34,
        1.334375, 1.325, 1.317812, 1.31,  1.300313, 1.29,  1.281563, 1.27,
        1.249062, 1.225, 1.2,      1.18,  1.174375, 1.175, 1.1775,   1.18,
        1.178125, 1.175, 1.172812, 1.17,  1.165312, 1.16,  1.155312, 1.15,
        1.142812, 1.135, 1.131562, 1.12,  1.092437, 1.04,  0.950375, 0.826,
        0.645875, 0.468, 0.35125,  0.272, 0.230813, 0.214, 0.20925,  0.213,
        0.21625,  0.223, 0.2365,   0.25,  0.254188, 0.26,  0.28,     0.3]

@testset "Average Spectrum Samples" begin
    @test 1.4003 ≈ RayTracing.average_spectrum_samples(CopperWavelengths, CopperN, CopperSamples, 0.0, 300.0)  atol=0.001
    @test 1.28138 ≈ RayTracing.average_spectrum_samples(CopperWavelengths, CopperN, CopperSamples, 300.0, 400.0)  atol=0.001
    @test 0.919478 ≈ RayTracing.average_spectrum_samples(CopperWavelengths, CopperN, CopperSamples, 0.0, 900.0)  atol=0.001
    @test 1.4003 ≈ RayTracing.average_spectrum_samples(CopperWavelengths, CopperN, CopperSamples, 0.0, 1.0)  atol=0.001
    @test 0.3 ≈ RayTracing.average_spectrum_samples(CopperWavelengths, CopperN, CopperSamples, 900.0, 901.0)  atol=0.001
end