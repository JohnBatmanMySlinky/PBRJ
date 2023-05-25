# PBRJ
Physically Based Rendering - in Julia

An implementation of [Physically Based Rendering: From Theory to Implementation](https://www.pbr-book.org/) in the Julia programming language.

# Usage
- Example command line usage
    - `julia -t 4 RayTracing.jl --scene-number 2 --samples-per-pixel 16 --image-dim 250 --file-name "test.png"`
    - see `src/args.jl` for a full specification of command line options
- Scenes are specified within `src/scene_builder.jl`
    1. Munich Re scene. Interior scene. many (relative) diffuse area lights. specular floor. 
        <details>
            <summary>Click to show image</summary>
            
            ![munich_scene](https://github.com/JohnBatmanMySlinky/PBRJ/blob/ao2/renders/munich-scene.png?raw=true)
        </details>

    2. Caustic glass
        <details>
            <summary>Click to show image</summary>
            
            ![caustic_glass](https://github.com/JohnBatmanMySlinky/PBRJ/blob/ao2/renders/caustic-glass.png?raw=true)
        </details>

    3. Dragon on a plane with Ambient Occlusion integrator
        <details>
            <summary>Click to show image</summary>
            
        </details>
    4. Cornell Box
        <details>
            <summary>Click to show image</summary>
            
        </details>

## Features
- Bi-Directional Path Tracing (BDPT)
    - implement the rest of the lights
- Implement Metroplois Light Transport Integrator
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
- Improve munich re scene 
    - Add more walls (left wall corner)
    - Add in more scene geometry (baseboards? stairs? elevator?)
    - Get reflections in back hallway looking nice and in general floor material
    - Wall material
- Parameterize more stuff
    - integrator
    - logging
- Move scene specification to a YAML or something. 
- Expand test coverage

## Debt
- stop kludging this and implement two versions: Texture<Spectrum> vs Texture<Float>
    - really good opportunity for parameterized types!!?
- implement spectrum is black checks and measure preformance improvement
- clean up surface interaction instantiation (esp. when empty)
- Implement passes with more dimensions of our film. Current method is hardcody and requires us to re-instantiate the scene every time!
- Implement texture sampling and use those ray differentials
- Static & dynamic code analysis
- Add in synonyms to instantiate simple stuff Vec3(), Translate(), etc.

## Bugs
- XYZ color to RGB, I am doing something wrong...
- My world is upside down! Use real pbrt to debug (or pxl-th's)
- Sometimes objects are see through (ie when they have a really bright light behind them)

## Ideas
- Triangles using UInt16 when small enough?
    - seems like I get a very small pay off when I did a quick test.
- tuple of lights instead of vector?
- can I make rays immutable and re-instantiate when mutation is needed?

# Beyond PBRT
- Denoiser. Opportunity for ML here?

# Sources
- Based on [Physically Based Rendering: From Theory to Implementation by Matt Pharr, Wenzel Jakob, and Greg Humphreys](https://www.pbr-book.org/).
- [This implementation of PBRT in Julia](https://github.com/pxl-th/Trace.jl) repo has been an invaluable reference.
- [3dtextures.com](https://3dtextures.me/2021/12/15/stone-floor-006/) Has some wonderful free texture maps.
