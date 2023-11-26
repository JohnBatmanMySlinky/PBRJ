using StaticArrays
using LinearAlgebra
using IterTools
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

# very helpful!
# https://editor.p5js.org/BarneyCodes/sketches/zYE1AuET8


# L SYSTEM TODOS
# - migrate generate_shapes() to be generate_primitives() by passing materials in the top level fn
# - properly parameterize length so its not hardcoded in generate_shapes() and generate_control_points()
# - fix inability to back track
#   - generate_control_points() should return a list of lists. 
#   - each sublist should be continuous branch. 
#   - "back tracking" should be delineated by a break in sublists so those segments aren't drawn.

function LSystem(rules::Dict{String, String}, start::String, iterations::Int64)

    # BECAUSE BACK TRACKING IS BORKEN
    @assert iterations == 1

    definitions = generate_lsystem_string(rules, start, iterations)
    # print("Our L-System string definition is: $(definitions)\n\n")

    control_points = generate_control_points(definitions)
    print("Our LSystem control points are:\n")
    for control_point in control_points
        print("\t\t$(control_point)\n")
    end

    # TODO
    # make this primitives next by passing materials
    shapes = generate_shapes(control_points)

    return shapes
end

# TODO
# MOVE THIS TO objects.jl
mutable struct SimpleRay
    p::Pnt3
    d::Vec3
end

function at(r::SimpleRay, t::Float64)::Pnt3
    return Pnt3(r.p + t * r.d)
end

function generate_shapes(v::Vector{Pnt3})::Vector{Shape}
    shapes = Shape[]
    for (look_from, look_to) in partition(v, 2, 1)
        tmp = Cylindar(
            LookAt(look_from, look_to, Vec3(0,1,0)),
            3.0,
            0.0,
            20.0
        )
        push!(shapes, tmp)
    end
    return shapes
end

function generate_control_points(definitions::String)::Vector{Pnt3}
    l = 20.0
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
            ray.p = at(ray, l)
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
            continue
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

# d1 = Dict("X" => "F+[[X]-X]-F[-FX]+X", "F" => "FF")
# pnts = LSystem(d1, "X", 2)

