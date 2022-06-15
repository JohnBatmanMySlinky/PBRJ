function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table s begin
        "--scene"
            help = "scene number"
            arg_type = Int
            default = 1
        "--image-width"
            help = "image-width"
            arg_type = Int
            default = 250
        "--samples-per-pixel"
            help = "samples per pixel"
            arg_type = Int
            default = 50
    end

    return parse_args(s)
end