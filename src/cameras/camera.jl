# PBR 6.1
# "The abstract Camera base class holds generic camera options and defines the interface that all camera implementations must provide."
struct CameraCore
    camera_to_world::Transformation
    shutter_open::Float64
    shutter_closed::Float64
    film::Union{Film, PassFilm}
    medium::Maybe{Medium}

    function CameraCore(
        camera_to_world::Transformation,
        shutter_open::Float64,
        shutter_closed::Float64,
        film::Union{Film, PassFilm}
    )
        return new(
            camera_to_world,
            shutter_open,
            shutter_closed,
            film,
            nothing
        )
    end
end

# "The CameraSample structure holds all of the sample values needed to specify a camera ray."
struct CameraSample
    film::Pnt2
    lens::Pnt2
    t::Float64
end