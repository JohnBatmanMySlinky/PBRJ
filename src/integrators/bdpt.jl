# PBR 16.3 Bi-Directional Path Tracing
struct BDPTIntegrator <: AbstractIntegrator
    camera::C where C <: Camera
    sampler::S where S <: AbstractSampler
    max_depth::Int64
end

function render(
    i::BDPTIntegrator, 
    scene::Scene, 
    render_pass_flag::UInt8,
    bdpt_pass::Tuple{Int64, Int64}=(-1,-1),
    light_dist_strat::String="uniform", 
)::Array{Float64}
    @assert render_pass_flag <= 4
    """
    0 = full 
    1 = albedo
    2 = depth
    3 = normal
    4 = position
    """

    # create light sampling light_distribution
    # JOHN HACK --> hard coding uniform dist
    light_distr_generator = LightDistribution(light_dist_strat, scene)

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

    print("Utilizing $(Threads.nthreads()) threads\n\n")
    print("Working on the $(PASSDICT[render_pass_flag])\n")
    # the multi-threaded loop
    Threads.@threads for k in 0:total_tiles
        # Render a single tile using BDPT
        x, y = k % width, k ÷ width
        tile = Pnt2(x, y)
        sampler = deepcopy(i.sampler)

        tb_min = sample_bounds.pMin .+ tile .* tile_size
        tb_max = min.(tb_min .+ (tile_size - 1), sample_bounds.pMax)
        tile_bounds = Bounds2(tb_min, tb_max)
        film_tile = FilmTile(i.camera.core.core.film, tile_bounds)
        for pixel in tile_bounds # adding iterator method is cool
            start_pixel!(sampler, pixel)
            while has_next_sample(sampler)
                # Generate a single sample using BDPT
                camera_sample = get_camera_sample!(sampler, pixel)

                L = Spectrum(0.0)
                if render_pass_flag == UInt8(0) # full pass
                    # instantiate the list of vertices
                    camera_vertices = Vector{Vertex}(undef, i.max_depth + 2)
                    light_vertices = Vector{Vertex}(undef, i.max_depth + 1)

                    # Trace the camera and light subpaths
                    n_camera = generate_camera_subpath!(
                        camera_vertices,
                        scene, 
                        sampler, 
                        i.max_depth + 2, 
                        i.camera,
                        camera_sample, 
                    )
                    # setting up light sampling dist at the start
                    # this isn't a good strategy
                    # default is "uniform" so not a big deal 
                    # would be worse with spatial or distance
                    light_distr = lookup(light_distr_generator, p(camera_vertices[1]))
                    n_light, light_num = generate_light_subpath!(
                        light_vertices,
                        scene,
                        sampler,
                        i.max_depth + 1,
                        time(camera_vertices[1]),
                        light_distr
                    )

                    # execute all BDPT connection strategies
                    # JOHN: sticking with indexing to match the book, adjusting for not 0 indexed arrays at array lookup
                    for t in 1:n_camera
                        for s in 0:n_light
                            if ((s,t) == bdpt_pass) || (bdpt_pass == (-1,-1))
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
                                    light_num,
                                    i.camera,
                                    sampler,
                                    camera_sample.film
                                )

                                if t != 1
                                    L += L_path
                                else
                                    add_splat!(i.camera.core.core.film, p_film_new, L_path)
                                end
                            end
                        end
                    end
                else
                    ray, _ = generate_ray_differential(i.camera, camera_sample)
                    scale_differentials!(ray, 1.0 / sqrt(sampler.pixel_sampler.sampler.samples_per_pixel))
                    check, t, interaction, = intersect!(scene.b, ray)

                    if !check
                        L = Spectrum(0.0)
                    else
                        if render_pass_flag == UInt(1) # albedo   
                            L = Spectrum(interaction.primitive.material.Kd(interaction))
                        elseif render_pass_flag == UInt8(2) # depth
                            L = Spectrum(t)
                        elseif render_pass_flag == UInt8(3) # normal
                            L = Spectrum(interaction.shading.n)
                        elseif render_pass_flag == UInt8(4) # depth
                            if any(isnan.(interaction.core.p))
                                L = Spectrum(0.0)
                            else
                                L = Spectrum(interaction.core.p)
                            end
                        else
                            @assert false
                        end
                    end
                end
                add_sample!(film_tile, camera_sample.film, L, 1.0)
                start_next_sample!(sampler)
            end
        end
        merge_film_tile!(i.camera.core.core.film , film_tile)
        Threads.atomic_add!(jj,1)
        Threads.lock(l)
        update!(prog, jj[])
        Threads.unlock(l)
    end
    got_film = i.camera.core.core.film
    img = save(got_film, render_pass_flag, 1.0/i.sampler.pixel_sampler.sampler.samples_per_pixel)
    return img
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
    return random_walk!(scene, ray, sampler, beta, pdf_dir, max_depth-1, Radiance, path, 1)
end

