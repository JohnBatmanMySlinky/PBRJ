# What is Ray Tracing?
"3D ray tracing is a computer graphics technique used to **simulate the way light interacts with objects to generate realistic images**. It works by **tracing the path of rays of light** as they travel through a scene. This technique, while computationally intensive, can produce highly realistic images by accurately simulating the intricate play of light in a 3D environment." – GPT-4

<sub>emphasis mine</sub>

# Introduction

I've always been interested in Computer Graphics, I almost went to college to work in 3D Animation and Special FX. I lacked artistic talent, so I balked at the idea of having to take real (studio) art classes. I never thought about approaching the topic from the software side. 

Then about 2 years I read this.

![Alt text](image-9.png)

Then I read this.

![Alt text](image-10.png)

Then I read this.

![Alt text](image-11.png)

Then I read this.

<img src="image-2.png" alt="drawing" width="250"/> 

I have written a photo-realistic ray tracing program from scratch in the Julia programming language, following the C++ code laid out in the book, *Physically Based Rendering: From Theory to Implementation* (PBRT). 2 years and 15k lines of code later...

<img src="image-3.png" alt="drawing" width="250"/>

# Movies vs Games

Raytracing has two main application areas, movies and video games. Same idea, very different problems. 
1) Games: 60 frames per second * (1920 * 1080) pixels per frame * 16 samples per pixel = 1,990,656,000 samples per second = you gotta be fast
2) Movies: "Despite increases in computer power, each Shrek movie has taken about twice as many hours to render as the one before it. Dreamworks call this 'Shrek's Law'". It's all about making it look pretty.


We will be focusing on **movies** from here on out.

# How movies are made

- Story
- Making assets
    - Filming live action
    - 3D: modeling, texturing, lighting, animating, etc
- Rendering 3D assets
- Post processing: Combining live action and 3D assets


# How Ray Tracing works - Physical
Helpful to start with the physical. How do we see stuff?

1) Lights (and the sun) emit photons, they shoot out $ 10^{\text{big number }}$  of photons continuously.
2) These photons hit the physical objects around us.
3) Some photons are absorbed by the objects they hit, other bounce off the objects they hit.
4) Eventually some photons hit our eyeballs.
5) Our brains synthesize these eyeball-photon interactions into an image.

**The bouncing (and absorbtion) of photons is what allows us to percieve the world around us.**

That's the basic model. In computer graphics, Ray Tracing simulates this physical process. Swapping eyes for a model of the camera sensor. 

# Geometry Refresher

Quick geometry refresher: Points, Vectors and Rays

```{julia}
struct Point3
    x::Float64
    y::Float64
    z::Float64
end
struct Vector3
    x::Float64
    y::Float64
    z::Float64
end
struct Ray
    origin::Point3
    direction::Vector3
end
```

# The naive algorithm

ray $ \approx $ photon

- shoot rays out of lights
- model the rays as they bounce around
- model a camera sensor
- eventually some rays will hit the camera sensor and form an image

<details>
<summary><b>Who wants to guess what the bottle neck is here?</b></summary>

Practically all of the rays you shoot out of lights won't hit your camera sensor! How do you fix this?

</details>


# The less naive algorithm - in words

- Simulate it **in reverse**. Shoot rays from your camera! bounce them around, figure out which hit lights, estimate how much light is traveling along that path. 
- Kinda hurts your brain at first. But if you can probabalistically model light --> floor --> camera sensor you can mathematically prove you can also go camera sensor --> floor --> light.
- Another way to frame this problem, which hints at some of the difficulty, is that we are integrating an infinite dimension integral.

<img src="image-1.png" alt="drawing" width="250"/>

# The less naive algorithm - in code

