# PBRJ
Physically Based Rendering - in Julia

# Sources
- Based on [Physically Based Rendering: From Theory to Implementation by Matt Pharr, Wenzel Jakob, and Greg Humphreys](https://www.pbr-book.org/).
- [This implementation of PBRT in Julia](https://github.com/pxl-th/Trace.jl) repo has been an invaluable reference.
- [3dtextures.com](https://3dtextures.me/2021/12/15/stone-floor-006/) Has some wonderful free texture maps.

# TODO
- add path integrator
    - add better light sampling strategies from github
    - infinite light is broken
- instead of copying sampler within multi-threaded loop, can we instantiate a list?
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
- I can assume all objects are static and simplify some camera shutter and sampling details.
- Expand tests. 
- Improve scene specification interface.
- Profile code base.
    - @inline some stuff?
    - Sampler feels inefficient. 
    - How does multi-threading interact with sampler?
- Clean up code base, use more '.x' and less '[1]'
- ~~Make CLI.~~
- ~~Distant light~~

# Research
- Quantify benefit of multi threading (todo after CLI)

# Beyond PBRT
- Importance sampling