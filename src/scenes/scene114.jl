const GOLDEN_ANGLE = 137.50776405003785

# Oklab <-> linear sRGB, via Björn Ottosson's reference matrices
# (https://bottosson.github.io/posts/oklab/). Implemented manually instead of
# relying on Colors.jl's Oklab/Oklch conversion methods, since those aren't
# present in every installed version of Colors.jl/ColorTypes.jl.
function oklab_to_linear_srgb(L::Float64, a::Float64, b::Float64)
    l_ = L + 0.3963377774 * a + 0.2158037573 * b
    m_ = L - 0.1055613458 * a - 0.0638541728 * b
    s_ = L - 0.0894841775 * a - 1.2914855480 * b

    l = l_^3
    m = m_^3
    s = s_^3

    r = 4.0767416621*l - 3.3077115913*m + 0.2309699292*s
    g = -1.2684380046*l + 2.6097574011*m - 0.3413193965*s
    bl = -0.0041960863*l - 0.7034186147*m + 1.7076147010*s
    return (r, g, bl)
end

# Linear -> gamma-encoded sRGB channel
linear_to_srgb(c::Float64) =
    (c = clamp(c, 0.0, 1.0); c <= 0.0031308 ? 12.92 * c : 1.055 * c^(1/2.4) - 0.055)

# Final (L,a,b) -> displayable Colors.RGB, clamped to the sRGB gamut
function oklab_to_rgb(L::Float64, a::Float64, b::Float64)
    r_lin, g_lin, b_lin = oklab_to_linear_srgb(L, a, b)
    return Colors.RGB(linear_to_srgb(r_lin), linear_to_srgb(g_lin), linear_to_srgb(b_lin))
end

# Generates n jewel-tone colors as Oklab (L,a,b) tuples, hues spread via the
# golden angle so they don't randomly clump together.
function jewel_palette(n::Int; l::Float64=0.55, c::Float64=0.15, hue0::Float64=rand() * 360.0)
    hue = hue0
    colors = Vector{NTuple{3,Float64}}(undef, n)
    for i in 1:n
        colors[i] = (l, c * cosd(hue), c * sind(hue))  # (L, a, b)
        hue = mod(hue + GOLDEN_ANGLE, 360.0)
    end
    return colors
end

# Blends Oklab `colors` at normalized position (u,v) based on proximity to
# each of `points`. `sigma` controls patch size/sharpness: smaller -> tighter,
# more distinct color islands; larger -> smoother gradient.
function blend_color_by_proximity(
    u::Float64, v::Float64,
    points::Vector{Tuple{Float64,Float64}},
    colors::Vector{NTuple{3,Float64}};
    sigma::Float64=0.15,
)
    weights = [exp(-((u - px)^2 + (v - py)^2) / (2 * sigma^2)) for (px, py) in points]
    wsum = sum(weights)

    if wsum < 1e-12
        nearest = argmin([(u - px)^2 + (v - py)^2 for (px, py) in points])
        L, a, b = colors[nearest]
        return oklab_to_rgb(L, a, b)
    end

    weights ./= wsum
    L = sum(w * col[1] for (w, col) in zip(weights, colors))
    a = sum(w * col[2] for (w, col) in zip(weights, colors))
    b = sum(w * col[3] for (w, col) in zip(weights, colors))
    return oklab_to_rgb(L, a, b)
end

