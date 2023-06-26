# PBRJ
Physically Based Rendering - in Julia

An implementation of [Physically Based Rendering: From Theory to Implementation](https://www.pbr-book.org/) in the Julia programming language.

# Usage
- Example command line usage
    - `julia -t 4 RayTracing.jl --scene-number 2 --samples-per-pixel 16 --image-dim 250 --n-spectral-samples 10 --file-name "test.png"`
    - see `src/args.jl` for a full specification of command line options
- Scenes are specified within `src/scene_builder.jl`
    1. Office scene. Interior scene. many (relative) diffuse area lights. specular floor. 

        ![office_scene](https://github.com/JohnBatmanMySlinky/PBRJ/blob/main/renders/munich-scene.png?raw=true)

    2. Caustic glass

        ![caustic_glass](https://github.com/JohnBatmanMySlinky/PBRJ/blob/main/renders/caustic-glass.png?raw=true)
        
    3. Dragon on a plane with Ambient Occlusion integrator

        ![dragon](https://github.com/JohnBatmanMySlinky/PBRJ/blob/main/renders/dragon.png?raw=true)

    4. Cornell Box

        ![cornell_box](https://github.com/JohnBatmanMySlinky/PBRJ/blob/main/renders/cornell-box.png?raw=true)
        

## Features Implemented
- BVH accelerator
- Perspective camera
- Edge-avoiding a-trous denoising
- BDPT, ambient occlusion, path & whitted integrators
- Area, distant, infinite, point, and spot lights
- Glass, matte, metal, mirror, plastic, and substrate materials
- Stratified sampling
- Box, cylindar, disk, rectangle, sphere, and triangle shapes
- RGB & spectral rendering
- Constant, image, mixed, procedural and mixed textures
- Logging

# Feature List
- use y() and dont hack with mean
- build in rendering passes natively
- Make sure I am sampling purley over the solid angle
- Implement Metroplois Light Transport Integrator
- Implement texture sampling and use those ray differentials
- Move to EXR
    - ~~for env lights~~
    - for final image
- Move the pbrt-v4's sampler structure
    - Implement more samplers beyond just stratified sampler
- Make obj_parser less anemic.
- Implement more materials
    - Add glass material
        - make sure all paths of Glass's compute scattering function work
        - pass all pxl-th's tests
    - Add metal material
    - Add fourier material
- Improve munich scene 
    - Add more walls (left wall corner)
    - Add in more scene geometry (baseboards? stairs? elevator?)
    - Get reflections in back hallway looking nice and in general floor material
    - Wall material
- Parameterize more stuff
    - integrator
    - logging
- Move scene specification to a YAML or something. 
- Expand test coverage

## Bugs
- XYZ color to RGB, I am doing something wrong...
- My world is upside down! Use real pbrt to debug (or pxl-th's)
- Sometimes objects are see through (ie when they have a really bright light behind them)

## Ideas
- Triangles using UInt16 when small enough?
    - seems like I get a very small pay off when I did a quick test.
- tuple of lights instead of vector?
- ~~can I make rays immutable and re-instantiate when mutation is needed?~~ No performance boost observed.

# Beyond PBRT
- Denoiser. Opportunity for ML here?

# Sources
- Based on [Physically Based Rendering: From Theory to Implementation by Matt Pharr, Wenzel Jakob, and Greg Humphreys](https://www.pbr-book.org/).
- [This implementation of PBRT in Julia](https://github.com/pxl-th/Trace.jl) repo has been an invaluable reference.
- [3dtextures.com](https://3dtextures.me/2021/12/15/stone-floor-006/) Has some wonderful free texture maps.
