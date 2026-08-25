#####################################################################
### Handle / MultiSet
###
### A tagged-union pattern for replacing abstract-type dispatch with
### a small concrete (isbits) handle. Instead of storing e.g.
### `Maybe{AbstractMedium}` in a hot struct (which boxes and forces
### dynamic dispatch on every access), store a `Handle{:Medium}` and
### keep the actual concretely-typed values in a `MultiSet` — a Tuple
### of Vectors, one per concrete type registered under that Category.
###
### Handle is generic over which "slot" it belongs to — a Material
### handle and a Light handle are different types, so you can't mix
### them up.
#####################################################################

struct Handle{Category}
    tag::UInt8
    idx::UInt32
end

Base.:(==)(a::Handle{Category}, b::Handle{Category}) where Category = (a.tag == b.tag) && (a.idx == b.idx)
Base.show(io::IO, h::Handle{Category}) where Category = print(io, "Handle{$(Category)}(tag=$(h.tag), idx=$(h.idx))")

# Storage: a Tuple of Vectors, one per concrete type registered under Category
struct MultiSet{Category, T<:Tuple}
    data::T
end

function make_multiset(::Val{Category}, types::Type...) where Category
    data = map(t -> t[], types)
    MultiSet{Category, typeof(data)}(data)
end

@generated function Base.push!(s::MultiSet{Category,T}, x::X) where {Category,T,X}
    i = findfirst(t -> eltype(t) === X, T.parameters)
    i === nothing && error("$X not registered under $Category")
    quote
        v = s.data[$i]
        push!(v, x)
        Handle{Category}($(UInt8(i)), length(v))
    end
end

@generated function dispatch(f::F, s::MultiSet{Category,T}, h::Handle{Category}, args...) where {F,Category,T}
    n = length(T.parameters)
    branches = [:(h.tag == $(UInt8(i)) && return f(@inbounds(s.data[$i][h.idx]), args...)) for i in 1:n]
    quote
        $(branches...)
        error("bad tag $(h.tag)")
    end
end
