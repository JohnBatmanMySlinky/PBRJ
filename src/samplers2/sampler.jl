function SamplerFactory(args::Dict)::AbstractSampler
    spp = args["samples-per-pixel"]
    type = args["sampler"]
    debug = args["debug"]
    seed = args["seed"]
    jitter = args["jitter"]
    if debug 
        if type == "dumb"
            return DumbSampler(spp)
        elseif type == "deterministic"
            return DeterministicSampler(spp)
        else
            @assert false
        end
    else
        if type == "independent"
            return IndependentSampler(spp)
        elseif type == "zsobol"
            return ZSobolSampler(
                spp,
                Pnt2i(parsed_args["image-dim"][1], parsed_args["image-dim"][2]),
                Int8(2),
                seed
            )
        elseif type == "sobol"
            return SobolSampler(
                spp,
                Pnt2i(parsed_args["image-dim"][1], parsed_args["image-dim"][2]),
                Int8(2),
            )
        elseif type == "stratified"
            return StratifiedSampler(
                spp,
                jitter
            )
        elseif type == "deterministic"
            return DeterministicSampler(spp)
        else
            @assert false
        end
    end
end
        