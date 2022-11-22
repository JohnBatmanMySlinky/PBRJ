# PBRJ
Physically Based Rendering - in Julia

# Sources
- Based on [Physically Based Rendering: From Theory to Implementation by Matt Pharr, Wenzel Jakob, and Greg Humphreys](https://www.pbr-book.org/).
- [This implementation of PBRT in Julia](https://github.com/pxl-th/Trace.jl) repo has been an invaluable reference.
- [3dtextures.com](https://3dtextures.me/2021/12/15/stone-floor-006/) Has some wonderful free texture maps.

# TODO
- add path integrator
    - document bxdf and bsdf and fresnel and stuff!
    - ~~add better light sampling strategies from github~~ (not doing, will wait for light bvh in v4)
    - ~~infinite light is broken~~
    - harmoinze bsdf flags and light flags
- instead of copying sampler within multi-threaded loop, can we instantiate a list?
- Improve sampling
    - a notebook to visually test results
    - Halton Sampler
    - remove unnecessary sampling dims
- What are the right filter parameters
- Add in synonyms to instantiate simple stuff Vec3(), Translate(), etc
- Scene work
    - Add more walls (left wall corner).
    - Add colored panels.
    - Add in more scene geometry (baseboards? stairs? elevator?)
    - Get reflections in back hallway looking nice and in general floor material.
    - Wall material.
    - Better ambient lighting.
- Stratified sampler edges...
- Add metal material
- Add fourier material.
- Make obj_parser less anemic.
- Expand tests. 
- Profile code base.
    - @inline some stuff?
    - Sampler feels inefficient. 
    - How does multi-threading interact with sampler?
- Clean up code base, use more '.x' and less '[1]'
- ~~Make CLI.~~
- ~~Distant light~~
- ~~Improve scene specification interface.~~
- ~~Texture tiling.~~

# Research
- Quantify benefit of multi threading (todo after CLI)

# Beyond PBRT
- Importance sampling