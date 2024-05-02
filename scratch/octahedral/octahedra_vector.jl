struct Vec3
	x::Float64
	y::Float64
	z::Float64
end

struct OctVec
	x::UInt16
	y::UInt16
end

function vec3_to_octvec(v::Vec3)::OctVec
	tmp = (abs(v.x) + abs(v.y) + abs(v.z))
	v = Vec3(v.x/tmp, v.y/tmp, v.z/tmp)
	if v.z >= 0
		x = encode(v.x)
		y = encode(v.y)
	else
		x = encode((1-abs(v.y)) * sign(v.x))
		y = encode((1-abs(v.x)) * sign(v.y))
	end
	return OctVec(x,y)
end

function octvec_to_vec3(vv::OctVec)::Vec3
	x = -1 + 2 * (vv.x / 65535)
	y = -1 + 2 * (vv.y / 65535)
	z = 1 - (abs(x) + abs(y))
	if z < 0
		xo = x
		x = (1 - abs(y)) * sign(xo)
		y = (1 - abs(xo)) * sign(y)
	end
	return normalize(Vec3(x,y,z))
end

function encode(f::Float64)::UInt16
	return round(clamp((f + 1)/2, 0, 1) * 65535)
end

function normalize(a::Vec3)
	tmp = sqrt(a.x^2 + a.y^2 + a.z^2)
	return Vec3(a.x / tmp, a.y / tmp, a.z / tmp)
end

v = Vec3(0.5, 0.6, 0.7)
o = vec3_to_octvec(v)
print(octvec_to_vec3(o), "\n")
