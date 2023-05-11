module RayTracing

using StaticArrays
using LinearAlgebra
using Printf
using Distributions
using Images
using Statistics
using ArgParse

abstract type Material end
abstract type Hittable end
abstract type Texture end
abstract type BxDF end

function write_color(pixel_color::Vec3)::String
    ir = Int(trunc(255.999 * pixel_color[1]))
    ig = Int(trunc(255.999 * pixel_color[2]))
    ib = Int(trunc(255.999 * pixel_color[3]))
    return "$ir $ig $ib\n"
end

function print_status(t::Int64, T::Int64, length::Int64)::String
    number_done = Int(trunc(t * length / T))
    number_remain = length - number_done
    return "█"^number_done * "-"^number_remain * " | $(@sprintf("%.2f", 100*t/T))%" * "\r"
end

function render()
    parsed_args = parse_commandline()

    # params
    image_width = parsed_args["image-width"]
    samples_per_pixel = parsed_args["samples-per-pixel"]
    max_depth = 50

    # unpack world
    universe = scenes(parsed_args["scene"])
    cam = universe.camera
    world = universe.world
    lights = universe.lights
    background = universe.background

    # derived from camera's aspect ratio 
    image_height = Int(trunc(image_width / cam.aspect_ratio))

    # Render
    z = 0
    open("renders/JDONE.ppm", "w") do io
        write(io, "P3\n$image_width $image_height\n255\n")
        Threads.@threads for x = reverse(1:image_height)
            for y = 1:image_width
                anti_aliasing_vec = Vector{Vec3}(undef, samples_per_pixel)
                for s = 1:samples_per_pixel
                    u = (y+rand()) / image_width
                    v = (x+rand()) / image_height
                    r = get_ray(cam, u, v)
                    anti_aliasing_vec[s] = ray_color(r, background, world, lights, max_depth)
                end
                pixel_color = sum(anti_aliasing_vec) ./ samples_per_pixel
                pixel_color = sqrt.(max.(0,pixel_color))
                write(io, write_color(pixel_color))

                z = z + 1
                print(print_status(z,image_height * image_width, 30))
            end
        end
    end
end

@time render()
end