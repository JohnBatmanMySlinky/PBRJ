# PBRJ
Physically Based Rendering - in Julia

# Sources
- Based on [Physically Based Rendering: From Theory to Implementation by Matt Pharr, Wenzel Jakob, and Greg Humphreys](https://www.pbr-book.org/).
- [This implementation of PBRT in Julia](https://github.com/pxl-th/Trace.jl) repo has been an invaluable reference.
- [3dtextures.com](https://3dtextures.me/2021/12/15/stone-floor-006/) Has some wonderful free texture maps.

# How to use
- TODO

# General Commentary on this whole experience
- BVH is (obviously) really important and am forever grateful of pxl-th's implementation
- Samplers gave (and continue to give) me a migraine
- BxDFs make sense in practice but their implementation hurts my brain.

# TODO
- Implement PathIntegrator
    - document bxdf and bsdf and fresnel and stuff hierarchy!
    - ~~add better light sampling strategies from github~~ (not doing, will wait for light bvh in v4)
    - ~~infinite light is broken~~
    - harmoinze bsdf flags and light flags
- Implement Bidirectional Path Tracing
    - this is a doozy
- My world is upside down! Use real pbrt to debug
- Is my BSDF sampling right? I should create some tests here
- theres a bug in my filtering!!!
- I need a linter or some static code analysis
- Also some dynamic code analysis
- Improve sampling
    - a notebook to visually test results
    - Halton Sampler
    - remove unnecessary sampling dims
    - Need to implement and use the, Sampler, PixelSampler, and GlobalSampler class structure from PBRT
    - implement a discrepancy function to also test with (if halton isnt better im gunna be mad!)
    - quantify convergence of estimation of pi using simple rejection sampling as an evaluation metric
- Implement BDPT
    - my scene is never going to look decent without it
- Implement Cornell Box
- What are the right filter parameters?
- Add in synonyms to instantiate simple stuff Vec3(), Translate(), etc.
- Improve munich re scene 
    - Add more walls (left wall corner)
    - ~~Add colored panels~~
    - Add in more scene geometry (baseboards? stairs? elevator?)
    - Get reflections in back hallway looking nice and in general floor material
    - Wall material
    - Better ambient lighting
- Implement more materials
    - Add metal material
    - Add fourier material
- Make obj_parser less anemic
- Expand tests
- Profile code base
    - @inline some stuff?
    - Sampler feels inefficient
    - How does multi-threading interact with sampler?
- Improvements
    - Clean up code base, use more '.x' and less '[1]'
    - Remove sampling dimensions for lens & time. What is the improvement?
    - Should I instantiate a list of samplers or stick with deepcopy()?
- ~~Make CLI.~~
- ~~Distant light~~
- ~~Improve scene specification interface.~~
- ~~Texture tiling.~~
- ~~Stratified sampler edges...~~

# Research
- Quantify benefit of multi threading (todo after CLI)

# Beyond PBRT
- Importance sampling


# Notes
## Reflectance
### Material
#### What they do
- Instantiate BSDF
- Add BxDFs to BSDF
#### Methods
- (Material)(SurfaceInteraction, Bool, TransportMode)
- bump!(Material, SurfaceInteraction)
### AbstractBSDF
#### What they do
- Hold collection of AbstractBxDFs
#### Methods
- (BSDF)(Vec3, Vec3, Flags)
- sample_f(BSDF, Vec3, Pnt2, UInt8)
- compute_pdf(BSDF, Vec3, Vec3, UInt8)
### AbstractBxDF
#### What they do
#### Methods