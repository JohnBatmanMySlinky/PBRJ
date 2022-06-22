# PBR 6.1
# "The abstract Camera base class holds generic camera options and defines the interface that all camera implementations must provide."
struct CameraCore
    camera_to_world::Transformation
    shutter_open::Float64
    shutter_closed::Float64
    film::Film
end

# "The CameraSample structure holds all of the sample values needed to specify a camera ray."
struct CameraSample
    film::Pnt2
    lens::Pnt2
    time::Float64
end