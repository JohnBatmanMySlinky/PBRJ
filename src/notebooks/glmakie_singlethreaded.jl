using GLMakie
using Colors

function setup_visualization(width, height)
    img = Observable(zeros(RGB{Float32}, height, width))
    
    fig = Figure()
    ax = Axis(fig[1, 1], aspect=DataAspect())
    image!(ax, img)
    hidedecorations!(ax)
    display(fig)
    
    return img
end

function complicated_trace_ray(x, y, height, width)
    # sleep(0.000000001)  # Simulate work
    return RGB{Float32}((x*y)/(height*width), (x*y)/(height*width), (x*y)/(height*width))
end

function render_single_threaded!(img_observable; tile_size=32)
    img = img_observable[]
    height, width = size(img)
    
    tiles = [(tx, ty) for ty in 1:tile_size:height for tx in 1:tile_size:width]
    
    for (tile_idx, (tx, ty)) in enumerate(tiles)
        # Render this tile
        for y in ty:min(ty + tile_size - 1, height)
            for x in tx:min(tx + tile_size - 1, width)
                color = complicated_trace_ray(x, y, height, width)
                img[y, x] = color
            end
        end
        
        # Update display after each tile
        notify(img_observable)
        sleep(0.001)  # Small delay to allow display to refresh
    end
    
    # Final update
    notify(img_observable)
end

# Usage
img_obs = setup_visualization(800, 600)
render_single_threaded!(img_obs; tile_size=32)
println("Rendering complete. Press Enter to close...")
readline()