function make_scene114(parsed_args::Dict)::Tuple{AbstractIntegrator, Scene}
    primitives = Primitive[]
    lights = Light[]
    materials = Material[]

    WORLD_MAX = 100.0
    WORLD_MIN = -100.0
    N_BOXES = 150.0

    box_size = (WORLD_MAX - WORLD_MIN) / N_BOXES

    N_JEWEL_POINTS = 35
    PROXIMITY_SIGMA = 0.15  # tune: smaller = sharper color islands, larger = smoother blend

    jewel_points = [(rand(), rand()) for _ in 1:N_JEWEL_POINTS]
    jewel_colors = jewel_palette(N_JEWEL_POINTS)

    for x in 0:N_BOXES-1
        for y in 0:N_BOXES-1
            wx = WORLD_MIN + x * box_size
            wy = WORLD_MIN + y * box_size

            noise_1_eval_scale = 0.03
            noise_1_eval_p = (Pnt3(wx, 0.0, wy) .+ 0.5) .* noise_1_eval_scale
            noise_1_eval = noise(noise_1_eval_p)
            noise_1_eval = clamp((noise_1_eval+1.0)/2.0, 0.0, 1.0)

            u = (wx - WORLD_MIN) / (WORLD_MAX - WORLD_MIN)
            v = (wy - WORLD_MIN) / (WORLD_MAX - WORLD_MIN)
            box_color = blend_color_by_proximity(u, v, jewel_points, jewel_colors; sigma=PROXIMITY_SIGMA)

            mat_tmp = Matte(
                "mat_$(x)_$(y)",
                ConstantTexture(spectrum_from_float(Colors.red(box_color), Colors.green(box_color), Colors.blue(box_color))),
                ConstantTexture(0.0),
                nothing
            )
            push!(materials, mat_tmp)

            base_height = noise_1_eval^3 * 30.0
            bright_bonus_1 = rand() < noise_1_eval   ? noise_1_eval^3 * 5.0 : 0.0
            bright_bonus_2 = rand() < noise_1_eval^3 ?                  8.0 : 0.0
            box_height = base_height + bright_bonus_1 + bright_bonus_2


            box_t = Translate(Pnt3(wx, 0, wy))
            box = Box(
                Pnt3(0.0, 0.0, 0.0),
                Pnt3(box_size, box_height, box_size),
                ShapeCore(box_t, Inv(box_t), false, false),
                nothing
            )
            for tri in box
                push!(primitives, Primitive(tri, "mat_$(x)_$(y)", nothing))
            end
        end
    end

    name_index = Dict(mat.name => i for (i, mat) in enumerate(materials))
    MATERIAL_REGISTRY[] = MaterialRegistry(materials, name_index)

    print("\nThere are " * num2str(length(primitives)) * " objects in the scene, building BVH\n")
    @time bvh = BVH(primitives)
    print("Done building BVH\n")

    l_2_w = RotateX(10.0)
    light = InfiniteLight(
        world_bounds(bvh), 
        l_2_w, 
        spectrum_from_float(4.0, Illuminant), 
        jmfp("/Users/johnmyslinski/Documents/pbrt-v4-scenes/bunny-cloud/textures/sky.exr"),
        true
    )
    push!(lights, light)


    filter = BoxFilter(Pnt2(.5, .5))

    film = Film(
        Pnt2i(parsed_args["image-dim"][1], parsed_args["image-dim"][2]),
        Bounds2(Pnt2(parsed_args["crop-window"][1], parsed_args["crop-window"][2]), Pnt2(parsed_args["crop-window"][3], parsed_args["crop-window"][4])),
        filter,
        1.0,
        1.0,
        parsed_args["file-name"]
    )

    look_from = Pnt3(60.0, 30.0, -80.0)
    look_at = Pnt3(0.0, 0.0, 0.0)
    up = Vec3(0, 1, 0)
    C = PerspectiveCamera(LookAt(look_from, look_at, up), nothing, 0.0, 1.0, 0.0, 1e6, 37.0, film)

    S = SamplerFactory(parsed_args)
    print("Using " * num2str(S.samples_per_pixel) * " samples per pixel\n")

    print("There are " * num2str(length(lights)) * " lights in the scene\n")
    scene = Scene(lights, bvh)

    integrator_arg = parsed_args["integrator"]
    if integrator_arg == "default"
        I = VolPathIntegratorv3(C, S, parsed_args["max-depth"])
    elseif integrator_arg == "bdpt"
        I = BDPTIntegrator(C, S, parsed_args["max-depth"])
    elseif integrator_arg == "volpath"
        I = VolPathIntegratorv3(C, S, parsed_args["max-depth"])
    elseif integrator_arg == "sppm"
        I = SPPMIntegrator(C, S, C.film, parsed_args["max-depth"], parsed_args["n-iterations"], parsed_args["photons-per-iteration"], 1.0)
    else
        error("Unknown integrator: $(integrator_arg)")
    end

    return I, scene
end