using StaticArrays
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

function generate_lsystem_primitives(definitions::String)::Vector{Ray}
    drawn = Ray[]
    ray = Ray(Pnt3(0,0,0), Vec3(0, 1, 0), 0.0, typemax(Float64))
    stack = Ray[]
    l = 4.0
    r = 25.0

    for definition in definitions
        if definition == 'F'
            ray = Translate(Pnt3(0, l, 0))(ray)
            push!(drawn, ray)
        elseif definition == '+'
            ray = RotateZ(-r)(ray)
        elseif definition == '-'
            ray = RotateZ(r)(ray)
        elseif definition == '['
            push!(stack, ray)
        elseif definition == ']'
            ray = pop!(stack)
        elseif definition == 'X'
            continue
        else
            @assert "Bad Character in the L-System Definition"
        end
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

LSystem(d1, "X", 1)

# https://editor.p5js.org/BarneyCodes/sketches/zYE1AuET8