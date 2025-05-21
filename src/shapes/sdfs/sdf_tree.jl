# The Tree
struct SDFNode <: ImplicitSurface
    contents::Union{SDFFunction, ImplicitSurface}
    core::Maybe{ShapeCore}
    bounding_sphere::Maybe{Sphere}
    left::Maybe{SDFNode}
    right::Maybe{SDFNode}

    # Function & SDF Node
    SDFNode(contents) = new(contents, nothing, nothing, nothing)

    # Tree
    SDFNode(contents, core, bs, left, right) = new(contents, core, bs, left, right)
end

function f(node::SDFNode, t::Float64, r::AbstractRay)::Float64
    return f(node, at(r,t))
end

function f(node::SDFNode, pp::Pnt3)::Float64
    if node.contents isa ImplicitSurface
        return f(node.contents, node.contents.core.world_to_object(pp))
    elseif node.contents isa SDFFunction
        @assert !((node.left isa Nothing) && (node.right isa Nothing))

        l = f(node.left, node.left.contents.core.world_to_object(pp))
        r = f(node.right, node.right.contents.core.world_to_object(pp))
        return node.contents(l, r)
    else
        @assert false
    end
end

function f(s::ImplicitSurface, t::Float64, r::AbstractRay)
    pp = at(r,t)
    return f(s,pp)
end

function ObjectBounds(s::ImplicitSurface)::Bounds3
    return Bounds3(
        Pnt3(-s.bounding_sphere.radius, -s.bounding_sphere.radius, -s.bounding_sphere.radius),
        Pnt3(s.bounding_sphere.radius,   s.bounding_sphere.radius,   s.bounding_sphere.radius),
    )
end