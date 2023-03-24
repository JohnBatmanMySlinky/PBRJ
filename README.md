# PBRJ
Physically Based Rendering - in Julia

An implementation of [Physically Based Rendering: From Theory to Implementation 3rd Edition](https://www.pbr-book.org/) in the Julia Language.

# How to use
How to render the Cornell Box with 100 samples per pixel using 4 threads. 
```
julia -t 4 RayTracing.jl --scene-number 4 --samples-per-pixel 100
```

## Notes of Usage
- I have only implemented a subset of materials specified in the book. 
- My obj parser is quite anemic.
- Samplers are limited to Random and Stratified.
- Scene specification is very verbose and done entirely within `scene_builder.jl`. Only a few things are parameterized thru the CLI.
- There are lots of partially implemented things: BDPT has only been tested with AreaLights, not sure if all the CLI args work anymore, some scenes might need to be updated etc.

# TODO
## Features
- BDPT is much less buggy now!
    - implement spectrum is black checks
    - move to exr?
- Triangles using UInt16 when small enough?
    - seems like I get a very small pay off when I did a quick test.
- Implement light BVH (or spatial light distribution)
- Implement Metroplois Light Transport Integrator
- Implement more materials
    - Add metal material
    - Add fourier material
- Improve munich re scene 
    - Add more walls (left wall corner)
    - ~~Add colored panels~~
    - Add in more scene geometry (baseboards? stairs? elevator?)
    - Get reflections in back hallway looking nice and in general floor material
    - Wall material
- Parameterize more stuff (like which integrator you want to use).
- Move scene specification to a YAML or something. 
- Make obj_parser less anemic
- Expand tests

## Debt
- Implement passes with more dimensions of our film. Current method is hardcody and requires us to re-instantiate the scene every time!
- What are my ray differentials actually being used for ?
- Is my BSDF sampling right? I should create some tests here
- Code
    - Static & dynamic code analysis
- Improve sampling
    - remove unnecessary sampling dims
- Add in synonyms to instantiate simple stuff Vec3(), Translate(), etc.

## Bugs
- XYZ color to RGB, I am doing something wrong...
- Infinite light sampling is very broken. 
- My world is upside down! Use real pbrt to debug (or pxl-th's)
- Halton sampler doesn't work for more than (0,1]^2
- There is some aliasing around the edge of every time, it looks like an off by one error on the edge? Somewhere in the film / film-tile or sampling...

## Ideas
- Should I instantiate a list of samplers or stick with deepcopy()?
- Is using rand() across threads optimal?

# Beyond PBRT
- Denoiser. Opportunity for ML here?

# Sources
- Based on [Physically Based Rendering: From Theory to Implementation by Matt Pharr, Wenzel Jakob, and Greg Humphreys](https://www.pbr-book.org/).
- [This implementation of PBRT in Julia](https://github.com/pxl-th/Trace.jl) repo has been an invaluable reference.
- [3dtextures.com](https://3dtextures.me/2021/12/15/stone-floor-006/) Has some wonderful free texture maps.