Ok let us proceed
```{julia}
# this sketch is based on the Path Tracing Light Transport Algorithm
# this was the first general-purpose unbiased Monte Carlo light transport algorithm used in graphics. Introduced in 1986.
function render!(output_image, pixels, scene_geometry)
    for pixel in pixels
        L_hat = 0 # L for Luminance
        for sample in 1:n_samples
            L = 0
            depth = 0
            ray = shoot_ray_from_camera()
            while depth < max_depth # ~ 6
                hit_information, hit_something = intersect(ray, scene_geometry)

                if hit_something
                    L += calculate_light_influence(hit_information, scene_geometry)

                    ray = bounce(ray, hit_information)
                
                    depth += 1
                else 
                    # implying we hit nothing and the ray shoots off into space
                    break
                end
            end
            L_hat += L
        end
        L_hat /= n_samples
        save_pixel_to_image!(output_image, L_hat, pixel)
    end
end
```


# My experiences writing this program
- `intersect()` is easy to do slowly, hard to do it efficiently.
- I am hand waving away a lot of math inside `calculate_light_influence()`.
- Perfectly reflective surfaces create some sharp corners in our code.
- Fundamentally, this algorithm is still very inefficient.
- Parallelism is actually ez pz.
- Effecient sampling isn't trivial. rand() ain't good enough.
- Debugging is really really really really hard. Thankfully both mine and the book's implementations are deterministic and I can validate directly.
- Fun stuff like optimizing AABB-Ray intersection tests increased performance of whole scene rendering by 15%.
    - Not repeating divisions and an early break or two had huge impacts!
- PBRT's code basis's APIs are really nice, so adding stuff like new procedural shapes is pretty easy.
- Julia is amazing. 10/10 would recommend. Not C++ fast though :( ...
- I learned some C++

# `intersect()` - The Math
ray-sphere intersection: let's calculate the point in 3d space where a ray intersects a sphere.
        $$ \text{ray}: r(t) = \textbf{o} + \textbf{d} * t  = \text{Point3}$$
        $$ \text{sphere at the origin}: \textbf{x}^2+\textbf{y}^2+\textbf{z}^2-r^2=0 $$
with some substitution and expansion we get...
        $$ (o_x + td_x)^2 + (o_y + td_y)^2 + (o_z+ td_z)^2 = r^2$$
all variales sans, $t$ are known here. So we can again expand and gather the coeffecients for a general quadratic equation in $t$

$$ at^2 + bt + c = 0 $$
$$ a = d_x^2 + d_y^2 + d_z^2 $$ 
$$ b = 2(d_x o_x + d_y o_y + d_z o_z) $$
$$ c = o_x^2 + o_y^2 + o_z^2 - r^2 $$

solve for $t$, plug it back into 

$$ \text{ray}: r(t) = \textbf{o} + \textbf{d} * t  = \text{Point3}$$

to get your intersection point

**tl;dr finding the point where a ray and a sphere intersect is really easy.**

# `intersect()` - The Problem

OK so what if your scene had 1,000,000 spheres? Check each sphere to see which your ray hit?

```
for pixel in 1:8_000_000 # ~8M pixels in 4k image
    for sample in 1:1_000 # typically we average 1,000s of rays per pixel
        while depth < 6
            for sphere in 1:1_000_000 # figure out which sphere is hit
                "uh oh"
```

# `intersect()` - Data structures to the rescue
![Alt text](image.png)

**Bounding Volume Hierarchy**
- for each shape, construct a bounding box
- leaf node: a sphere
- interior node: a union of bounding boxes

Construction is not trivial. But when done correctly, it's *fast*.

# All of the major *classes* involved
1) **Shape**: geometry by which your scene is constructed. (Triangles)
2) **Accelerators**: data structures to aid in ray-shape intersections. (Bounding Volume Hierarchy)
3) **Cameras**: various camera models from simplistic to full realistic models.
4) **Samplers**: responsible for generating well distributed high dimension random numbers.
5) **Filters**: signal processing components responsible for aggregating pixel estimates.
6) **Materials**: responsible for defining how light bounces.
7) **Textures**: responsible for coloring shapes.
8) **Media**: represent the fact that we dont live in a vacuum.
9) **Lights**: define how light is emitted.
10) **Integrators**: house the core rending algorithms.


# Images I made

- Interior Scene: Designed by hand in code.

