# PBRJ
Physically Based Rendering - in Julia


# Sources
- Based on [Physically Based Rendering: From Theory to Implementation by Matt Pharr, Wenzel Jakob, and Greg Humphreys](https://www.pbr-book.org/)
- [THIS](https://github.com/pxl-th/Trace.jl) repo has been an invaluable reference.
- Wonderful texture maps from [LINK](https://3dtextures.me/2021/12/15/stone-floor-006/)

## PBR Book Overview 
1) Introduction
2) Geometry and Transformations
    2.1) Coordinate Systems --> some transformations left
3) Shapes
    3.3) Cylindars
    3.4) Disks
    3.5) Other Quadrics
    3.7) Curves
    3.8) Subdivision Surfaces
    3.9) Rounding Error
4) Primitives and Intersection Acceleration
    4.3) BVH --> SAH and other optimizations
    4.4) Kd-Tree Accelerator
5) Color & Radiometry
6) Camera Models
    6.3) Environment Camera
    6.4) Realistic Cameras
7) Sampling and Reconstruction
    7.4) The Halton Sampler
    7.5) (0,2)-Sequence Sampler
    7.6) Maximized Minimal Distance Sampler
    7.7) Sobol' Sampler
    7.8) Image Reconstruction --> more filters
8) Reflection Models
    8.4) Microfacet Models
    8.5) Fresnel Incidence BSDFs
    8.6) Fourier Basis BSDFs
9) Materials
    9.x) More materials from github
10) Texture
    10.x) all but constant texture
11) Volume Scattering
    11.x) all
12) Light Sources
    12.1) Light Emission --> blackbody
    12.3) Point Lights --> spotlights, texture projection lights, goniophotometric
    12.4) Distant Lights
13) Monte Carlo Integration
14) Light Transport I: Surface Reflection
15) Light Transport II: Volume Rendering
16) Light Transport III: Bidirectional Methods 


## TODO
- WHAT IS GOING ON WITH LOOKAT TRANSFORM. 
- I kludged the  shuffling in stratified sampling a bit.

