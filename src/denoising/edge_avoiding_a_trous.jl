function denoise(img::Vector{Array{Float64}}, filter_size::Int64)::Array{Float64}
    # extract channels
    color_buffer = img[1]  # full
    albedo_buffer = img[2]  # albedo
    depth_buffer = img[3]  # depth
    normal_buffer = img[4] # normal

    # filter size loop
    loop_range = Int(trunc(log10(filter_size)/log10(2)))-1

    for step_width_tmp in 0:loop_range
        step_width = 2^step_width_tmp 
        color_buffer = denoise_kernel(color_buffer, depth_buffer, normal_buffer, step_width)
    end
    return color_buffer
end



function denoise_kernel(
    color_buffer::Array{Float64}, 
    depth_buffer::Array{Float64},
    normal_buffer::Array{Float64},
    step_width::Int64
)::Array{Float64}
    # create output channel
    X, Y = size(color_buffer)
    out_buffer = zeros(X,Y,3)

    # define constants
    kernel = Float64[0.375, 0.25, 0.0625]
    c_phi = 0.45
    d_phi = 0.95
    n_phi = 0.40


    # pixel loop
    for x in 1:X
        for y in 1:Y
            c_val = RayTracing.Pnt3(color_buffer[x, y, :])
            d_val = RayTracing.Pnt3(depth_buffer[x, y, :])
            n_val = RayTracing.Pnt3(normal_buffer[x, y, :])

            # convolution loop
            total = RayTracing.Pnt3(0.0)
            cum_w = 0.0
            for dy in -2:2
                for dx in -2:2
                    x_temp = clamp(x + dx * step_width, 1, X)
                    y_temp = clamp(y + dy * step_width, 1, Y)

                    c_temp = RayTracing.Pnt3(color_buffer[x_temp, y_temp, :])
                    t = c_val - c_temp
                    dist2 = dot(t,t)
                    c_w = min(exp(-dist2 / c_phi), 1.0)

                    n_temp = RayTracing.Pnt3(normal_buffer[x_temp, y_temp, :])
                    t = n_val - n_temp
                    dist2 = max(dot(t,t)/(step_width * step_width), 0.0)
                    n_w = min(exp(-dist2 / n_phi), 1.0)

                    d_temp = RayTracing.Pnt3(depth_buffer[x_temp, y_temp, :])
                    t = d_val - d_temp
                    dist2 = dot(t,t)
                    d_w = min(exp(-dist2 / d_phi), 1.0)

                    weight = c_w * n_w * d_w
                    kernel_index = min(abs(dx), abs(dy))+1
                    total += c_temp * weight * kernel[kernel_index]
                    cum_w += weight * kernel[kernel_index]
                end
            end
            fin = total / cum_w
            out_buffer[x, y, 1] = fin.x
            out_buffer[x, y, 2] = fin.y
            out_buffer[x, y, 3] = fin.z
        end
    end
    return out_buffer
end