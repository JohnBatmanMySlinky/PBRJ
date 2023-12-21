# PBRJ
Physically Based Rendering - in Julia

An implementation of [Physically Based Rendering: From Theory to Implementation](https://www.pbr-book.org/) in the Julia programming language.

# Usage
Example command line usage. See `src/args.jl` for a full specification of command line options.
```
julia -t 4 RayTracing.jl \
--scene-number 2 \
--samples-per-pixel 16 \
--image-dim 250 \
--n-spectral-samples 10 \
--file-name "test.png"
```

# Scene Specification
Scenes are specified within `src/scene_builder.jl`.

Hierarchy of objects needed is as follows. 
```
Render
├── Integrator
│   ├── Camera
│   └── Sampler
│       └── Film
└── Scene
    ├── Vector{Light}
    └── AccelerationStructure
        └── Vector{Primitive} = Vector{Tuple{Shape, Material}}
```

# Example Renders
1. Office scene. Interior scene. many (relative) diffuse area lights. specular floor. 

    ![office_scene](https://github.com/JohnBatmanMySlinky/PBRJ/blob/main/renders/munich-scene.png?raw=true)

2. Caustic glass

    ![caustic_glass](https://github.com/JohnBatmanMySlinky/PBRJ/blob/main/renders/caustic-glass.png?raw=true)
    
3. Dragon on a plane with Ambient Occlusion integrator

    ![dragon](https://github.com/JohnBatmanMySlinky/PBRJ/blob/main/renders/dragon.png?raw=true)

4. Cornell Box

    ![cornell_box](https://github.com/JohnBatmanMySlinky/PBRJ/blob/main/renders/cornell-box.png?raw=true)

4. Metaballs

    ![metaballs](https://github.com/JohnBatmanMySlinky/PBRJ/blob/main/renders/metaballs.png?raw=true)

5. Julia logo but with teapots

    ![julia_logo](https://github.com/JohnBatmanMySlinky/PBRJ/blob/main/renders/julia-logo.png?raw=true)
        

# Features Implemented
- BVH accelerator
- Perspective camera
- Edge-avoiding a-trous denoising
- BDPT, ambient occlusion, path & whitted integrators
- Area, distant, infinite, point, and spot lights
- Glass, matte, metal, mirror, plastic, and substrate materials
- Stratified sampling
- Box, cylindar, disk, rectangle, sphere, and triangle shapes
- Very basic L-systrem
- Implicit surfaces: Goursat surface & metaballs
- RGB & spectral rendering
- Constant, image, mixed, procedural and mixed textures
- Logging

# TODO's
- Validate 100% aginst PBR for a single scene
    - Document what is needed to get that level of validation
    - Suffer thru MISWeight & image writing
- Tidy up implicit Surfaces
- Displaced sphere looks cool [link](https://math.stackexchange.com/questions/1071662/surface-normal-to-point-on-displaced-sphere)
- Add mediums
- Add bi-linear patches
- ~~sampling over the solid angle~~
- Implement light BVH for more efficient sampling
- Use y(::Spectrum) and dont hack with mean
- Build in rendering passes natively
    - don't just use 1 spp for rendering passes
- Julia 1.9 has native support for Float16, a 4x speed up would be very nice albeit at some cost.
- ~~use inplace operations where possible ie `normalize!()` vs `normalize`~~
- Make sure I am sampling purley over the solid angle
- Implement Metroplois Light Transport Integrator
- Implement texture sampling and use those ray differentials
- ~~Liberal use of `const` in all mutable structs~~
- `Scene` uses a vector of (abstract) lights. would a tuple of lights be better? Could I use a macro to generate scene specific struct?
- ~~Move to EXR~~
    - ~~for env lights~~
    - ~~for final image~~
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

# Bugs
- My world is upside down! Use real pbrt to debug (or pxl-th's)
- Sometimes objects are see through (ie when they have a really bright light behind them)

# Ideas
- ~~Triangles using UInt16 when small enough?~~ I get a very small pay off when I did a quick test.
- ~~can I make rays immutable and re-instantiate when mutation is needed?~~ No performance boost observed.

# Beyond PBRT
- Denoiser. Opportunity for ML here?

# Sources
- Based on [Physically Based Rendering: From Theory to Implementation by Matt Pharr, Wenzel Jakob, and Greg Humphreys](https://www.pbr-book.org/).
- [This implementation of PBRT in Julia](https://github.com/pxl-th/Trace.jl) repo has been an invaluable reference.
- [3dtextures.com](https://3dtextures.me/2021/12/15/stone-floor-006/) Has some wonderful free texture maps.

# Notes
## Metaball learnings
- To start, I want to talk about **Functions**. The function $f(x,y,z) = x^2 + y^2 + z^2$ takes in 3 numbers, $x, y, z$ and returns one number. Since I am only really interested in 3D rendering, let's equate these three numbers to a single point in space. Swithing to points let's re-write $f(p) = p_x^2 + p_y^2 + p_z^2$. Now the intuition is that for any point in 3D space, this function returns a single number. For instance at the origin $(0,0,0)$ this function returns $0$ and for any other point it returns the distance from the origin.
- Functions are nice, but we want to render Shapes, aka Surfaces. One way to think about Surfaces, is as a collection of specific points (very 3D rendering view of the world here...). Functions return an unconstrained collection of points, where Surfaces are a collection of specific points. The trick to go from Functions to Surfaces is thresholding aka root finding. With our previous example, let's find the collection of points that is the solution to $f(p) = 0.5$ (0.5 being the threshold here). In this particular example the collection of points that is the solution to our constrained function is a sphere! I also like the note that this setup gives us a very easy check to determine if a point is in fact on the surface, but gives us zilch in terms of programmatic ways of finding those points that make up the surface.
- I really like the following images because they made the idea that thresholding a continuous function turns it into a surface. 
    - http://www.geisswerks.com/ryan/BLOBS/blobs.html

- Let's introduce the Ray. Our ray is specified by an Origin and a Direction and when we give our Ray a time $t$, it will return a point. We will write $r(t) = o + t*d = p$ or equivalently and verbosely $p_x = o_x + t * d_x, \quad p_y = o_y + t * d_y, \quad p_z = o_z + t * d_z$. At the core of RayTracing, we shoot rays from our camera into a 3D world, find stuff they intersect with and evaluate the lighting at that 3D point. So we need to figure out where, in 3D space, our Ray will intersect our Surface. Turns out this is pretty easy and a univariate problem. If we have $r(t) = p$ and $f(p)=0.5$ then our problem is to find $f(r(t))=0.5$, again more verbosely, $(o_x + t*d_x)^2 + (o_y + t*d_y)^2 + (o_z + t*d_z)^2 = 0.5$ with our one unknown $t$. 
    - I liked how this paper drove home why it is a single variable problem: https://graphicsinterface.org/wp-content/uploads/gi1990-8.pdf.
    - PBRT was also helpful here.
- Now it turns out that for this example we can find a closed form solution to the above problem, since it is quadratic. But what happens if our $f(p)$ ain't so nice? Well the problem is the same, find solutions to the equality, but we will have to use more general root finding algorithms.

- In comes the MetaBall. 
    - Definitions to start (because notation is hard.)
        - $||\bm{p}||$ represents the **norm** of that point. Component wise, this looks like $\sqrt{p_x^2 + p_y^2 + p_z^2}$. It's *like* a distance.
    - https://people.computing.clemson.edu/~dhouse/courses/405/notes/implicit-parametric.pdf
    - How to parameterize a metaball? 
        - Wyvill and Wyvill 1989a  use the following formulation
            - $f_i(r_i) = -\frac{4}{9} * (\frac{r_i}{R})^6 + \frac{17}{9}*(\frac{r_i}{R})^4 - \frac{22}{9}*(\frac{r_i}{R})^2$ if $r_i \leq R $ else $f_i(r_i)=0$
            - $F(r(t))=\sum{f_i(||r(t)-k_i||)}^n_{i=1}-\text{magic}=0$
            - Where there are $n$ key points $k_i$ in space (so 3D points) that parameterize the meta ball, think of these as the origins of the Balls.
            - R is also a parameter that does something...
        - For me, trying to visualize this hurts my brain. The sphere I can do, it is like a point light at the origin and it glows, and the glowing fades uniformly in 3D with space. But wtf is this?
        - The lovely part is that it doesn't matter wtf this is. Just shoot some rays, see if they intersect and if they do calculate a normal then on to the next. Stop over thinking it. For now. 


    - Normals
        - normals can be empirically approximated using this black magic: http://rodolphe-vaillant.fr/entry/87/normal-to-an-implicit-surface
        - though I suppose this is pretty easily derived by hand in this case. 

- How to fit into PBRT.
    - Easy (if we assume they cannot be emmissive). We only need the two following methods.
        - Intersect (+ IntersectP)
        - ObjectBounds
    - Intersect is also made easy if we assume that they surface will not be UV textured. Because our surface interaction really just needs p, t, n at it's core (pun intended)
    - The actual ray object intersection is the fun part. 
- Ray object intersection
    - Naive algorithm. Use a generic Solver library to calculate at what t, our ray will intersect the surface of the metaball. This is a pretty straightforward single variable root finding problem.
    - My first catch was that using that generic Solvier library wasn't so easy. 
    - I needed to define bounds in which the ray intersection could exist. My initial heuristic to get an upper bound on my solution space by looking at my world radius and using a mean magnitude of the ray distance vector. Lower bound of $t=0.0$
    - Apparently, this wasn't good enough. My root solver wasn't good enough and frequently wouldn't converge.
    - It was a real pain to diagnose this issue. My root solver is a 3rd party black box and it's not like I know which rays should intersect. I eventually logged all my rays, their intersection and validated some manually until I realized that sometimes (read; often) would have a ray that didn't intersect that my manual calculations indicate it should have.
    - Second move was to calculate a bounding sphere of our metaball, re-use sphere intersection code and use the solutions to the bounding sphere-ray intersection as bounds for the root solve.
    - Now i have something that 'works' enough that I can do some test renders
        - IMAGE HERE
    - my guess is that is going to be slow because intersection grows linearly with # of balls. yeah so I was right...
        - `julia -t 4 RayTracing.jl --scene-number 5 --samples-per-pixel 4 --image-dim 150` on my personal mac not plugged in (if that matters)
        - 1: 13s
        - 9: 23s
        - 49: 33s
        - 100: 42s
        - 484: 100s
    - Let's use the idea that some balls are far away and will never influence the f(). Extreme example
        - IMAGE HERE: balls in a line from left to right
        - if I hit the right most ball only, I still must evaluate f() at every key point. Lame.
    - first BVH idea
        - I think the idea is to figure out the subset of key points which are **active** and only evaluate f() for that active subset. 
        - create BVH of balls (AABB for each key point & it's R_i)
        - shoot ray all the way through the BVH until you don't hit any more balls. 
        - every ball that is hit, could be active
            - we can prune at the end. we will see the closest hit and then can remove balls too far away
        - with active balls, go about your normal business
        - Results:
            - horrendously slow! 10x slower than my naive approach! What???
            - So what I realized is that in f() isn't THAT inefficient, the norm() < R essentially just finds the active balls and compared to the whole BVH stuff, the norm() < R is apparently pretty good!
                - The other thing, my test of generating many spheres in a tight space, is biased against BVH. It isn't realistic to have so many overlapping metaballs and results in excess BVH traversals. 
                - BVH results look less bad when I use a grid of balls instead of a random smattering. 
            - So then why does that ray tracing gems article have a BVH?
                - anisotropy! if you want non-spherical balls, you can't use norm() < R!!!! so then how do you find active balls? BVH is how. 
                - or can you get away with norm() < R ... ???
            - Thoughts to improve BVH
                - within intersect!(bvh): don't intersect spheres, just return leaf's whose AABB are hit and t
                - MB intersect will collect leafs and t's
                - this will include more spheres in activeset when hit aabb but not bounding sphere BUT save lots of traversal time?
    - second BVH idea 
        - ray tracing gems 2 approach with inner and outer bounding spheres

### Metaballs TODO
- Test out how bad this scales
- break out balls into their own shapes with key point level parameters then have MetaBalls be a container of Balls
- meta ball BVH
- Blending materials and colors
- ellipsoid balls
- negative balls
