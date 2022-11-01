# PBRJ
Physically Based Rendering - in Julia

# Sources
- Based on [Physically Based Rendering: From Theory to Implementation by Matt Pharr, Wenzel Jakob, and Greg Humphreys](https://www.pbr-book.org/).
- [This implementation of PBRT in Julia](https://github.com/pxl-th/Trace.jl) repo has been an invaluable reference.
- [3dtextures.com](https://3dtextures.me/2021/12/15/stone-floor-006/) Has some wonderful free texture maps.

# Todo list
- Implement float texture.
- Add in uber material.
- Add tests. 
- Improve scene geometry & lighting.
- Fix sampling. I think my shuffle in stratified sampler removes benefit of the stratification.
- Improve scene specification interface.
- Optimize code base.
- Clean up code base, use more '.x' and less '[1]'
- Quantify benefit of multi-threading.
- Make CLI.