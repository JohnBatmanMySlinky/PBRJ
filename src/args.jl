function parse_commandline()::Dict
    s = ArgParseSettings()

    @add_arg_table s begin
        "--scene-number"
            help = "pick a scene"
            arg_type = Int
            default = 4
        "--render-simple"
            help = "bool for simple or complex"
            arg_type = Bool
            default = false
        "--image-dim"
            help = "image-width"
            arg_type = Int
            default = 250
        "--samples-per-pixel"
            help = "samples per pixel"
            arg_type = Int
            default = 5
        "--n-spectral-samples"
            help = "number of spectral samples to be used in rendering. 3 == RGB, else == Spectral"
            arg_type = Int
            default = 3
        "--jitter"
            help = "for stratified sampler: do jitter"
            arg_type = Bool
            default = true
        "--crop-window"
            nargs = 4
            help = "crow window from (0,0) - (1,1)"
            arg_type = Float64
            default = [0.0, 0.0, 1.0, 1.0]
        "--max-depth"
            help = "max # of bounces"
            arg_type = Int
            default = 6
        "--light-distribution-strategy"
            help = "strategy for sampling lights"
            arg_type = String
            default = "uniform" # power, centroid_distance, spatial
        "--file-name"
            help = "name of file"
            arg_type = String
            default = "yeehaw.exr"
        "--debug"
            help = "true = debug mode, false = not debug mode"
            arg_type = Bool
            default = false
        "--seed"
            help = "a random seeed for re-producibility"
            arg_type = Int
            default = 1234
    end

    return parse_args(s)
end