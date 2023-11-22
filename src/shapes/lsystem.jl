using StaticArrays
using LinearAlgebra
abstract type AbstractRay end
abstract type AbstractBSDF end
abstract type Material end
abstract type Light end
abstract type Shape end
const Radiance = Val{:Radiance}
const Importance = Val{:Importance}
const TransportMode = Union{Radiance, Importance}
include("../objects.jl")
include("../primitive.jl")
include("../interactions.jl")
include("../transformations.jl")

function LSystem(rules::Dict{String, String}, start::String, iterations::Int64)
    definitions = generate_lsystem_string(rules, start, iterations)
    print("Our L-System string definition is: $(definitions)\n\n")

    primitives = generate_lsystem_primitives(definitions)
    print("Our LSystem primitives are:\n")
    for prim in primitives
        print("\t$(prim)\n")
    end

    return definitions
end

mutable struct SimpleRay
    p::Pnt3
    d::Vec3
end

function at(r::SimpleRay, t::Float64)::Pnt3
    return Pnt3(r.p + t * r.d)
end

function generate_lsystem_primitives(definitions::String)::Vector{Pnt3}
    l = 4.0
    r = -25.0
    drawn = Pnt3[]
    stack = SimpleRay[]

    # instantiate ray
    ray = SimpleRay(
        Pnt3(0, 0, 0),
        RotateZ(r)(Vec3(0, 1, 0))
    )
    push!(drawn, ray.p)

    # begin drawing
    for definition in definitions
        if definition == 'F'
            ray.p = at(ray, 2.0)
            push!(drawn, ray.p)
        elseif definition == '+'
            ray.d = RotateZ(-r)(ray.d)
        elseif definition == '-'
            ray.d = RotateZ(r)(ray.d)
        elseif definition == '['
            push!(stack, deepcopy(ray)) # Rotates were mutating the stack...
        elseif definition == ']'
            ray = pop!(stack)
        elseif definition == 'X'
            
        else
            @assert "Bad Character in the L-System Definition"
        end
        # print("\tDefinition: $(definition) -- Current Ray: $(ray)\n")
        # print("\t\tStack: $(stack)\n")
    end
    @assert length(stack) == 0
    return drawn
end

function generate_lsystem_string(rules::Dict{String, String}, start::String, iterations::Int64)::String
    next_gen = start
    for _ in 1:iterations
        next_gen = string("")

        for s in start
            s = string(s)
            if s in keys(rules)
                next_gen *= rules[s]
            else
                next_gen *= s
            end
        end
        start = next_gen
    end
    return next_gen
end

d1 = Dict("X" => "F+[[X]-X]-F[-FX]+X", "F" => "FF")

LSystem(d1, "X", 2)

# https://editor.p5js.org/BarneyCodes/sketches/zYE1AuET8