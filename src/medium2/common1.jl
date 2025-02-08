struct MediumInterface
    inside::Maybe{AbstractMedium}
    outside::Maybe{AbstractMedium}
end

function MediumInterface(m::Maybe{AbstractMedium})
    return MediumInterface(m, m)
end