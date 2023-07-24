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

# To do's
- Implicit Surfaces
- use y() and dont hack with mean
- build in rendering passes natively
    - don't just use 1 spp for rendering passes
- Julia 1.9 has native support for Float16, a 4x speed up would be very nice albeit at some cost.
- Make sure I am sampling purley over the solid angle
- Implement Metroplois Light Transport Integrator
- Implement texture sampling and use those ray differentials
- Liberal use of `const` in all mutable structs
- `Scene` uses a vector of (abstract) lights. would a tuple of lights be better? Could I use a macro to generate scene specific struct?
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
- My world is upside down! Use real pbrt to debug (or pxl-th's)
- Sometimes objects are see through (ie when they have a really bright light behind them)

## Ideas
- ~~Triangles using UInt16 when small enough?~~ I get a very small pay off when I did a quick test.
- ~~can I make rays immutable and re-instantiate when mutation is needed?~~ No performance boost observed.

# Beyond PBRT
- Denoiser. Opportunity for ML here?

# Sources
- Based on [Physically Based Rendering: From Theory to Implementation by Matt Pharr, Wenzel Jakob, and Greg Humphreys](https://www.pbr-book.org/).
- [This implementation of PBRT in Julia](https://github.com/pxl-th/Trace.jl) repo has been an invaluable reference.
- [3dtextures.com](https://3dtextures.me/2021/12/15/stone-floor-006/) Has some wonderful free texture maps.


# Metaball learnings
- Implicit Surfaces
    - Some math
        - Definitions to start
            - $\bm{p}$ represents a vector. In our case, most likely a point in 3d space with components $p_x, p_y, p_z$
            - $||\bm{p}||$ represents the **norm** of that vector. Component wise, this looks like $\sqrt{p_x^2 + p_y^2 + p_z^2}$
        - An implicit surface takes the form $F(\bm{p}) = 0$
            - where $F$ is a function 
            - where $\bm{p}$ is a point in space
            - $\bm{p}$ is on the surface if and only if $F(\bm{p})=0$. 
        - This formulation makes it easy to test if $\bm{p}$ is on the surface, however this representation gives you no way to systematicaly generate consecutive points on the surface. 
        - Let's apply this framework and math to a sphere. 
            - Equation for a sphere: $\bm{p}^2-r^2 = 0$ where $r$ is the radius. 
            - Expanding vector notation: $\bm{p}^2$ = $p_x^2 + p_y^2 + p_z^2$ gives us $p_x^2 + p_y^2 + p_z^2 - r^2 = 0$
        - Now let's introduce the ray and construct the ray intersection test math. 
            - Let's parameterize our ray as a function of time, an origin and a direction: $r(t) = \bm{p} = \bm{o} + t * \bm{d}$
            - Expanding vector notation: $r(t) = \bm{p} = (o_x + t * d_x) + (o_ + t * d_y) + (o_z + t * d_z)$
        - So our ray defines a point $\bm{p}$ as a function of time. Subbing in our equation for a sphere gives us
            - $(o_x + t * d_x)^2 + (o_y + t * d_y)^2 + (o_z + t * d_z)^2 - r^2 = 0$
            - Which now is an equation with **one unknown** $t$ that we can easily solve for. When you expand terms you will more clearly see that this is a nice quadratic to which we can apply the quadratic formula or use a more generic root finding algorithm.
            - I liked how this paper drove home why it is a single variable problem: https://graphicsinterface.org/wp-content/uploads/gi1990-8.pdf. PBRT was also helpful here.
        - https://people.computing.clemson.edu/~dhouse/courses/405/notes/implicit-parametric.pdf
    - Metaballs
        - Now let's apply this framework to Metaballs. This was honestly a bit trickier for me. Just translation vernacular into one consistent basis was a challenge. 
        - I think it is important to keep in mind the core idea of Implicit Surfaces, they are a function of a point in 3d space. The surface is defined as the set of points where that function equals zero. 
        - So the whole game is one of solving roots. Youre trying to find points in space that result in your function being zero, $F(\bm{p}) = 0$. And if your point $\bm{p}$ can be defined as $\bm{p} = r(t) = (o_x + t * d_x) + (o_ + t * d_y) + (o_z + t * d_z)$ then really it is about finding $t$ that result in $F(r(t)) = 0$
        - this article's 2d examples made things click a lot: http://www.geisswerks.com/ryan/BLOBS/blobs.html
        
    
    
    - this article had the lovely normal hack. http://rodolphe-vaillant.fr/entry/87/normal-to-an-implicit-surface
    
    - stick some math in here
- How to fit into PBRT.
    - Easy (if we assume they cannot be emmissive). We only need the two following methods.
        - Intersect (+ IntersectP)
        - ObjectBounds
    - Intersect is also made easy if we assume that they surface will not be UV textured. Because our surface interaction really just needs p, t, n at it's core (pun intended)
    - Normals can be approximated via (INIGO QUILEZ + French guy).
    - The actual ray object intersection is the fun part. 
- Ray object intersection
    - Naive algorithm. Use a generic Solver library to calculate at what t, our ray will intersect the surface of the metaball. This is a pretty straightforward single variable root finding problem.
    - My first catch was that using that generic Solvier library wasn't so easy. 
    - I needed to define bounds in which the ray intersection could exist. My initial heuristic was to get an upper bound on my solution space by looking at my world radius and using a mean magnitude of the ray distance vector. 
    - This wasn't good enough. 
    - Second move was the calculate a bounding sphere of our metaball, re-use sphere intersection code and use the solutions to the bounding sphere -ray intersection as bounds for the metaball root solve.
    - now i have something that 'works' lets do some test renders
        - number of balls
        - more reflective material
    - my guess is that is going to be slow because intersection grows linearly with # of balls. let's use the idea that some balls are far away and will never influence the f().
        - first BVH idea
            - create BVH of balls
            - shoot ray all the way through the BVH until you don't hit any more balls. 
            - every ball that is hit, could be active
                - we can prune at the end. we will see the closest hit and then can remove balls too far away
                    - !! Need to be careful, our tree doesnt guarantee first hit is closest... i think
            - with active balls, go about your normal business
        - second BVH idea 
            - ray tracing gems 2 approach with inner and outer bounding spheres