![Alt text](image-6.png)

- Refractive Glass

![Alt text](image-4.png)

- Dragon with >1M triangles

![Alt text](image-5.png)

- Cornell Box (a classic)

![Alt text](image-7.png)

- Metaballs (a new shape I added)

![Alt text](image-8.png)

- Julia logo but with teapots

![Alt text](image-12.png)
<img src="image-3.png" alt="drawing" width="250"/>

# How do you define a scene?

```{julia}
primitives = Primitive[]
lights = Light[]

#################
### MATERIALS ###
#################
mat_gray = Matte(
    ConstantTexture(Vec3(.4, .4, .4)),
    ConstantTexture(Vec3(0, 0, 0)),
    nothing
)

mat_white = Matte(
    ConstantTexture(Vec3(1, 1, 1)),
    ConstantTexture(Vec3(0, 0, 0)),
    nothing
)

########################
### OBJECTS & LIGHTS ###
########################

dragon_translate = RotateZ(-135.0)
dragon = parse_obj(
    "../ref/dragon1.obj",
    dragon_translate,
    false,
    false,
    nothing
)

for tri in dragon
    push!(primitives, Primitive(tri, mat_gray, nothing))
end

floor_transform = Translate(Pnt3(0,-40,0))
floor = Rectangle(
    Pnt2(-300, -300), 
    Pnt2(300, 300), 
    0.0,
    2, 
    ShapeCore(floor_transform, Inv(floor_transform), false, false),
    false,
    nothing
)
for tri in floor
    push!(primitives, Primitive(tri, mat_gray, nothing))
end

alight_transform = Translate(Pnt3(0,-40,0))
alight = Rectangle(
    Pnt2(-100, -100), 
    Pnt2(-100, 100), 
    150.0,
    2, 
    ShapeCore(alight_transform, Inv(alight_transform), false, false),
    true,
    nothing
)
for tri in alight
    tmp = DiffuseAreaLight(
        spectrum_from_float(5.0, 5.0, 5.0),
        tri,
        false # NOT two sided
    )
    push!(lights,tmp)
    push!(primitives, Primitive(tri, mat_white, tmp))
end

####################
### ACCELERATORS ###
####################
print("\nThere are " * num2str(length(primitives)) * " objects in the scene, building BVH\n")
@time bvh = BVH(primitives)
print("Done building BVH\n")

##############
### FILTER ###
##############
filter = BoxFilter(Pnt2(.25, .25))

############
### FILM ###
############
film = Film(
    Pnt2(parsed_args["image-dim"], parsed_args["image-dim"]),
    Bounds2(Pnt2(0,0), Pnt2(1,1)),
    filter,
    1.0,
    1.0,
    parsed_args["file-name"]
)

##############
### CAMERA ###
##############
look_from = Pnt3(200, 200, 200)
look_at = Pnt3(-35, 0, -35)
up = Vec3(0, -1, 0)
screen = Bounds2(Pnt2(-1, -1), Pnt2(1, 1))
C = PerspectiveCamera(LookAt(look_from, look_at, up), screen, 0.0, 1.0, 0.0, 1e6, 65.0, film)

###############
### SAMPLER ###
###############
S = StratifiedSampler(parsed_args["samples-per-pixel"], true)
print("Using " * num2str(S.samples_per_pixel) * " samples per pixel\n")

#############
### SCENE ###
#############
print("There are " * num2str(length(lights)) * " lights in the scene\n")
scene = Scene(lights, bvh)

###################
### INTEGTRATOR ###
###################
I = AOIntegrator(C, S, true)
return I, scene
```

# What is Next

- Definitely some bug causing fireflies (when you divide by *almost zero* you get a big number and that throws off your Luminance estimate.)
- Sampling over the solid angle for triangles
- More implicit surfaces: Goursat Surface
- L-systems
- Better generation of (pseudo) random numbers
- Better de-noising algorithms
- Metropolis Light Transport Integrator
- Light BVH
- Implement fourier material
- Participating mediums
- Subsurface scattering