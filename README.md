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
- Halton sampler doesn't work for more than 0,0 - 1,1
- Filtering or sampling has a bug and has alias around the edge.
- Should I instantiate a list of samplers or stick with deepcopy()?


## DONE    
- ~~Make CLI.~~
- ~~Distant light~~
- ~~Improve scene specification interface.~~
- ~~Texture tiling.~~
- ~~Stratified sampler edges...~~
- ~~a notebook to visually test results~~

# Beyond PBRT
- Importance sampling
- Denoiser. Opportunity for ML here?

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