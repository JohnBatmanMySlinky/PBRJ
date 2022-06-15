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





function ray_color(r::Ray, background::Vec3, world::Hittable, lights::Hittable, depth::Int64)::Vec3
    hit_record = hit(world, r, 0.0001, typemax(Float64))

    # if ray hit something
    if !ismissing(hit_record)
        # calculate scatter record & emittance at intersection
        s = scatter(hit_record.material, r, hit_record)
        emit = emitted(hit_record.material, hit_record.front_face, hit_record.u, hit_record.v, hit_record.p)

        # if scatter and depth
        if s.check && depth >= 0
            # if scatter is specular no pdf because detla distribution and recurse
            if s.is_specular == true
                return s.attenuation .* ray_color(s.specular_ray, background, world, lights, depth-1)

            # if scatter isn't specular
            else
                if length(lights.list)>0
                    light_pdf = HittablePDF(lights, hit_record.p)
                    light_ray = Ray(hit_record.p, generate(light_pdf), r.time)
                    light_pdf_val = value(light_pdf, light_ray.direction)

                    s_pdf_val = value(s.pdf, s.diffuse_ray.direction) / s.diffuse_prob
                    
                    if rand() < .5
                        scattered = light_ray
                    else
                        scattered = s.diffuse_ray
                    end

                    pdf_val = .5 * (
                        light_pdf_val + s_pdf_val
                    )
                else
                    scattered = s.diffuse_ray
                    pdf_val = value(s.pdf, s.diffuse_ray.direction) / s.diffuse_prob
                end

                # if pdf is zero, emit
                if pdf_val == 0
                    return emit
                # else emit and recurse
                else
                    return emit .+ s.attenuation .* scattering_pdf(hit_record.material, r, hit_record, scattered) .* ray_color(scattered, background, world, lights, depth - 1) / pdf_val
                end
            end

        # if no scatter, emit
        else
            return emit
        end
    # if no hit, background
    else
        return background
    end
end

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