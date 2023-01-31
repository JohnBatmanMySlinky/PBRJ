# PBR 16.3 Bi-Directional Path Tracing
struct BDPTIntegrator <: AbstractIntegrator
    camera::C where C <: Camera
    sampler::S where S <: AbstractSampler
    max_depth::Int64
end

function render(i::BDPTIntegrator, scene::Scene, minimal::Bool=false)
    # create light sampling light_distribution
    # JOHN HACK --> hard coding uniform dist
    light_distr_generator = LightDistribution("uniform", scene)

    # partition the image into tiles
    sample_bounds = get_sample_bounds(i.camera.core.core.film)
    sample_extent = diagonal(sample_bounds)
    tile_size = 16
    width, height = Int64.(floor.((sample_extent .+ tile_size) ./ tile_size))
    total_tiles = width * height - 1
    print("Rendering " * num2str(total_tiles + 1) * " tiles\n")

    # progress stuff
    prog = Progress(total_tiles)
    update!(prog,0)
    jj = Threads.Atomic{Int}(0)
    l = Threads.SpinLock()

    print("Utilizing $(Threads.nthreads()) threads\n")
    # the multi-threaded loop
    Threads.@threads for k in 0:total_tiles
        # Render a single tile using BDPT
        x, y = k % width, k ÷ width
        tile = Pnt2(x, y)
        tile_sampler = deepcopy(i.sampler)

        tb_min = sample_bounds.pMin .+ tile .* tile_size
        tb_max = min.(tb_min .+ (tile_size - 1), sample_bounds.pMax)
        tile_bounds = Bounds2(tb_min, tb_max)
        film_tile = FilmTile(i.camera.core.core.film, tile_bounds)
        for pixel in tile_bounds # adding iterator method is cool
            start_pixel!(tile_sampler, pixel)
            while has_next_sample(tile_sampler)
                # Generate a single sample using BDPT
                # JOHN HACK. Generating get camera sample in generate_camera_subpath, problem?
                camera_sample = get_camera_sample!(tile_sampler, pixel)

                # Trace the camera and light subpaths
                camera_vertices = Vector{Vertex}(undef,i.max_depth + 2)
                light_vertices = Vector{Vertex}(undef,i.max_depth + 1)
                n_camera = generate_camera_subpath!(
                    camera_vertices,
                    scene, 
                    tile_sampler, 
                    i.max_depth + 2, 
                    i.camera,
                    camera_sample, 
                )
                # setting up light sampling dist at the start
                # this isn't a good strategy
                # default is "uniform" so not a big deal 
                # would be worse with spatial or distance
                light_distr = lookup(light_distr_generator, p(camera_vertices[1]))
                n_light = generate_light_subpath!(
                    light_vertices,
                    scene,
                    tile_sampler,
                    i.max_depth + 1,
                    time(camera_vertices[1]),
                    light_distr
                )

                # CHECK n_light and n_camera match # of vertices

                # execute all BDPT connection strategies
                # JOHN: sticking with indexing to match the book, adjusting for not 0 indexed arrays at array lookup
                L = Spectrum(0)
                for t in 1:n_camera
                    for s in 0:n_light
                        depth = t + s - 2
                        if ((s==1)&&(t==1) || (depth<0) || (depth>i.max_depth))
                            continue
                        end

                        mis_weight = 0.0
                        L_path, mis_weight, p_film_new = connect_BDPT(
                            scene,
                            light_vertices,
                            camera_vertices,
                            s,
                            t,
                            light_distr,
                            i.camera,
                            tile_sampler
                        )

                        if t != 1
                            L += L_path
                        else
                            # JOHN HACK
                            # ADD SPLAT???
                        end
                    end
                end
                
                add_sample!(film_tile, camera_sample.film, L, 1.0)
                start_next_sample!(tile_sampler)
            end
        end
        merge_film_tile!(i.camera.core.core.film , film_tile)
        # print("$(k)\n")
        Threads.atomic_add!(jj,1)
        Threads.lock(l)
        update!(prog, jj[])
        Threads.unlock(l)
    end
    @time got_film = i.camera.core.core.film
    save(got_film)
end

