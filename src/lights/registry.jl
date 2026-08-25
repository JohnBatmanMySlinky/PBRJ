#####################################################################
### Light Registry
###
### Same Handle/MultiSet pattern as shapes/registry.jl and
### medium2/registry.jl - the full list of concrete Light subtypes is
### known up front (none are parameterized per-instance), so this is
### one fixed global MultiSet.
###
### Concrete lights live here in per-type Vectors instead of being
### referenced through abstract-typed fields (Primitive.area_light,
### Scene.lights, EndpointInteraction.light, ...). Those fields hold
### a Handle{:Light} instead - a small isbits value - resolved back
### to the concrete light via `dispatch`.
#####################################################################

const LIGHT_REGISTRY = Ref(make_multiset(
    Val(:Light),
    PointLight, SpotLight, DistantLight, UniformInfiniteLight, InfiniteLight, DiffuseAreaLight, ParticleEmitter,
))

to_light_handle(::Nothing) = nothing
to_light_handle(h::Handle{:Light}) = h
to_light_handle(l::Light) = push!(LIGHT_REGISTRY[], l)

get_light(h::Handle{:Light}) = dispatch(identity, LIGHT_REGISTRY[], h)

# Dedicated flags-only accessor: DiffuseAreaLight/ParticleEmitter aren't
# isbits (they carry heap fields like Vector/MIPMap), so the 7-way
# Union{<light types>} that get_light(h) returns can't be stored inline and
# boxes on every call. LightFlags is a single concrete isbits type across
# every branch, so reading just .flags through `dispatch` avoids that box -
# useful in hot spots (BDPT vertex bookkeeping) that only need the flags.
light_flags(h::Handle{:Light}) = dispatch(l -> l.flags, LIGHT_REGISTRY[], h)

power(h::Handle{:Light}) = dispatch(power, LIGHT_REGISTRY[], h)
le(h::Handle{:Light}, ray::AbstractRay) = dispatch(le, LIGHT_REGISTRY[], h, ray)
L(h::Handle{:Light}, n::Nml3, w::Vec3, uv::Pnt2) = dispatch(L, LIGHT_REGISTRY[], h, n, w, uv)
sample_li(h::Handle{:Light}, interaction::Interaction, u::Pnt2) = dispatch(sample_li, LIGHT_REGISTRY[], h, interaction, u)
pdf_li(h::Handle{:Light}, isect::SurfaceInteraction, wi::Vec3) = dispatch(pdf_li, LIGHT_REGISTRY[], h, isect, wi)
pdf_li(h::Handle{:Light}, isect::Interaction, wi::Vec3) = dispatch(pdf_li, LIGHT_REGISTRY[], h, isect, wi)
sample_le(h::Handle{:Light}, u1::Pnt2, u2::Pnt2, t::Float64) = dispatch(sample_le, LIGHT_REGISTRY[], h, u1, u2, t)
pdf_le(h::Handle{:Light}, ray::AbstractRay, n::Nml3) = dispatch(pdf_le, LIGHT_REGISTRY[], h, ray, n)
is_delta_light(h::Handle{:Light}) = dispatch(is_delta_light, LIGHT_REGISTRY[], h)
is_delta_pos_light(h::Handle{:Light}) = dispatch(is_delta_pos_light, LIGHT_REGISTRY[], h)
is_delta_dir_light(h::Handle{:Light}) = dispatch(is_delta_dir_light, LIGHT_REGISTRY[], h)
is_infinite_light(h::Handle{:Light}) = dispatch(is_infinite_light, LIGHT_REGISTRY[], h)
is_area_light(h::Handle{:Light}) = dispatch(is_area_light, LIGHT_REGISTRY[], h)
