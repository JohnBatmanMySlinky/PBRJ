include("../src/RayTracing.jl")

using Test

@testset "Spectral Spectrums" begin
    print("input: (0, 0, 1)\n")
    a::RayTracing.Spectrum = RayTracing.spectrum_from_float(0.0, 0.0, 1.0)
    print("spectral: $(a)\n")
    b = RayTracing.to_XYZ(a)
    print("xyz: $(b)\n")
    c = RayTracing.XYZ_to_RGB(b)
    print("rgb: $(c)\n")
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
    @test 1.4003 == RayTracing.average_spectrum_samples(CopperWavelengths, CopperN, CopperSamples, 0.0, 300.0)
end

"""
/******************************************************************************

                              Online C++ Compiler.
               Code, Compile, Run and Debug C++ program online.
Write your code in this editor and press "Run" button to compile and execute it.

*******************************************************************************/

#include <iostream>

using namespace std;

const int CopperSamples = 56;

const float CopperWavelengths[CopperSamples] = {
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
    885.6012714};

const float CopperN[CopperSamples] = {
    1.400313, 1.38,  1.358438, 1.34,  1.329063, 1.325, 1.3325,   1.34,
    1.334375, 1.325, 1.317812, 1.31,  1.300313, 1.29,  1.281563, 1.27,
    1.249062, 1.225, 1.2,      1.18,  1.174375, 1.175, 1.1775,   1.18,
    1.178125, 1.175, 1.172812, 1.17,  1.165312, 1.16,  1.155312, 1.15,
    1.142812, 1.135, 1.131562, 1.12,  1.092437, 1.04,  0.950375, 0.826,
    0.645875, 0.468, 0.35125,  0.272, 0.230813, 0.214, 0.20925,  0.213,
    0.21625,  0.223, 0.2365,   0.25,  0.254188, 0.26,  0.28,     0.3};

float Lerp(float t, float v1, float v2) { return (1 - t) * v1 + t * v2; }

float AverageSpectrumSamples(const float *lambda, const float *vals, int n,
                             float lambdaStart, float lambdaEnd) {
    // Handle cases with out-of-bounds range or single sample only
    if (lambdaEnd <= lambda[0]) return vals[0];
    if (lambdaStart >= lambda[n - 1]) return vals[n - 1];
    if (n == 1) return vals[0];
    float sum = 0;
    // Add contributions of constant segments before/after samples
    if (lambdaStart < lambda[0]) sum += vals[0] * (lambda[0] - lambdaStart);
    if (lambdaEnd > lambda[n - 1])
        sum += vals[n - 1] * (lambdaEnd - lambda[n - 1]);

    // Advance to first relevant wavelength segment
    int i = 0;
    while (lambdaStart > lambda[i + 1]) ++i;

    // Loop over wavelength sample segments and add contributions
    auto interp = [lambda, vals](float w, int i) {
        return Lerp((w - lambda[i]) / (lambda[i + 1] - lambda[i]), vals[i],
                    vals[i + 1]);
    };
    for (; i + 1 < n && lambdaEnd >= lambda[i]; ++i) {
        float segLambdaStart = std::max(lambdaStart, lambda[i]);
        float segLambdaEnd = std::min(lambdaEnd, lambda[i + 1]);
        sum += 0.5 * (interp(segLambdaStart, i) + interp(segLambdaEnd, i)) *
               (segLambdaEnd - segLambdaStart);
    }
    return sum / (lambdaEnd - lambdaStart);
}


int main()
{
    cout<<AverageSpectrumSamples(CopperWavelengths, CopperN, CopperSamples, 300.0, 400.0);

    return 0;
}
"""