# 16.3.2 Generating the Camera and Light subpaths
"""
A symmetric pair of functions, generate_camera_subpath() and generate_light_subpath()
generate the two corresponding types of subpaths. both do some initial work to get the path started
then call out to a second function RandomWalk() which takes care of sampling the following vertices and 
initializing the path array. Both functions return the number of vertices in the path
"""
function generate_camera_subpath!(
    path::Vector{Vertex}, 
    scene::Scene, 
    sampler::AbstractSampler, 
    max_depth::Int64, 
    camera::Camera, 
    camera_sample::CameraSample
)::Int64
    (max_depth == 0) && return 0

    # sample initial ray for camera subpath
    """
    a camera path starts with a camera ray from generate_ray_differential(). 
    as in sample integrator, differentials are scaled so they reflect the actual pixel sampling density
    """
    ray, beta = generate_ray_differential(camera, camera_sample)
    beta = Spectrum(beta) # john hack; casting to spectrum
    scale_differentials!(ray, 1.0 / sqrt(sampler.pixel_sampler.sampler.samples_per_pixel))

    # generate first vertex on camera subpath and start random walk
    path[1] = create_camera_vertex(camera, ray, beta)
    pdf_pos, pdf_dir = pdf_we(camera, ray)
    return random_walk!(scene, ray, sampler, beta, pdf_dir, max_depth-1, Radiance, path, 1) + 1
end

function generate_light_subpath!(
    path::Vector{Vertex}, 
    scene::Scene, 
    sampler::AbstractSampler, 
    max_depth::Int64, 
    t::Float64, 
    light_distr::Distribution1D
)::Int64
    (max_depth == 0) && return 0
    
    # sample initial ray for light subpath
    light_num, light_pdf, _ = sample_discrete(light_distr, get_1D!(sampler))
    light = scene.lights[light_num]
    Le, ray, n_light, pdf_pos, pdf_dir = sample_le(light, get_2D!(sampler), get_2D!(sampler), t)
    if (pdf_pos == 0.0) || (pdf_dir == 0.0)
        return 0
    end

    # generate first vertex on light subpath and start random walk
    path[0+1] = create_light_vertex(light, ray, n_light, Le, pdf_pos * light_pdf)
    beta = Le * abs(dot(n_light, ray.direction)) / (light_pdf * pdf_pos * pdf_dir)
    n_vertices = random_walk!(scene, ray, sampler, beta, pdf_dir, max_depth-1, Importance, path, 1)

    # correct subpath sampling densities for infinite area lights
    if is_infinite_light(path[1])
        # set spatial density of path[2] for infinite area light
        if n_vertices > 0
            path[1+1].pdf_fwd = pdf_pos
            if is_on_surface(path[1+1])
                path[1+1].pdf_fwd *= abs(dot(ray.direction, path[1+1].ng))
            end
        end
        path[0+1].pdf_fwd = infinite_light_density(scene, light_distr, ray.direction)
    end
    return n_vertices + 1
end

function random_walk!(
    scene::Scene, 
    ray::RayDifferential, 
    sampler::AbstractSampler, 
    beta::Spectrum, 
    pdf::Float64, 
    max_depth::Int64, 
    mode::Type{T}, 
    path::Vector{Vertex},
    path_offset::Int64
)::Int64 where T <: TransportMode
    (max_depth == 0) && return 0
    # decleare variables for forward and reverse probability densities
    bounces = 0
    pdf_fwd = pdf
    pdf_rev = 0.0

    # JOHN HACK
    bounces += path_offset

    while true
        # attempt to create the next subpath verte in *path*
        check, _, isect = intersect!(scene.b, ray)
        
        # JOHN HACK --> no medium no is black so continue

        # JOHN HACK --> using indexes
        vertex = bounces+1
        prev = bounces-1+1

        # handle surface interaction for path generation
        if !check
            # capture escaped rays when tracing from camera
            if mode == Radiance
                path[vertex] = create_light_vertex(EndpointInteraction(ray), beta, pdf_fwd)
                bounces += 1
            end
            break
        end

        # compute scattering functions for mode and skip over medium boundaries
        compute_scattering!(isect, ray, true, mode)
        if isect.bsdf isa Nothing
            ray = spawn_ray(isect.core, ray.direction)
            continue
        end
        
        # initialize vertex with surface scattering information
        path[vertex] = create_surface_vertex(isect, beta, pdf_fwd, path[prev])

        bounces += 1
        if bounces >= max_depth + path_offset # JOHN HACK
            break
        end

        # sample BSDF at current vertex and compute reverse probability
        wo = isect.core.wo
        wi, f, pdf, sampled_type = sample_f(isect.bsdf, wo, get_2D!(sampler), BSDF_ALL)
        (pdf == 0.0) && break
        beta *= f * abs(dot(wi, isect.shading.n)) / pdf_fwd
        pdf_rev = compute_pdf(isect.bsdf, wi, wo, BSDF_ALL)
        if (sampled_type & BSDF_SPECULAR) == sampled_type
            path[vertex].delta = true
            pdf_rev = 0.0
            pdf_fwd = 0.0
        end
        beta *= correct_shading_normal(isect, wo, wi, mode)
        ray = spawn_ray(isect.core, wi)
        
        # Compute reverse area density at preceding vertex
        path[prev].pdf_rev = convert_density(path[vertex], pdf_rev, path[prev])
    end
    return bounces