function generate_light_subpath!(
    path::Vector{Vertex}, 
    scene::Scene, 
    sampler::AbstractSampler, 
    max_depth::Int64, 
    t::Float64, 
    light_distr::Distribution1D
)::Tuple{Int64,Int64}
    (max_depth == 0) && return 0, 0
    
    # sample initial ray for light subpath
    light_num, light_pdf, _ = sample_discrete(light_distr, get_1D!(sampler))
    light = scene.lights[light_num]
    Le, ray, n_light, pdf_pos, pdf_dir = sample_le(light, get_2D!(sampler), get_2D!(sampler), t)
    if (pdf_pos == 0.0) || (pdf_dir == 0.0)
        return 0, 0
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
    return n_vertices, light_num # JOHN HACK, what if I got rid of the +1?
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

    COUNTER = 0

    while true
        COUNTER += 1
        # attempt to create the next subpath verte in *path*
        check, t, isect = intersect!(scene.b, ray)
        
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
        (DEBUG == true) && print("\nray interesected scene (t=$(t)), surface added to idx $(vertex), bounces=$(bounces), max_depth=$(max_depth+path_offset)\n")
        if bounces >= max_depth + path_offset # JOHN HACK
            break
        end

        # sample BSDF at current vertex and compute reverse probability
        wo = isect.core.wo
        (DEBUG == true) && print("  Sampling BSDF: from p: $(isect.core.p), n: $(isect.core.n), t: $(isect.core.t)\n")
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
    light_num::Int64,
    camera::Camera,
    sampler::AbstractSampler,
    pfilm::Pnt2,
)::Tuple{Spectrum, Float64, Pnt2}
    L = Spectrum(0.0)

    # ignore invalid connections related to infinite light
    if (t > 1) && (s != 0) && (camera_vertices[t-1+1].type == VTLight)
        return Spectrum(0), 1.0, pfilm
    end

    sampled = nothing
    # perform connection and write contribution to L
    if s == 0
        # interpret the camera subpath as a complete path
        """
        The first case s==0 applies when no vertices on the light subpath are used 
        and can only succeed when the camera subpath p0,p1,...,pt-1  is already a complete path—that is, 
        when vertex pt-1 can be interpreted as a light source. 
        In this case, L is set to the product of the path throughput weight and the emission at 
        """
        pt = camera_vertices[t-1+1]
        if is_light(pt)
            L = le(pt, scene, camera_vertices[t-2+1]) * pt.beta
        end
        (DEBUG == true) && print("    Strategy: s==0\n")
        (DEBUG == true) && print("    L: $(L)\n")
        (DEBUG == true) && print_nice(pt)
        (DEBUG == true) && print_nice(camera_vertices[t-2+1])
    elseif t == 1
        # sample a point on the camera and connect it to the light subpath
        """
        The second case applies when t==1 that is,  when a prefix of the light subpath is directly connected to the camera. 
        To permit optimized importance sampling strategies analogous to direct illumination routines for light sources, 
        we will ignore the actual camera vertex p0 and sample a new one using Camera::Sample_Wi()—
        this optimization corresponds to the second bullet listed at the beginning of Section 16.3. 
        This type of connection can only succeed if the light subpath vertex qs-1 supports sampled connections; 
        otherwise the BSDF at qs-1 will certainly return 0 and there’s no reason to attempt a connection.
        """
        (DEBUG == true) && print("    Strategy: t==1\n")
        qs = light_vertices[s-1+1]
        (DEBUG == true) && print_nice(qs)
        if is_connectible(qs)
            sampled_wi, wi, pdf_val, vis, pfilm = sample_wi(camera, get_interaction(qs), get_2D!(sampler))
            (DEBUG == true) && print("    sampled_wi: $(sampled_wi)\n")
            (DEBUG == true) && print("    wi: $(wi)\n")
            (DEBUG == true) && print("    pdf_val: $(pdf_val)\n")
            if pdf_val > 0
                # initalize dynamically sampled vertex and L for t=1 case
                sampled = create_camera_vertex(camera, vis.p1, sampled_wi / pdf_val)
                (DEBUG == true) && print_nice(sampled)
                (DEBUG == true) && print("    unoccluded: $(unoccluded(vis, scene.b))\n")
                ff = f(qs, sampled, Importance)
                trtr = tr(vis, scene.b, sampler)
                (DEBUG == true) && print("    f: $(ff)\n")
                (DEBUG == true) && print("    tr: $(trtr)\n")
                (DEBUG == true) && print("    unoccluded: $(unoccluded(vis, scene.b))\n")
                L = qs.beta * ff * trtr * sampled.beta
                if is_on_surface(qs)
                    L *= abs(dot(wi, ns(qs)))
                end
                (DEBUG == true) && print("    L: $(L)\n")
                (DEBUG == true) && print("    Splatted to $(pfilm)\n")
            end
        end
    elseif s == 1
        # sample a point on the light and connect it to the camera subpath
        """
        We omit the next case, s==1 , here. It corresponds to performing a direct lighting calculation at the last vertex of the camera subpath. 
        Its implementation is similar to the t==1 case—the main differences are that roles of lights and cameras are exchanged 
        and that a light source must be chosen using lightDistr before a light sample can be generated.
        """
        (DEBUG == true) && print("    Strategy: s==1\n")
        pt = camera_vertices[t-1+1]
        (DEBUG == true) && print_nice(pt)
        if is_connectible(pt)
            light_num, light_pdf, _ = sample_discrete(light_distr, get_1D!(sampler))
            light = scene.lights[light_num]
            sampled_li, wi, pdf_val, vis, _, _ = sample_li(light, get_interaction(pt).core, get_2D!(sampler))
            if pdf_val > 0
                ei = EndpointInteraction(vis.p1, light)
                sampled = create_light_vertex(ei, sampled_li/(pdf_val*light_pdf), 0.0)
                (DEBUG == true) && print_nice(sampled)
                sampled.pdf_fwd = pdf_light_origin(sampled, scene, pt, light_distr, light_num)
                L = pt.beta * f(pt, sampled, Radiance) * tr(vis, scene.b, sampler) * sampled.beta
                if is_on_surface(pt)
                    L *= abs(dot(wi, ns(pt)))
                end
                (DEBUG == true) && print("    L: $(L)\n")
            end
        end
    else
        # handle all other bidirectional connection cases
        qs = light_vertices[s-1+1]
        pt = camera_vertices[t-1+1]
        (DEBUG == true) && print("    Strategy: s==1\n")
        (DEBUG == true) && print_nice(pt)
        (DEBUG == true) && print_nice(qs)
        if is_connectible(qs) && is_connectible(pt)
            (DEBUG == true) && print("    f radiance: $(f(pt, qs, Radiance))\n")
            (DEBUG == true) && print("    f importance: $(f(qs, pt, Importance))\n")
            L = qs.beta * f(qs, pt, Importance) * f(pt, qs, Radiance) * pt.beta
            (DEBUG == true) && print("    L pre G: $(L)\n")
            # JOHN HACK: if not black --> always
            L *= G(scene, sampler, qs, pt)
        end
        (DEBUG == true) && print("    L: $(L)\n")
    end

    # compute MIS weight for connection strategy
    mis_weight = MIS_weight(scene, light_vertices, camera_vertices, sampled, s, t, light_distr, light_num)
    (DO_MIS_WEIGHT) && (L *= mis_weight)
    return L, mis_weight, pfilm
