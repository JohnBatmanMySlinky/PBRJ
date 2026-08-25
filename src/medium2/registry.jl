#####################################################################
### Medium Registry
###
### Concrete AbstractMedium instances live here, in per-type Vectors,
### instead of being referenced directly through abstract-typed
### fields (Ray.medium, MediumInterface.inside/outside, ...). Those
### fields instead hold a Handle{:Medium} - a small concrete bits
### value - which is resolved back to the concrete medium via
### `dispatch`. This keeps hot structs like Ray free of
### dynamically-dispatched/boxed abstract-type fields.
#####################################################################

const MEDIUM_REGISTRY = Ref(make_multiset(Val(:Medium), HomogenousMedium, GridMedium, CloudMedium, NanoVDBMedium))

# Identity-keyed cache so registering the *same* medium object twice (e.g. the
# common `MediumInterface(m)` == `MediumInterface(m, m)` case) returns the same
# handle rather than two distinct ones - `is_transition_medium` depends on
# inside/outside comparing equal for a non-transition boundary.
const MEDIUM_HANDLE_CACHE = IdDict{AbstractMedium, Handle{:Medium}}()

to_medium_handle(::Nothing) = nothing
to_medium_handle(h::Handle{:Medium}) = h
function to_medium_handle(m::AbstractMedium)
    haskey(MEDIUM_HANDLE_CACHE, m) && return MEDIUM_HANDLE_CACHE[m]
    h = push!(MEDIUM_REGISTRY[], m)
    MEDIUM_HANDLE_CACHE[m] = h
    return h
end

sample_point(h::Handle{:Medium}, p::Pnt3)::MediumProperties = dispatch(sample_point, MEDIUM_REGISTRY[], h, p)
sample_ray(h::Handle{:Medium}, ray::AbstractRay, t_max::Float64) = dispatch(sample_ray, MEDIUM_REGISTRY[], h, ray, t_max)
