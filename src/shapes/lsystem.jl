function LSystem(rules::Dict{String, String}, drawer::Dict{String, String}, start::String, iterations::Int64)
    definition = generate_lsystem_string(rules, start, iterations)

    return definition
end

function generate_lsystem_primitives(drawer::Dict{String, String}, definition::String)::Vector{Primitives}
    p = Pnt3(0.0, 0.0, 0.0)
    stack = Transformation[]
    committed = Pnt3[]

    for def in definition
        def = string(def)
        if def in keys(drawer)
            trans, op = drawer[def]
            if trans isa Transformation
                p = trans(p)
            else
                op(stack, p)
            end
        end
    end
    return committed
end

function nice_pop!(v::Vector{Transformation}, ::Transformation)
    pop!(v)
end
function nice_push!(v::Vector{Transformation}, t::Transformation)
    push!(v, t)
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
d2 = Dict(
    "F" => (Translate(Vec3(0,4,0)), nothing),
    "-" => (RotateX(-25.0), nothing),
    "-" => (RotateX(25.0), nothing),
    "[" => (nothing, push!),
    "]" => (nothing, pop!)
)

print(LSystem(d1, d1, "X", 1))