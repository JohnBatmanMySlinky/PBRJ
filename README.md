# PBRJ
Physically Based Rendering - in Julia

A partial implementation of [Physically Based Rendering: From Theory to Implementation 3rd Edition](https://www.pbr-book.org/) in the Julia Language.

# How to use
- TODO

# General Commentary on this whole experience
- Julia is wonderful.
- BVH is (obviously) really important and I am forever grateful of pxl-th's implementation
- PBRT's sampler implementation gave (and continues to give) me a headache.
- BxDFs make sense in practice but their implementation is hard for me to wrap my head around.

# TODO
## Features
- Implement PathIntegrator
    - document bxdf and bsdf and fresnel and stuff hierarchy!
    - ~~add better light sampling strategies from github~~ (not doing, will wait for light bvh in v4)
    - ~~infinite light is broken~~
    - harmoinze bsdf flags and light flags
- Implement Bidirectional Path Tracing
    - move from book's `uniform_sample_one_light()` to the code's `light_distribution` abstraction 
    - THEN what I implemented a `sample_lights_based_on_distance()` ? That should help the back hallway?
- Implement more materials
    - Add metal material
    - Add fourier material
- Improve munich re scene 
    - Add more walls (left wall corner)
    - ~~Add colored panels~~
    - Add in more scene geometry (baseboards? stairs? elevator?)
    - Get reflections in back hallway looking nice and in general floor material
    - Wall material
- Make obj_parser less anemic
- Expand tests

## Debt
- Is my BSDF sampling right? I should create some tests here
- Code
    - Static & dynamic code analysis
- Improve sampling
    - remove unnecessary sampling dims
- Add in synonyms to instantiate simple stuff Vec3(), Translate(), etc.

## Bugs
- My world is upside down! Use real pbrt to debug (or pxl-th's)
- Halton sampler doesn't work for more than (0,1]^2
- There is some aliasing around the edge of every time, it looks like an off by one error on the edge? Somewhere in the film or sampling...
- Should I instantiate a list of samplers or stick with deepcopy()?
- Is using rand() across threads optimal?

# Beyond PBRT
- Denoiser. Opportunity for ML here?

# Sources
- Based on [Physically Based Rendering: From Theory to Implementation by Matt Pharr, Wenzel Jakob, and Greg Humphreys](https://www.pbr-book.org/).
- [This implementation of PBRT in Julia](https://github.com/pxl-th/Trace.jl) repo has been an invaluable reference.
- [3dtextures.com](https://3dtextures.me/2021/12/15/stone-floor-006/) Has some wonderful free texture maps.
