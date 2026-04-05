mutable struct RenderVizState
    fig::GLMakie.Figure
    img_obs::GLMakie.Observable{Matrix{RGB{Float32}}}
    stats_text::GLMakie.Observable{String}
    start_time::Float64
    total_tiles::Int
    w::Int
    h::Int
end

function setup_render_viz(w::Int, h::Int, total_tiles::Int, args::Dict{String, Any})::RenderVizState
    img_obs = GLMakie.Observable(zeros(RGB{Float32}, w, h))
    stats_text = GLMakie.Observable(initial_stats(args, w, h, total_tiles))

    sidebar_w = 200
    fig = GLMakie.Figure(size=(w + sidebar_w, h), backgroundcolor=:black)

    # image panel
    ax = GLMakie.Axis(fig[1, 1], aspect=GLMakie.DataAspect(), backgroundcolor=:black)
    GLMakie.image!(ax, img_obs)
    GLMakie.hidedecorations!(ax)
    GLMakie.hidespines!(ax)
    GLMakie.colsize!(fig.layout, 1, GLMakie.Fixed(w))

    # stats panel
    stats_ax = GLMakie.Axis(fig[1, 2], backgroundcolor=:black)
    GLMakie.hidedecorations!(stats_ax)
    GLMakie.hidespines!(stats_ax)
    GLMakie.xlims!(stats_ax, 0, 1)
    GLMakie.ylims!(stats_ax, 0, 1)
    GLMakie.text!(stats_ax, 0.1, 0.95,
        text=stats_text,
        align=(:left, :top),
        color=:white,
        fontsize=12,
        font="Courier New"
    )

    display(fig)
    return RenderVizState(fig, img_obs, stats_text, Base.time(), total_tiles, w, h)
end

function update_viz_stats!(rs::RenderVizState, completed::Int, args::Dict{String, Any})
    elapsed = Base.time() - rs.start_time
    pct = completed / rs.total_tiles * 100
    secs_per_tile = completed > 0 ? elapsed / completed : 0.0
    eta = completed > 0 ? (rs.total_tiles - completed) * secs_per_tile : 0.0

    rs.stats_text[] = """
scene:    $(args["scene-number"])
res:      $(rs.w) × $(rs.h)
spp:      $(args["samples-per-pixel"])
threads:  $(Threads.nthreads())

tiles:    $completed / $(rs.total_tiles)
done:     $(round(pct, digits=1))%

elapsed:  $(fmt_duration(elapsed))
eta:      $(completed > 0 ? fmt_duration(eta) : "---")"""
end

function initial_stats(args::Dict{String, Any}, w::Int, h::Int, total_tiles::Int)::String
    return """
scene:    $(args["scene-number"])
res:      $w × $h
spp:      $(args["samples-per-pixel"])
threads:  $(Threads.nthreads())

tiles:    0 / $total_tiles
done:     0.0%

elapsed:  0:00
eta:      ---"""
end

function update_viz_image!(rs::RenderVizState, film::Film, tile_bounds::Bounds2i)
    img = rs.img_obs[]
    film_width = film.cropped_pixel_bounds.pMax.x - film.cropped_pixel_bounds.pMin.x
    for pixel in tile_bounds
        if inside_exclusive(pixel, film.cropped_pixel_bounds)
            offset = (pixel.x - film.cropped_pixel_bounds.pMin.x) + (pixel.y - film.cropped_pixel_bounds.pMin.y) * film_width
            fp = film.pixels[offset + 1]
            rgb = XYZ_to_RGB(fp.xyz)
            if fp.filter_weight_sum != 0.0
                rgb = max.(0.0, rgb .* (1.0 / fp.filter_weight_sum))
            end
            px = pixel.x - film.cropped_pixel_bounds.pMin.x + 1
            py = pixel.y - film.cropped_pixel_bounds.pMin.y + 1
            img[px, rs.h - py + 1] = RGB{Float32}(clamp(Float32(rgb[1]), 0f0, 1f0), clamp(Float32(rgb[2]), 0f0, 1f0), clamp(Float32(rgb[3]), 0f0, 1f0))
        end
    end
    GLMakie.notify(rs.img_obs)
end

function viz_wait(rs::RenderVizState)
    println("Render complete. Close the window to exit.")
    while isopen(rs.fig.scene)
        sleep(0.1)
    end
end

function fmt_duration(s::Float64)::String
    s = round(Int, s)
    h, rem = divrem(s, 3600)
    m, sec = divrem(rem, 60)
    h > 0 ? @sprintf("%d:%02d:%02d", h, m, sec) : @sprintf("%d:%02d", m, sec)
end
