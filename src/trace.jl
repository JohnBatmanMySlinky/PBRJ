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