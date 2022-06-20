function costheta(w::Vec3)
    return w[3]
end
function cos2theta(w::Vec3)
    return w[3]^2
end
function abscostheta(w::Vec3)
    return abs(w[3])
end
function sin2theta(w::Vec3)
    return max(0, 1-cos2theta(w))
end
function sintheta(w::Vec3)
    return sqrt(sin2theta(w))
end
function tantheta(w::Vec3)
    return sintheta(w) / costheta(w)
end
function tan2theta(w::Vec3)
    return sin2theta(w) / cos2theta(w)
end
function cosphi(w::Vec3)
    sintheta = sintheta(w)
    return sintheta == 0 ? 1 : clamp(w[3] / sintheta, -1, 1)
end
function sinphi(w::Vec3)
    sintheta = sintheta(w)
    return sintheta == 0 ? 0 : clamp(w[2] / sintheta, -1, 1)
end
function cos2phi(w::Vec3)
    return cosphi(w) ^ 2
end
function sin2phi(w::Vec3)
    return sinphi(w) ^ 2
end
function cosdphi(wa::Vec3, wb::Vec3)
    return clamp((wa[1] * wb[1] + wa[2] * wb[2]) / sqrt((wa[1]^2 + wb[2]^2)*(wb[1]^2 + wb[2]^2)), -1, 1)