end


# 16.3.3 Subpath Connections
function connect_BDPT(
    scene::Scene, 
    light_vertices::Vector{Vertex}, 
    camera_vertices::Vector{Vertex},
    s::Int64,
    t::Int64,
    light_distr::Distribution1D,
    camera::Camera,
    sampler::AbstractSampler,
)::Spectrum
    L = Spectrum(0.0)

    print("Connection Strategy: (",s, ", ", t, ")\n")
    print("light length:", length(light_vertices), ": ")
    print_nice(light_vertices)
    print("\n")
    print("camera length:", length(camera_vertices), ": ")
    print_nice(camera_vertices)
    print("\n\n")


    # ignore invalid connections related to infinite light
    if (t > 1) && (s != 0) && (camera_vertices[t-1+1].type == VTLight)
        return Spectrum(0)
    end

    sampled = nothing
    # perform connection and write contribution to L
    if s == 0
        # interpret the camera subpath as a complete path
        pt = camera_vertices[t-1+1]
        if is_light(pt)
            L = le(pt, scene, camera_vertices[t-2+1]) * pt.beta
        end
    elseif t == 1
        # sample a point on the camera and connect it to the light subpath
        qs = light_vertices[s-1+1]
        if is_connectible(qs)
            sampled_wi, wi, pdf, vis = sample_wi(camera, get_interaction(qs), get_2D!(sampler))
            if pdf > 0
                # initalize dynamically sampled vertex and L for t=1 case
                sampled = create_camera_vertex(camera, vis.p1, sampled_wi / pdf)
                L = qs.beta * f(qs, sampled) * tr(vis, scene, sampler) * sampled.beta
                if is_on_surface(qs)
                    L *= abs(dot(wi, qs.ns))
                end
            end
        end
    elseif s == 1
        # sample a point on the light and connect it to the camera subpath
        pt = camera_vertices[t-1+1]
        if is_connectible(pt)
            light_num, light_pdf, _ = sample_discrete(light_distr, get_1D(sampler))
            light = scene.lights[light_num]
            sampled_li, wi, pdf, vis, _, _ = sample_li(light, get_interaction(pt), get_2D!(i.sampler))
            if pdf > 0
                ei = EndpointInteraction(vis.p1)
                sampled = create_light_vertex(ei, sampled_li/(pdf*light_pdf), 0)
                sampled.pdf_fwd = pdf_light_origin(sampled, scene, pt, light_distr)
                L = pt.beta * f(pt, sampled) * tr(vis, scene, sampler) * sampled.beta
                if is_on_surface(pt)
                    L *= abs(dot(wi, pt.ns))
                end
            end
        end
    else
        # handle all other bidirectional connection cases
        qs = light_vertices[s-1+1]
        pt = camera_vertices[t-1+1]
        if is_connectible(qs) && is_connectible(pt)
            L = qs.beta * f(qs, pt) * f(pt, qs) * pt.beta
            # JOHN HACK: if not black --> always
            L *= G(scene, sampler, qs, pt)
        end
    end

    # compute MIS weight for connection strategy
    mis_weight = MIS_weight(scene, light_vertices, camera_vertices, sampled, s, t, light_distr)
    L *= mis_weight
    return L
end