end

function MIS_weight(
    scene::Scene, 
    light_vertices::Vector{Vertex}, 
    camera_vertices::Vector{Vertex},
    sampled::Maybe{Vertex},
    s::Int64,
    t::Int64,
    light_distr::Distribution1D,
    light_num::Int64
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
            backup = light_vertices[qs]
            light_vertices[qs] = sampled
        end
    elseif t==1
        if pt > 0
            backup = camera_vertices[pt]
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
            if qs_minus == 0
                camera_vertices[pt].pdf_rev = pdf(light_vertices[qs], scene, nothing, camera_vertices[pt])
            else
                camera_vertices[pt].pdf_rev = pdf(light_vertices[qs], scene, light_vertices[qs_minus], camera_vertices[pt])
            end
        else
            camera_vertices[pt].pdf_rev = pdf_light_origin(camera_vertices[pt], scene, light_vertices[qs], light_distr, light_num)
        end
    end

    # Update reverse density of vertex $\pt{}_{t-2}$
    # a5
    if pt_minus > 0
        if s > 0 
            camera_vertices[pt_minus].pdf_rev = pdf(camera_vertices[pt], scene, light_vertices[qs], camera_vertices[pt_minus])
        else
            camera_vertices[pt_minus].pdf_rev = pdf_light(camera_vertices[pt], scene, camera_vertices[pt_minus])
        end
    end

    # Update reverse density of vertices $\pq{}_{s-1}$ and $\pq{}_{s-2}$
    # a6 & a7
    if qs > 0
        if pt_minus == 0
            light_vertices[qs].pdf_rev = pdf(camera_vertices[pt], scene, nothing, light_vertices[qs])
        else
            light_vertices[qs].pdf_rev = pdf(camera_vertices[pt], scene, camera_vertices[pt_minus], light_vertices[qs])
        end
    end
    if qs_minus > 0
        light_vertices[qs_minus].pdf_rev = pdf(light_vertices[qs], scene, camera_vertices[pt], light_vertices[qs_minus])
    end

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
        camera_vertices[pt].pdf_rev = logg[(pt,2)].pdf_rev
    end
    if pt_minus > 0
        camera_vertices[pt_minus].pdf_rev = logg[(pt_minus,2)].pdf_rev
    end

    # UNROLL a6 & a7
    (qs > 0) && (light_vertices[qs].pdf_rev = logg[(qs,1)].pdf_rev)
    (qs_minus > 0) && (light_vertices[qs_minus].pdf_rev = logg[(qs_minus,1)].pdf_rev)

    return 1.0/(1.0+sum_ri)
end