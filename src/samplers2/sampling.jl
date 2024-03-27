function get_camera_sample!(sampler::AbstractSampler, p_raster::Pnt2)
    p_film = p_raster .+ get_pixel_2D!(sampler) # 1,2
    timesample = get_1D!(sampler)         # 3
    p_lens = get_2D!(sampler)             # 4,5
    return CameraSample(
        p_film,
        p_lens,
        timesample
    )
end