function MIS_weight(
    scene::Scene, 
    light_vertices::Vector{Vertex}, 
    camera_vertices::Vector{Vertex},
    sampled::Maybe{Vertex},
    s::Int64,
    t::Int64,
    light_distr::Distribution1D
)::Float64
    (s + t == 2) && (return 1.0)
    sum_ri = 0.0

    # Temporarily update vertex properties for current strategy

    # Look up connection vertices and their predecessors
    # JOHN HACK: these are idx's not vertex's
    check = (sampled isa Nothing)
    qs = (s > 0) && (!check) ? s-1+1 : 0 # --> LIGHT
    pt = (t > 0) && (!check) ? t-1+1 : 0 # --> CAMERA
    qs_minus = (s > 1) && (!check) ? s-2+1 : 0 # --> LIGHT
    pt_minus = (t > 1) && (!check) ? t-2+1 : 0 # --> CAMERA

    # LOG INITIAL STATE
    logg = Dict{Tuple{Int64,Int64}, VertexLog}()
    # logging qs and qs_minus
    (qs>0) && (logg[(qs,1)] = VertexLog(
        light_vertices[qs].delta, 
        light_vertices[qs].pdf_fwd, 
        light_vertices[qs].pdf_rev
    ))
    (qs_minus>0) && (logg[(qs_minus,1)] = VertexLog(
        light_vertices[qs_minus].delta, 
        light_vertices[qs_minus].pdf_fwd, 
        light_vertices[qs_minus].pdf_rev
    ))
    # logging pt and pt_minus
    (pt>0) && (logg[(pt,2)] = VertexLog(
        camera_vertices[pt].delta, 
        camera_vertices[pt].pdf_fwd, 
        camera_vertices[pt].pdf_rev
    ))
    (pt_minus>0) && (logg[(pt_minus,2)] = VertexLog(
        camera_vertices[pt_minus].delta, 
        camera_vertices[pt_minus].pdf_fwd, 
        camera_vertices[pt_minus].pdf_rev
    ))

    # Update sampled vertex for $s=1$ or $t=1$ strategy
    # a1
    if s==1
        if qs > 0
            backup = copy(light_vertices[qs])
            light_vertices[qs] = sampled
        end
    elseif t==1
        if pt > 0
            backup = copy(camera_vertices[pt])
            camera_vertices[pt] = sampled
        end
    end

    # Mark connection vertices as non-degenerate
    # a2 & a3
    (pt > 0) && (camera_vertices[pt].delta = false)
    (qs > 0) && (light_vertices[qs].delta = false)

    # Update reverse density of vertex $\pt{}_{t-1}$
    # a4
    if pt > 0 
        if s > 0
            light_vertices[pt].pdf_rev = pdf(camera_vertices[qs])
        else
            light_vertices[pt].pdf_rev = pdf_light_origin(light_vertices[pt])
        end
    end

    # Update reverse density of vertex $\pt{}_{t-2}$
    # a5
    if pt_minus > 0
        if s > 0 
            camera_vertices[pt_minus].pdf_rev = pdf(light_vertices[pt])
        else
            camera_vertices[pt_minus].pdf_rev = pdf_light(light_vertices[pt])
        end
    end

    # Update reverse density of vertices $\pq{}_{s-1}$ and $\pq{}_{s-2}$
    # a6 & a7
    (qs > 0) && (camera_vertices[qs].pdfRev = pdf(light_vertices[pt]))
    (qs_minus > 0) && (camera_vertices[qs_minus].pdfRev = pdf(camera_vertices[qs]))

    # Consider hypothetical connection strategies along the camera subpath
    ri = 1.0
    for i in reverse(1:(t-1))
        ri *= remap0(camera_vertices[i+1].pdf_rev) / remap0(camera_vertices[i+1].pdf_fwd)
        (!camera_vertices[i+1].delta && !camera_vertices[i-1+1].delta) && (sum_ri += ri)
    end

    # Consider hypothetical connection strategies along the light subpath
    ri = 1.0
    for i in reverse(0:(s-1))
        ri *= remap0(light_vertices[i+1].pdf_rev) / remap0(light_vertices[i+1].pdf_fwd)
        delta_light_vertex = i > 0 ? light_vertices[i-1+1].delta : is_delta_light(light_vertices[0+1].ei.light)
        (light_vertices[i+1].delta && !delta_light_vertex) && (sum_ri += ri)
    end

    # UNROLL a1
    if s==1
        if qs > 0
            light_vertices[qs] = backup
        end
    elseif t==1
        if pt > 0
            camera_vertices[pt] = backup
        end
    end

    # UNROLL a2 & a3
    (pt > 0) && (camera_vertices[pt].delta = logg[(pt,2)].delta)
    (qs > 0) && (light_vertices[qs].delta = logg[(qs,1)].delta)

    # UNROLL a4 & a5
    if pt > 0 
        light_vertices[pt].pdf_rev = logg[(pt,2)].pdf_rev
    end
    if pt_minus > 0
        camera_vertices[pt_minus].pdf_rev = logg[(pt_minus,2)].pdf_rev
    end

    # UNROLL a6 & a7
    (qs > 0) && (camera_vertices[qs].pdf_rev = logg[(qs,1)].pdf_rev)
    (qs_minus > 0) && (camera_vertices[qs_minus].pdf_rev = logg[(qs_minus,1)].pdf_rev)

    return 1.0/(1.0+sum_ri)
end