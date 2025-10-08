# PBR 16.3 Bi-Directional Path Tracing
struct BDPTIntegrator <: AbstractIntegrator
    camera::C where C <: Camera
    sampler::S where S <: AbstractSampler
    max_depth::Int64
end

function render(
    i::BDPTIntegrator, 
    scene::Scene, 
    parsed_args::Dict, 
    bdpt_pass::Tuple{Int64, Int64}=(-1,-1),
)::Array{RGB}

    # BDPT only works if you have lights!!
    @assert length(scene.lights) > 0

    # create light sampling light_distribution
    # JOHN HACK --> hard coding uniform dist
    light_distr_generator = LightDistribution(
        parsed_args["light-distribution-strategy"], 
        scene,
        parsed_args["max-voxels"], 
    )

    # partition the image into tiles
    sample_bounds = get_sample_bounds(i.camera.core.core.film)
    @info "Sample Bounds $(sample_bounds)"
    sample_extent = diagonal(sample_bounds)
    tile_size = 16
    n_x_tiles, n_y_tiles = Int64.(floor.((sample_extent .+ tile_size .- 1) ./ tile_size))
    total_tiles = n_x_tiles * n_y_tiles

    # progress stuff
    prog = Progress(total_tiles)
    update!(prog,0)
    jj = Threads.Atomic{Int}(0)
    l = Threads.SpinLock()

    println("\nUtilizing $(Threads.nthreads()) threads\n\n")
    # the multi-threaded loop
    Threads.@threads for k in 0:(total_tiles-1)
        # this is a bullshit ass hack
        for wtf in 1:length(scene.b.primitives)
            if !(scene.b.primitives[wtf].mi.inside isa Nothing)
                if scene.b.primitives[wtf].mi.inside isa NanoVDBMedium
                    NanoVDB.init(scene.b.primitives[wtf].mi.inside.nanovdb_grid)
                end
            end
            if !(scene.b.primitives[wtf].mi.outside isa Nothing)
                if scene.b.primitives[wtf].mi.outside isa NanoVDBMedium
                    NanoVDB.init(scene.b.primitives[wtf].mi.outside.nanovdb_grid)
                end
            end
        end

        # Render a single tile using BDPT
        x, y = k % n_x_tiles, k ÷ n_x_tiles
        tile = Pnt2i(x, y)
        sampler = deepcopy(i.sampler)

        tb_min = sample_bounds.pMin .+ tile .* tile_size
        tb_max = min.(tb_min .+ (tile_size - 1), sample_bounds.pMax)
        tile_bounds = Bounds2i(tb_min, tb_max)
        film_tile = FilmTile(i.camera.core.core.film, tile_bounds)
        for pixel in tile_bounds # adding iterator method is cool
            @info "########################\nWorking on Pixel: $(pixel)\n########################\n\n\n"
            for sample_index in 1:sampler.samples_per_pixel
                start_pixel_sample!(sampler, pixel, sample_index-1)

                # Generate a single sample using BDPT
                camera_sample = get_camera_sample!(sampler, pixel)

                # JOHN TODO Render pass hacking
                if sample_index == 1
                    if i.camera.core.core.film isa PassFilm
                        ray, _ = generate_ray_differential(i.camera, camera_sample)
                        scale_differentials!(ray, 1.0 / sqrt(sampler.samples_per_pixel))
                        check, t, interaction, = intersect!(scene.b, ray)
                        if !check
                            L = to_XYZ(spectrum_from_float(0.0))
                            i.camera.core.core.film.pixels[Int(pixel.y)+1, Int(pixel.x)+1].albedo = L
                            i.camera.core.core.film.pixels[Int(pixel.y)+1, Int(pixel.x)+1].depth = L
                            i.camera.core.core.film.pixels[Int(pixel.y)+1, Int(pixel.x)+1].normal = L
                            i.camera.core.core.film.pixels[Int(pixel.y)+1, Int(pixel.x)+1].position = L
                        else
                            i.camera.core.core.film.pixels[Int(pixel.y)+1, Int(pixel.x)+1].albedo = to_XYZ(interaction.primitive.material.Kd(interaction))
                            i.camera.core.core.film.pixels[Int(pixel.y)+1, Int(pixel.x)+1].depth = to_XYZ(spectrum_from_float(t))
                            i.camera.core.core.film.pixels[Int(pixel.y)+1, Int(pixel.x)+1].normal = to_XYZ(spectrum_from_float(interaction.shading.n...))
                            i.camera.core.core.film.pixels[Int(pixel.y)+1, Int(pixel.x)+1].position = to_XYZ(spectrum_from_float(interaction.core.p...))
                        end
                    end
                end

                L = spectrum_from_float(0.0)
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

                # Some stuff for debugging here
                num_real_camera_vertices = count_not_undef(camera_vertices)
                num_real_light_vertices = count_not_undef(light_vertices)
                @info "BDPT: Number of real camera vertices: $(num_real_camera_vertices)"
                @info "BDPT: Number of real light vertices: $(num_real_light_vertices)"

                for iii in 1:num_real_camera_vertices
                    @info "$(camera_vertices[iii])"
                end
                for iii in 1:num_real_light_vertices
                    @info "$(light_vertices[iii])"
                end

                # for iii in 1:num_real_camera_vertices
                #     if camera_vertices[iii].ei isa Nothing
                #         pos = camera_vertices[iii].si.core.p
                #         lig = 1*(camera_vertices[iii].si.primitive.area_light isa Nothing)
                #     else
                #         pos = ""
                #         lig = ""
                #     end
                #     @info "BDPT: Camera Vertex $(iii): $(camera_vertices[iii].type) @ $(pos) $(lig)"
                # end

                # for iii in 1:num_real_camera_vertices
                #     @info "BDPT: Camera Vertex Hacky but OK $(iii): $(camera_vertices[iii].type) $(p(camera_vertices[iii]))"
                # end

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

                            @info "Connect bdpt s: $(s), t: $(t), Lpath: $(L_path), misWeight: $(mis_weight)"

                            if t != 1
                                L += L_path
                            else
                                add_splat!(i.camera.core.core.film, p_film_new, L_path)
                            end
                        end
                    end
                end
                
                @info "Add film sample pFilm: [ $(camera_sample.film.x), $(camera_sample.film.y) ], L: $(L), (y: $(y_spectrum(L)))"
                add_sample!(film_tile, camera_sample.film, L, 1.0)
            end
        end
        merge_film_tile!(i.camera.core.core.film , film_tile)
        Threads.atomic_add!(jj,1)
        Threads.lock(l)
        update!(prog, jj[])
        Threads.unlock(l)
    end
    got_film = i.camera.core.core.film
    @info "FILM before save: $(got_film)" 
    img = save(got_film, 1.0/i.sampler.samples_per_pixel)
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
    beta = spectrum_from_float(beta) # john hack; casting to spectrum
    scale_differentials!(ray, 1.0 / sqrt(sampler.samples_per_pixel))

    # generate first vertex on camera subpath and start random walk
    path[0+1] = create_camera_vertex(camera, ray, beta)
    pdf_pos, pdf_dir = pdf_we(camera, ray)
    @info "Starting camera subpath.\n\tRay $(ray)\n\tbeta $(beta)\n\t pdfPos $(pdf_pos)\n\tpdfDir $(pdf_dir) "
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
    @info "Light subpath light #$(light_num) aka $(light_num-1) in c++"
    light = scene.lights[light_num]
    Le, ray, n_light, pdf_pos, pdf_dir = sample_le(light, get_2D!(sampler), get_2D!(sampler), t)
    @info "Sample_le: $Le, $n_light, $ray"
    if (pdf_pos == 0.0) || (pdf_dir == 0.0) || is_black(Le)
        return 0, 0
    end

    # generate first vertex on light subpath and start random walk
    path[0+1] = create_light_vertex(light, ray, n_light, Le, pdf_pos * light_pdf)
    beta = Le * abs(dot(n_light, ray.direction)) / (light_pdf * pdf_pos * pdf_dir)
    @info "Starting light subpath. Ray: o $(ray.origin), d $(ray.direction) t $(ray.t) tMax: $(ray.tMax) , Le: $(Le), beta: $(beta), pdfPos: $(pdf_pos), pdfDir: $(pdf_dir)"
    n_vertices = random_walk!(scene, ray, sampler, beta, pdf_dir, max_depth-1, Importance, path, 1)

    # correct subpath sampling densities for infinite area lights
    if is_infinite_light(path[0+1])
        # set spatial density of path[2] for infinite area light
        if n_vertices > 0+1
            path[1+1].pdf_fwd = pdf_pos
            if is_on_surface(path[1+1])
                path[1+1].pdf_fwd *= abs(dot(ray.direction, ng(path[1+1])))
            end
        end
        path[0+1].pdf_fwd = infinite_light_density(scene.lights, light_distr, ray.direction)
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
    @info "Random Walk: We have entered"
    if max_depth == 0
        return 0
    end
    # decleare variables for forward and reverse probability densities
    mi = nothing
    bounces = 0
    pdf_fwd = pdf
    pdf_rev = 0.0

    # JOHN HACK
    bounces += path_offset

    COUNTER = 0

    while true
        @info "Random walk. Bounces $(bounces), beta $(beta), pdfFwd $(pdf_fwd), pdfRev $(pdf_rev)"

        COUNTER += 1
        # attempt to create the next subpath verte in *path*
        # @info "Ray current has a medium: $(!(ray.medium isa Nothing))"
        check, t, isect = intersect!(scene.b, ray)
        if check
            @info "Random walk: intersection\n\tp $(isect.core.p)\n\two $(isect.core.wo)\n\tn $(isect.core.n)\n\tshading n $(isect.shading.n)\n\t shading dpdu: $(isect.shading.dpdu)\n\t shading dpdv $(isect.shading.dpdv)"
            # @info "Isect Medium Interface: INSIDE $(!(isect.core.mi.inside isa Nothing)), OUTSIDE $(!(isect.core.mi.outside isa Nothing))";
        end

        # JOHN HACK --> using indexes
        vertex = bounces+1
        prev = bounces-1+1

        scattered = false
        terminated = false

        if !(ray.medium isa Nothing)
            # @info "MEDIUM BEEN HIT"
            u = get_1D!(sampler)
            t_max = (t isa Nothing) ? typemax(Float64) : t

            T_maj = sampleT_maj!(ray, t_max, u, sampler) do p, mp, sigma_maj, T_maj
                p_absorb = y_spectrum(mp.sigma_a) / y_spectrum(sigma_maj)
                p_scatter = y_spectrum(mp.sigma_s) / y_spectrum(sigma_maj)
                p_null = max(0.0, 1.0 - p_absorb - p_scatter)

                # Randomly sample medium event for _RandomRalk()_ ray
                um = get_1D!(sampler)
                callback_mode, _, _ = sample_discrete(Distribution1D([p_absorb, p_scatter, p_null]), um)

                if callback_mode == 0+1
                    # Handle absorption for _RandomWalk()_ ray
                    terminated = true
                    return false
                elseif callback_mode == 1+1
                    # Handle scattering for _RandomWalk()_ ray
                    beta *= T_maj * mp.sigma_s / (y_spectrum(T_maj) * y_spectrum(mp.sigma_s))

                    # record medium interaction in _path_ and compute forward density
                    mi = MediumInteraction(p, ray.t, -ray.direction, ray.medium, mp.phase)
                    path[vertex] = create_medium_vertex(mi, beta, pdf_fwd, path[prev])
                    bounces += 1
                    if bounces >= max_depth
                        terminated = true
                        return false
                    end

                    # Sample direction and compute reverse density at preceding vertex
                    ps_p, ps_wi, ps_pdf = sample_p(ray.medium.phase, -ray.direction, get_2D!(sampler))
                    if ((ps_p isa Nothing) || ps_pdf == 0.0) # JOHN HACK WHEN COULD ps be a Nothing?
                        terminated = true
                        return false
                    end

                    # Update path state and previous path vertex after medium scattering
                    pdf_fwd = ps_pdf
                    beta *= ps_p / ps_pdf
                    ray = spawn_ray(mi.core, ps_wi)
                    path[prev].pdf_rev = convert_density(path[vertex], ps_pdf, path[prev])

                    scattered = true
                    return false
                else
                    # Handle null scattering for _RandomWalk()_ ray
                    sigma_n = clamp.(sigma_maj - mp.sigma_a - mp.sigma_s, 0.0, typemax(Float64))
                    pdf_val = y_spectrum(T_maj) * y_spectrum(sigma_n)
                    if (pdf_val == 0.0)
                        beta = spectrum_from_float(0.0)
                    else
                        beta *= T_maj * sigma_n / pdf_val
                    end
                    return !is_black(beta)
                end
                @assert false
            end

            if (!scattered)
                beta *= T_maj / y_spectrum(T_maj)
            end
        end

        if is_black(beta)
            @info "Random walk: exited due to Black"
            break
        end

        if terminated
            return bounces
        end

        if scattered
            continue
        end

        # handle surface interaction for path generation
        if !check
            # capture escaped rays when tracing from camera
            if mode == Radiance
                @info "Random walk: Capture escaped rays when tracing from the camera - RADIANCE"
                path[vertex] = create_light_vertex(EndpointInteraction(ray), beta, pdf_fwd)
                # @info "HAHA: $(p(path[vertex])) $ray"
                bounces += 1
            end
            @info "Random walk: exited due to escaped rays"
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
        wi, f, pdf_fwd, sampled_type = sample_f(isect.bsdf, wo, get_2D!(sampler), BSDF_ALL)
        @info "Random walk sampled dir $wi f: $f, pdfFwd: $pdf_fwd, sampled_type: $sampled_type"
        if (pdf_fwd == 0.0) || is_black(f)
            break
        end
        beta *= f * abs(dot(wi, isect.shading.n)) / pdf_fwd
        @info "Random walk beta now $beta"
        pdf_rev = compute_pdf(isect.bsdf, wi, wo, BSDF_ALL)
        @info "random walk pdf_rev = $pdf_rev"
        if (sampled_type & BSDF_SPECULAR) > 0
            path[vertex].delta = true
            pdf_rev = 0.0
            pdf_fwd = 0.0
        end
        beta *= correct_shading_normal(isect, wo, wi, mode)
        @info "Random walk beta after shading normal correction $beta"
        ray = spawn_ray(isect.core, wi)
        
        # Compute reverse area density at preceding vertex
        @info "pdf_rev - before - $(path[prev].pdf_rev)"
        path[prev].pdf_rev = convert_density(path[vertex], pdf_rev, path[prev])
        @info "pdf_rev - after - $(path[prev].pdf_rev)"
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
    L = spectrum_from_float(0.0)

    @info "connect bdpt for s $(s), t $(t)"

    # ignore invalid connections related to infinite light
    if (t > 1) && (s != 0) && (camera_vertices[t-1+1].type == VTLight)
        return spectrum_from_float(0.0), 1.0, pfilm
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
            # @info "Vignette De Bugging: We Here"
            L = le(pt, scene, camera_vertices[t-2+1]) * pt.beta
        end
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
        qs = light_vertices[s-1+1]
        if is_connectible(qs)
            sampled_wi, wi, pdf_val, vis, pfilm = sample_wi(camera, get_interaction(qs), get_2D!(sampler))
            if (pdf_val > 0) && !is_black(sampled_wi)
                # initalize dynamically sampled vertex and L for t=1 case
                sampled = create_camera_vertex(camera, vis.p1, sampled_wi / pdf_val)
                L = qs.beta * f(qs, sampled, Importance) * sampled.beta
                if is_on_surface(qs)
                    L *= abs(dot(wi, ns(qs)))
                end
                if !(is_black(L))
                    L *= tr(vis, scene.b, sampler)
                end
            end
        end
    elseif s == 1
        # sample a point on the light and connect it to the camera subpath
        """
        We omit the next case, s==1 , here. It corresponds to performing a direct lighting calculation at the last vertex of the camera subpath. 
        Its implementation is similar to the t==1 case—the main differences are that roles of lights and cameras are exchanged 
        and that a light source must be chosen using lightDistr before a light sample can be generated.
        """
        pt = camera_vertices[t-1+1]
        if is_connectible(pt)
            # @info "is connectable"
            light_num, light_pdf, _ = sample_discrete(light_distr, get_1D!(sampler))
            light = scene.lights[light_num]
            sampled_li, wi, pdf_val, vis, _, _ = sample_li(light, get_interaction(pt).core, get_2D!(sampler))
            # @info "sampled Li from last camera vertex: sampled_li: $(sampled_li), wi: $(wi), pdf_val: $(pdf_val), visibility tester: $(vis)"
            if pdf_val > 0.0 && !(is_black(sampled_li))
                # @info "<<<<<SAMPLED A VERTEX>>>>>"
                ei = EndpointInteraction(vis.p1, light)
                sampled = create_light_vertex(ei, sampled_li/(pdf_val*light_pdf), 0.0)
                sampled.pdf_fwd = pdf_light_origin(sampled, scene, pt, light_distr, light_num)
                L = pt.beta * f(pt, sampled, Radiance) * sampled.beta
                # @info "L: $(L)"
                if is_on_surface(pt)
                    L *= abs(dot(wi, ns(pt)))
                end
                # @info "L: $(L)"
                if !is_black(L)
                    TR = tr(vis, scene.b, sampler)
                    L *= TR
                end
                # @info "L: $(L)"
            end
        end
    else
        # handle all other bidirectional connection cases
        qs = light_vertices[s-1+1]
        pt = camera_vertices[t-1+1]
        if is_connectible(qs) && is_connectible(pt)
            L = qs.beta * f(qs, pt, Importance) * f(pt, qs, Radiance) * pt.beta
            if !is_black(L)
                L *= G(scene, sampler, qs, pt)
            end
        end
    end

    # compute MIS weight for connection strategy
    mis_weight = is_black(L) ? 0.0 : MIS_weight(scene, light_vertices, camera_vertices, sampled, s, t, light_distr, light_num)
    # @info "MIS weight for (s,t) = ($(s),$(t)) connection $(mis_weight)"
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

    # for i in 0:(t-1)
    #     @info "MISWEIGHT LOOP CAMERA BEFORE: $(i)"
    #     @info "\t\tRev $(camera_vertices[i+1].pdf_rev), Fwd $(camera_vertices[i+1].pdf_fwd)"
    # end
    # for i in 0:(s)
    #     @info "MISWEIGHT LOOP LIGHT BEFORE: $(i)"
    #     @info "\t\tRev $(light_vertices[i+1].pdf_rev), Fwd $(light_vertices[i+1].pdf_fwd)"
    # end

    # Temporarily update vertex properties for current strategy

    # Look up connection vertices and their predecessors
    # JOHN HACK: these are idx's not vertex's
    qs = (s > 0) ? s-1+1 : 0 # --> LIGHT
    pt = (t > 0) ? t-1+1 : 0 # --> CAMERA
    qs_minus = (s > 1) ? s-2+1 : 0 # --> LIGHT
    pt_minus = (t > 1) ? t-2+1 : 0 # --> CAMERA

    # @info """Inventory
    # qs, $qs
    # pt, $pt - $(camera_vertices[pt])
    # qsMinus, $qs_minus
    # ptMinus, $pt_minus
    # """

    # # LOG INITIAL STATE
    # logg = Dict{Tuple{Int64,Int64}, VertexLog}()
    # # logging qs and qs_minus
    # (qs>0) && (logg[(qs,1)] = VertexLog(
    #     light_vertices[qs].delta, 
    #     light_vertices[qs].pdf_fwd, 
    #     light_vertices[qs].pdf_rev
    # ))
    # (qs_minus>0) && (logg[(qs_minus,1)] = VertexLog(
    #     light_vertices[qs_minus].delta, 
    #     light_vertices[qs_minus].pdf_fwd, 
    #     light_vertices[qs_minus].pdf_rev
    # ))
    # # logging pt and pt_minus
    # (pt>0) && (logg[(pt,2)] = VertexLog(
    #     camera_vertices[pt].delta, 
    #     camera_vertices[pt].pdf_fwd, 
    #     camera_vertices[pt].pdf_rev
    # ))
    # (pt_minus>0) && (logg[(pt_minus,2)] = VertexLog(
    #     camera_vertices[pt_minus].delta, 
    #     camera_vertices[pt_minus].pdf_fwd, 
    #     camera_vertices[pt_minus].pdf_rev
    # ))

    logg = MVector{4, VertexLog}(undef)

    (qs>0) && (logg[1] = VertexLog(
        light_vertices[qs].delta, 
        light_vertices[qs].pdf_fwd, 
        light_vertices[qs].pdf_rev
    ))
    (qs_minus>0) && (logg[2] = VertexLog(
        light_vertices[qs_minus].delta, 
        light_vertices[qs_minus].pdf_fwd, 
        light_vertices[qs_minus].pdf_rev
    ))
    (pt>0) && (logg[3] = VertexLog(
        camera_vertices[pt].delta, 
        camera_vertices[pt].pdf_fwd, 
        camera_vertices[pt].pdf_rev
    ))
    (pt_minus>0) && (logg[4] = VertexLog(
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

    if s==1 && t==2
        # @info "MISWEIGHT: <<a1>> $(camera_vertices[1+1].pdf_rev)"
    end

    # Mark connection vertices as non-degenerate
    # a2 & a3
    (pt > 0) && (camera_vertices[pt].delta = false)
    (qs > 0) && (light_vertices[qs].delta = false)

    if s==1 && t==2
        # @info "MISWEIGHT: <<a2,a3>> $(camera_vertices[1+1].pdf_rev)"
    end

    # Update reverse density of vertex $\pt{}_{t-1}$
    # a4
    if pt > 0 
        if s > 0
            if qs_minus == 0
                # @info "A"
                camera_vertices[pt].pdf_rev = pdf(light_vertices[qs], scene, nothing, camera_vertices[pt])
            else
                # @info "B"
                camera_vertices[pt].pdf_rev = pdf(light_vertices[qs], scene, light_vertices[qs_minus], camera_vertices[pt])
            end
        else
            # @info "C"
            camera_vertices[pt].pdf_rev = pdf_light_origin(camera_vertices[pt], scene, camera_vertices[pt_minus], light_distr, light_num)
        end
    end

    # @info "pt, $pt - $(camera_vertices[pt])"

    if s==1 && t==2
        # @info "MISWEIGHT: <<a4>> $(camera_vertices[1+1].pdf_rev)"
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

    if s==1 && t==2
        # @info "MISWEIGHT: <<a5>> $(camera_vertices[1+1].pdf_rev)"
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

    if s==1 && t==2
        # @info "MISWEIGHT: <<a6,a7>> $(camera_vertices[1+1].pdf_rev)"
    end

    # Consider hypothetical connection strategies along the camera subpath
    ri = 1.0
    for i in reverse(1:(t-1))
        # @info "MISWEIGHT LOOP: $(i)"
        ri *= remap0(camera_vertices[i+1].pdf_rev) / remap0(camera_vertices[i+1].pdf_fwd)
        if !camera_vertices[i+1].delta && !camera_vertices[i-1+1].delta
            sum_ri += ri
            # @info "MISWEIGHT: Camera Subpath: sumRi: $(sum_ri) ri: $(ri) aka $(remap0(camera_vertices[i+1].pdf_rev)) / $(remap0(camera_vertices[i+1].pdf_fwd))"
        end
    end

    # Consider hypothetical connection strategies along the light subpath
    ri = 1.0
    for i in reverse(0:(s-1))
        # @info "MISWEIGHT LOOP: $(i)"
        ri *= remap0(light_vertices[i+1].pdf_rev) / remap0(light_vertices[i+1].pdf_fwd)
        delta_light_vertex = i > 0 ? light_vertices[i-1+1].delta : is_delta_light(light_vertices[0+1].ei.light)
        if !light_vertices[i+1].delta && !delta_light_vertex
            # @info "MISWEIGHT: Light Subpath: sumRi: $(sum_ri) ri: $(ri)"
            sum_ri += ri
        end
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
    (pt > 0) && (camera_vertices[pt].delta = logg[3].delta)
    (qs > 0) && (light_vertices[qs].delta = logg[1].delta)

    # UNROLL a4 & a5
    if pt > 0 
        camera_vertices[pt].pdf_rev = logg[3].pdf_rev
    end
    if pt_minus > 0
        camera_vertices[pt_minus].pdf_rev = logg[2].pdf_rev
    end

    # UNROLL a6 & a7
    (qs > 0) && (light_vertices[qs].pdf_rev = logg[1].pdf_rev)
    (qs_minus > 0) && (light_vertices[qs_minus].pdf_rev = logg[4].pdf_rev)

    return 1.0/(1.0+sum_ri)
end