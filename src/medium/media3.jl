struct NanoVDBMedium <: AbstractMedium
    sigma_a::Spectrum
    sigma_s::Spectrum
    g::Float64
    world_to_medium::Transformation
    accessor::NanoVDB.DefaultReadAccessorAllocated
    sigma_t::Float64
    inv_max_density::Float64

    function NanoVDBMedium(sigma_a::Spectrum, sigma_s::Spectrum, 
        g::Float64, p0::Pnt3, p1::Pnt3, medium_to_world::Transformation, fpath::String
    )
        data_to_medium = Translate(Vec3(p0)) * Scale(p1.x - p0.x, p1.y - p0.y, p1.z - p0.z)
        tmp = Inv(medium_to_world * data_to_medium)
        @info "WTF IS THIS TRANSFORM: $(tmp)"

        bbox = NanoVDB.get_bbox(fpath)
        bboxmin = floor.(NanoVDB.get_bbox_min(bbox))
        bboxmax = ceil.(NanoVDB.get_bbox_max(bbox))
        delta = bboxmax - bboxmin

        accessor = NanoVDB.get_accessor_pls(fpath)
        max_density = 0.0
        resolution = 64
        for x in 1:resolution
            for y in 1:resolution
                for z in 1:resolution
                    c = NanoVDB.Coord(
                        Int(x * delta.x / resolution + bboxmin.x),
                        Int(y * delta.y / resolution + bboxmin.y),
                        Int(z * delta.z / resolution + bboxmin.z),
                    )
                    val = get_value_pls(accessor, c)
                    max_density = max(max_density, val)
                end
            end
        end

        @info "inv max density: $(1.0/max_density)"

        return new(
            sigma_a, sigma_s, g, tmp, 
            accessor, (sigma_a + sigma_s)[0+1], 1.0 / max_density
        )
    end
end
