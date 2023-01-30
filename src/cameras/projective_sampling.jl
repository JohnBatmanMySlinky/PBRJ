# JOHN TODO: adding this file to solve import order of operations.
# is there a better way?

function sample_wi(camera::PerspectiveCamera, ei::Union{EndpointInteraction, SurfaceInteraction}, u::Pnt2)::Tuple{Vec3, Spectrum, Float64, VisibilityTester}
    # uniformly sample a lens interaction
    plens = camera.core.lens_radius * random_in_concentric_disk(u)
    plensworld = camera.core.core.camera_to_world(Pnt3(plens.x, plens.y, 0))
    lens_norm = Nml3(camera.core.core.camera_to_world(Vec3(0,0,1)))
    lens_intr = Interaction(plensworld, time(ei), Vec3(0,0,0), lens_norm) # JOHN HACK: Vec3(0,0,0) going to break shit?

    base_inter = get_interaction(ei)
    # populate and precompute the importance value
    vis = VisibilityTester(base_inter, lens_intr)
    wi = Vec3(lens_intr.p - lens_intr.p)
    dist = norm(lens_intr.p - lens_intr.p)
    wi /= dist
    
    # compute the pdf for importance arriving at ei

    # compute lens area of perspective camera
    lens_area = camera.core.lens_radius != 0 ? (pi * camera.core.lens_radius ^ 2) : 1.0
    pdf = (dist^2) / (abs(dot(lens_intr.n, wi)) * lens_area)
    sampled_wi, p_raster = we(camera, spawn_ray(lens_intr, -wi)) # JOHN HACK: what to do with p_raster here?
    return wi, sampled_wi, pdf, vis
end