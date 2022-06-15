struct Image <: Texture
    data::Matrix
end

function color_value(img::Image, u::Float64, v::Float64, p::Vec3)::Vec3
    i = u * size(img.data)[2]
    j = (1-v) * size(img.data)[1] - .001
    i = Int(floor(max(0,min(i, size(img.data)[2]))))+1
    j = Int(floor(max(0,min(j, size(img.data)[1]))))+1

    r,g,b = red(img.data[j, i]), green(img.data[j, i]), blue(img.data[j, i])

    return Vec3(r,g,b)
end