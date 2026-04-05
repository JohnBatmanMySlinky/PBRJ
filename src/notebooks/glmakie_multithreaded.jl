using GLMakie
using Colors
using Base.Threads: @threads, Atomic, atomic_add!

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
    _ = [x^2 for x in 1:10_000]  # Simulate work]
    # sleep(0.000000001)
    return RGB{Float32}((x*y)/(height*width), (x*y)/(height*width), (x*y)/(height*width))
end

function render_with_locked_updates!(img_observable; tile_size=32, update_every=5)
    img = img_observable[]
    height, width = size(img)
    
    # Temporary buffer for rendering
    temp_buffer = zeros(RGB{Float32}, height, width)
    
    tiles = [(tx, ty) for ty in 1:tile_size:height for tx in 1:tile_size:width]
    completed_tiles = Set{Int}()
    tiles_lock = ReentrantLock()
    rendering_done = Atomic{Bool}(false)
    
    # Periodic update on main thread
    update_task = @async begin
        while !rendering_done[]
            sleep(0.1)  # Update every 100ms
            
            # Copy completed tiles to display buffer
            lock(tiles_lock) do
                for tile_idx in completed_tiles
                    tx, ty = tiles[tile_idx]
                    for y in ty:min(ty + tile_size - 1, height)
                        for x in tx:min(tx + tile_size - 1, width)
                            img[y, x] = temp_buffer[y, x]
                        end
                    end
                end
            end
            
            notify(img_observable)
        end
        notify(img_observable)  # Final update
    end
    
    # Render on worker threads
    @threads for tile_idx in 1:length(tiles)
        tx, ty = tiles[tile_idx]
        
        # Render this tile to temp buffer
        for y in ty:min(ty + tile_size - 1, height)
            for x in tx:min(tx + tile_size - 1, width)
                color = complicated_trace_ray(x, y, height, width)
                temp_buffer[y, x] = color
            end
        end
        
        # Mark tile as completed
        lock(tiles_lock) do
            push!(completed_tiles, tile_idx)
        end
    end
    
    # Signal rendering is done and do final copy
    rendering_done[] = true
    wait(update_task)
    
    # Final full copy
    img .= temp_buffer
    notify(img_observable)
end

# Usage
img_obs = setup_visualization(500, 500)
render_with_locked_updates!(img_obs; tile_size=16, update_every=1)
println("Rendering complete. Press Enter to close...")
readline()