struct CameraCore
    camera_to_world::Transformation
    shutter_open::Float64
    shutter_closed::Float64
    film::Film
end


struct CameraSample
    film::Vec2
    lens::Vec2
    time::Float64
end