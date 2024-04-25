# struct TexInfo
#     filename::String
#     do_trilinear::Bool
#     max_anisotropy::Float64
#     wrap_mode::Int8
#     scale::Float64
#     do_gamma::Bool
# end

# struct ImageTexture
#     mapping::AbstractTextureMapping2D
#     mipmap::MIPMap
#     texinfo::TexInfo

#     function ImageTexture(
#         mapping::AbstractTextureMapping2D, 
#         filename::String,
#         do_trilinear::Bool,
#         max_anisotropy::Float64,
#         wrap_mode::Int8,
#         scale::Float64,
#         do_gamma::Bool
#     )
#         mipmap = MipMap()
#         return new(
#             mapping,
#             mipmap,
#             TexInfo(filename, do_trilinear, max_anisotropy, wrap_mode, scale, do_gamma),
#         )
#     end
# end

# function evaluate(it::ImageTexture, si::SurfaceInteraction)::Spectrum
#     st, dstdx, dstdy = map(it.mapping, si)
#     mem = lookup(it.mipmap, st, dstdx, dstdy)
#     return mem
# end