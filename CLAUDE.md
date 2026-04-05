# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

PBRJ is a physically based ray tracer implemented in Julia, based on *Physically Based Rendering: From Theory to Implementation* (3rd edition, with some 4th edition elements). It renders scenes to `.exr` files using multithreaded tile-based rendering.

## Running the Renderer

```bash
# Basic render with multithreading
julia -t 4 src/RayTracing.jl --scene-number 4 --samples-per-pixel 16 --image-dim 250 250 --file-name "output.exr"

# Use all available threads (recommended)
julia -t auto src/RayTracing.jl --scene-number 4 --samples-per-pixel 16 --image-dim 500 500 --file-name "output.exr"

# Prevent sleep on long renders (macOS)
caffeinate -di julia -t auto src/RayTracing.jl --scene-number 14 --image-dim 640 360 --samples-per-pixel 16 --file-name "output.exr"

# Debug a specific pixel region (crop-window is 0–1 normalized)
julia -t 4 src/RayTracing.jl --scene-number 4 --samples-per-pixel 1 --jitter false --image-dim 250 --crop-window 0.964 0.452 0.965 0.453 --debug true

# With profiling
julia -t auto src/RayTracing.jl --scene-number 4 --samples-per-pixel 16 --profile-output profiling.txt
```

Key CLI args (see `src/args.jl` for full spec):
- `--scene-number`: integer scene ID (see `src/scenes/scene_builder.jl` for catalog)
- `--samples-per-pixel`: default 16
- `--image-dim`: width height (default 250 250)
- `--n-spectral-samples`: 3 = RGB mode, >3 = spectral mode
- `--sampler`: `independent`, `stratified`, `sobol`, `zsobol` (default: `zsobol`)
- `--max-depth`: max ray bounces (default 6)
- `--light-distribution-strategy`: `uniform`, `power`, `spatial`
- `--seed`: random seed for reproducibility
- `--debug`: enables file logging to `log_<timestamp>.txt`

## Running Tests

Tests must be run from the `test/` directory because they reference `.pbrt` files by relative path:

```bash
cd test && julia unit_tests.jl
```

The test file includes a `jmfp()` helper that translates absolute paths between macOS (`/Users/johnmyslinski`) and Linux (`/home/jmyslinski`) environments.

## NanoVDB Setup

Required for scenes using NanoVDB mediums (scenes 13, 19, 20):
```bash
cd src/nanovdb && sh INSTALL.sh
```

## Architecture

### Entry Point & Module Structure

All code lives in the `RayTracing` Julia module (`src/RayTracing.jl`). This file:
1. Declares all abstract types upfront
2. Defines global constants (`nSpectralSamples`, `ShadowEpsilon`, etc.)
3. Parses command-line args early (needed to configure the `Spectrum` type at compile time via `@make_spectrum` macro)
4. `include()`s every source file in dependency order

The `Spectrum` type is parameterized at module load time: if `--n-spectral-samples 3`, it's RGB; otherwise it's a fixed-size spectral array. This is set via the `@make_spectrum` macro in `src/spectrum/spectrum_macro.jl`.

### Rendering Pipeline

`render_scene()` → `build_scene()` (scene-specific) → `render()` (integrator dispatch) → tile-based `Threads.@threads` loop → `Li()` per ray.

Scene construction (in `src/scenes/scene_builder.jl`) dispatches to `src/scenes/scene<N>.jl` files. Each scene builds: primitives (shapes + materials), lights, BVH, film, camera, sampler, and integrator.

### Core Type Hierarchy

All core geometric types (`Vec3`, `Pnt3`, `Nml3`, `Pnt2`, etc.) are defined in `src/objects.jl` using `StaticArrays.FieldVector`. Transformations are in `src/transformations.jl`.

Abstract types (declared in `RayTracing.jl`):
- `Shape` → sphere, triangle, rectangle, box, disk, cylinder, SDFs, implicit surfaces
- `Material` → matte, glass, metal, mirror, plastic, substrate, fourier, subsurface
- `AbstractBxDF` → lambertian, specular, microfacet, oren-nayar, hair, fourier, BSSRDF
- `Light` → area, point, spot, distant, image infinite, uniform infinite
- `AbstractIntegrator` → `AOIntegrator`, `SimpleIntegrator`, `SimpleVolPathIntegratorv4`, `VolPathIntegratorv3`, `BDPTIntegrator`
- `AbstractSampler` → stratified, independent, sobol, zsobol, LCG, deterministic
- `AbstractMedium` → homogenous, grid, NanoVDB, cloud
- `Camera` → `PerspectiveCamera`
- `BVHAccel` → two implementations: naive (`bvh_naive.jl`) and optimized (`bvh_pbr_pxlth.jl`)

### Key Data Flow

`Primitive` wraps a `Shape` + `Material` + medium interface (`MediumInterface`). `Scene` holds a `BVHAccel` over primitives and a list of `Light`s. The integrator holds a `Camera` and `AbstractSampler`.

`ShapeCore` carries `object_to_world` / `world_to_object` transformations and `reverse_orientation` flag. Shapes compose a `ShapeCore` rather than inheriting it.

### Participating Media

The `medium2/` directory contains the v4-style medium implementation:
- `SampledGrid` for volumetric data
- `DDAMajorantIterator` for null-scattering delta tracking
- Grid medium reads from `.pbrt` density files; NanoVDB reads `.nvdb` files

### Materials & BSDF

`src/materials/registry.jl` defines `MaterialRegistry` (global `MATERIAL_REGISTRY`). The BSDF pattern: `Material.compute_scattering_functions()` creates a `BSDF` with up to 8 `AbstractBxDF` components. `src/reflection/` contains all BxDF implementations.

`AlphaTextureRegistry` (global `ALPHA_TEXTURE_REGISTRY`) manages alpha masking textures.

### Scene Files

`src/scenes/scene_builder.jl` is the catalog — check it for render commands and status of each scene (✅ working, 🟨 known issues, 🔴 broken).

Scenes 1–21 are self-contained. Scenes 99–112 are numbered experiments. Some scenes require external `.pbrt` geometry files under `ref/` or `scenes/poof/`.

### Profiling

Use `--profile-output <file>` with `--profile-on`. The `@prof "label" expr` macro instruments code sections (single-threaded only — errors if `nthreads() > 1`).

### Transform Gotcha

PBRT applies transforms right-to-left in scene files but the equivalent Julia code is left-to-right multiplication:
```
Scale -1 1 1; LookAt ...   →   camera_transform = LookAt(...) * Scale(-1,1,1)
TransformBegin Translate; Rotate; ...  →  t = Translate(...) * Rotate(...)
```

### Film Output

All renders output `.exr` format via `OpenEXR.jl`. The `PassFilm` variant saves 5 separate EXR passes (for denoising). The edge-avoiding à-trous denoiser is in `src/denoising/`.
