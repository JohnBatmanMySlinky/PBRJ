struct InfiniteLight
    L::Vec3
end


function le(il::InfiniteLight, ray::Ray)
    return li.L
end