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
        "--file-name"
            help = "name of file"
            arg_type = String
            default = "yeehaw.png"
    end

    return parse_args(s)
end