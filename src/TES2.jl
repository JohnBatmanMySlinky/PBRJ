using StaticArrays

struct Pnt3 <: FieldVector{3, Float64}
    x::Float64
    y::Float64
    z::Float64
end

struct Vec3 <: FieldVector{3, Float64}
    x::Float64
    y::Float64
    z::Float64
end


function add_vec(v::Vec3)::Vec3
    v .+ 3
end

v = Vec3(0, 0, 0)
p = Pnt3(0, 0, 0)

print(add_vec(v))
print("\n")
print(p.^2)