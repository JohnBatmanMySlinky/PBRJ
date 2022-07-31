mutable struct StratifiedSampler <: AbstractSampler
    pixel_sampler::PixelSampler
    current_pixel::Int64
    n_sampled_dimensions::Int64
    x_pixel_samples::Int64
    y_pixel_samples::Int64
    samples_per_pixel::Int64
    jitter::Bool

    function StratifiedSampler(
            x_pixel_samples::Int64,
            y_pixel_samples::Int64,
            n_sampled_dimensions::Int64,
            jitter::Bool
        )
        new(
            PixelSampler(
                x_pixel_samples * y_pixel_samples,
                n_sampled_dimensions
            ),
            1,
            n_sampled_dimensions,
            x_pixel_samples,
            y_pixel_samples,
            x_pixel_samples * y_pixel_samples,
            jitter
        )
    end
end

# "As a PixelSampler subclass, the implementation of StartPixel() 
# must both generate 1D and 2D samples for the number of dimensions 
# nSampledDimensions passed to the PixelSampler constructor as well as 
# samples for the requested arrays.
function start_pixel!(ss::StratifiedSampler, ::Pnt2)
    ss.current_pixel = 1
    one_minus_eps = 1.0 - eps()
    for i in 1:ss.n_sampled_dimensions
        inv_n_samples = 1 / (ss.x_pixel_samples * ss.y_pixel_samples)
        dx = 1.0 / ss.x_pixel_samples
        dy = 1.0 / ss.y_pixel_samples

        z = 0
        for x in 0:(ss.x_pixel_samples-1)
            for y in 0:(ss.y_pixel_samples-1)
                z+= 1
                # generate 1D samples
                delta = ss.jitter ? rand() : 0.5
                ss.pixel_sampler.sampels1D[i, z] = min((z-1 + delta) * inv_n_samples, one_minus_eps)

                # generate 2D samples
                jx = ss.jitter ? rand() : 0.5
                jy = ss.jitter ? rand() : 0.5
                ss.pixel_sampler.sampels2D[i, z] = Pnt2(
                    min((x + jx) * dx, one_minus_eps),
                    min((y + jy) * dy, one_minus_eps)
                )
            end
        end
    end

    # now shuffle!
    shuffle!(ss.pixel_sampler.sampels1D)
    shuffle!(ss.pixel_sampler.sampels2D)
end

function get_1D!(ss::StratifiedSampler)
    ss.pixel_sampler.current1DDimension += 1
    if ss.pixel_sampler.current1DDimension >= size(ss.pixel_sampler.sampels1D)[1]
        return rand()
    else
        return rand()
        # return ss.pixel_sampler.sampels1D[ss.pixel_sampler.current1DDimension, ss.current_pixel]
    end    
end

function get_2D!(ss::StratifiedSampler)
    ss.pixel_sampler.current2DDimension += 1
    if ss.pixel_sampler.current2DDimension >= size(ss.pixel_sampler.sampels2D)[1]
        return Pnt2(rand(), rand())
    else
        return Pnt2(rand(), rand())
        # return ss.pixel_sampler.sampels2D[ss.pixel_sampler.current2DDimension, ss.current_pixel]
    end    
end


function has_next_sample(ss::StratifiedSampler)
    return ss.current_pixel <= ss.samples_per_pixel
end
function start_next_sample!(ss::StratifiedSampler)
    ss.current_pixel += 1
    ss.pixel_sampler.current1DDimension = 1
    ss.pixel_sampler.current2DDimension = 1
end


function get_camera_sample!(sampler::StratifiedSampler, p_raster::Pnt2)
    p_film = p_raster .+ get_2D!(sampler) # 1,2
    time = get_1D!(sampler)               # 3
    p_lens = get_2D!(sampler)             # 4,5
    return CameraSample(
        p_film,
        p_lens,
        time
    )
end