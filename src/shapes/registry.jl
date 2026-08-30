#####################################################################
### Shape Registry
###
### Same Handle/MultiSet pattern as medium2/registry.jl - the full
### list of concrete Shape subtypes is known up front (none of them
### are parameterized per-instance like Material's Matte{K,S,B}), so
### this is one fixed global MultiSet, not a per-scene registry like
### MaterialRegistry.
###
### Concrete shapes live here in per-type Vectors instead of being
### referenced through abstract-typed fields (Primitive.shape,
### SurfaceInteraction.shape, DiffuseAreaLight.shape, SDFUnion's
### left/right, ...). Those fields hold a Handle{:Shape} instead - a
### small isbits value - resolved back to the concrete shape via
### `dispatch`.
#####################################################################

const SHAPE_REGISTRY = Ref(make_multiset(
    Val(:Shape),
    Sphere, Triangle, Disk, Cylindar, Curve, BasicSphere, BilinearPatch,
    GoursatSurface, MetaBalls, MetaBallsBVH,
    SDFUnion, SDFSphere, SDFDisplacedSphere, SDFBox, SDFTorus, SDFFrameBox, SDFRoundedCone, SDFHexagonalPrism, SDFQuad,
))

# Scene construction (single-threaded) pushes here freely. The one other
# caller - BasicSphere's "kludge because I am not using primitives" path in
# metaballs_bvh's inner BVH{BasicSphere} traversal - runs inside the
# multithreaded render loop, so this needs to be safe under concurrent push!.
const SHAPE_REGISTRY_LOCK = ReentrantLock()

to_shape_handle(::Nothing) = nothing
to_shape_handle(h::Handle{:Shape}) = h
to_shape_handle(s::Shape) = lock(() -> push!(SHAPE_REGISTRY[], s), SHAPE_REGISTRY_LOCK)

get_shape(h::Handle{:Shape}) = dispatch(identity, SHAPE_REGISTRY[], h)

intersect(h::Handle{:Shape}, r::AbstractRay) = dispatch(intersect, SHAPE_REGISTRY[], h, r)
intersect_p(h::Handle{:Shape}, r::AbstractRay) = dispatch(intersect_p, SHAPE_REGISTRY[], h, r)
world_bounds(h::Handle{:Shape}) = dispatch(world_bounds, SHAPE_REGISTRY[], h)
area(h::Handle{:Shape}) = dispatch(area, SHAPE_REGISTRY[], h)
sample(h::Handle{:Shape}, u::Pnt2) = dispatch(sample, SHAPE_REGISTRY[], h, u)
sample(h::Handle{:Shape}, si::Interaction, u::Pnt2) = dispatch(sample, SHAPE_REGISTRY[], h, si, u)
pdf(h::Handle{:Shape}) = dispatch(pdf, SHAPE_REGISTRY[], h)
pdf(h::Handle{:Shape}, si::Interaction, wi::Vec3) = dispatch(pdf, SHAPE_REGISTRY[], h, si, wi)
evaluate(h::Handle{:Shape}, p::Pnt3) = dispatch(evaluate, SHAPE_REGISTRY[], h, p)
