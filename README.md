# PBRJ
Physically Based Rendering - in Julia


# Sources
- Based on [Physically Based Rendering: From Theory to Implementation by Matt Pharr, Wenzel Jakob, and Greg Humphreys](https://www.pbr-book.org/)
- [THIS](https://github.com/pxl-th/Trace.jl) repo has been an invaluable reference.


## BVH Notes
- Using my own naive implementation because I am too lazy to understand the one in PBR right now. I am paying for this though, my tree construction is pretty slow. 1,000,000 random spheres within a 3d box takes about 70 seconds to construct, but only takes ~0.00005 seconds to intersect. I suppose that is the magic of BVH though...