struct NoRandomizer <: Randomizer
end

function (r::NoRandomizer)(a::UInt32)::UInt32
    return a
end
