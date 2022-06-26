cos_theta(w::Vec3) = w.z
cos_2_theta(w::Vec3) = w.z^2
abs_cos_theta(w::Vec3) = abs(w.z)

sin_2_theta(w::Vec3) = max(0,1-cos_2_theta(w))
sin_theta(w::Vec3) = sqrt(sin_2_theta(w))

tan_theta(w::Vec3) = sin_theta(w) / cos_theta(w)
tan_2_theta(w::Vec3) = sin_2_theta(w) / cos_2_theta(w)

function cos_phi(w::Vec3)
    st = sin_theta(w)
    return st == 0 ? 1 : clamp(w.x / st, -1, 1)
end

function sin_phi(w::Vec3)
    st = sin_theta(w)
    return st == 0 ? 1 : clamp(w.y / st, -1, 1)
end

cos_2_phi(w::Vec3) = cos_phi(w)^2
sin_2_phi(w::Vec3) = sin_phi(w)^2

function cos_d_phi(wa::Vec3, wb::Vec3)
    return clamp((wa.x * wb.x + wa.y * wb.y) / sqrt((wa.x^2 + wa.y^2) * (wb.x^2 + wb.y^2), -1, 1))
end

