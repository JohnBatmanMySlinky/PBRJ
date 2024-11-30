// pbrt is Copyright(c) 1998-2020 Matt Pharr, Wenzel Jakob, and Greg Humphreys.
// The pbrt source code is licensed under the Apache License, Version 2.0.
// SPDX: Apache-2.0

#include <gtest/gtest.h>

#include <pbrt/pbrt.h>

#include <pbrt/bsdf.h>
#include <pbrt/interaction.h>
#include <pbrt/options.h>
#include <pbrt/paramdict.h>
#include <pbrt/shapes.h>
#include <pbrt/util/image.h>
#include <pbrt/util/log.h>
#include <pbrt/util/memory.h>
#include <pbrt/util/parallel.h>
#include <pbrt/util/print.h>
#include <pbrt/util/rng.h>
#include <pbrt/util/sampling.h>
#include <pbrt/util/spectrum.h>

#include <cstdio>
#include <cstdlib>
#include <fstream>
#include <functional>
#include <iostream>

using namespace pbrt;

TEST(Hair, Intersection) {
    //  curve stuff
    Transform renderFromObject, objectFromRender;
    renderFromObject = Inverse(Translate(Vector3f(0, 2, 5))) * Translate(Vector3f(.15, -.03, 0)) * Scale(7, 7, 7);
    std::cout << "renderFromObject: \n\t" << renderFromObject << std::endl;
    objectFromRender = Inverse(renderFromObject);
    std::cout << "objectFromRender: \n\t" << objectFromRender << std::endl;

    Point3f cpObj[4];
    cpObj[0] = Point3f(-0.048298, 0.076975, -0.018403);
    cpObj[1] = Point3f(-0.047604, 0.078775, -0.022468);
    cpObj[2] = Point3f(-0.04686, 0.077952, -0.026829);
    cpObj[3] = Point3f(-0.046247, 0.075309, -0.030419);
    
    pstd::span<const Normal3f> nspan;

    pstd::vector<Shape> curves;
    curves = Curve::CreateCurve(
        &renderFromObject, 
        &objectFromRender,
        false,
        pstd::MakeConstSpan(cpObj),
        8e-05,
        7e-06,
        CurveType::Flat,
        nspan,
        3,
        Allocator()
    );

    // Ray
    Point3f o(2.451949, -1.669419, -11.742881);
    Vector3f d(-0.37262046f, 0.024686506f, 0.92765534f);
    Ray r(o, d, 0.0f, nullptr);
    std::cout << "Ray: \n\t" << r << " " << std::endl;

    // Intersect
    std::cout << "CURVES:" << std::endl;
    pstd::optional<ShapeIntersection> si;
    for (int i = 0; i < 8; ++i) {
        std::cout << "\t" << i << std::endl;
        std::cout << "\t" << curves[i] << "\n" << std::endl;
        si = curves[i].Intersect(r, 9999999999.999);
        if (si.has_value()){
            std::cout << "SI: \n\t" << si << std::endl;
            
            SampledSpectrum sigma_a(1.3f);
            Float h = .4;
            Float beta_m = 0.5f;
            Float beta_n = 0.5f;
            HairBxDF hair(h, 1.55, sigma_a, beta_m, beta_n, 0.4f);

            Vector3f wo = SampleUniformSphere({0.15, 0.35});
            Vector3f wi = SampleUniformSphere({0.25, 0.75});
            std::cout << "wo: " << wo << " wi " << wi << std::endl;

            SampledSpectrum f = hair.f(wo, wi, TransportMode::Radiance) * AbsCosTheta(wi);
            std::cout << "f: " << f << std::endl;
        }
    }   
}