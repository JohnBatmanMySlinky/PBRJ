struct ImageTexture <: Texture
    data::Matrix{Pnt3}
    l::Int64
    w::Int64
    tile::Pnt2

    function ImageTexture(path::String, tile::Pnt2=Pnt2(1,1))
        if lowercase(path[end-3:end]) == ".exr"
            raw = OpenEXR.load(path)
        elseif lowercase(path[end-3:end]) in [".png", ".jpg"]
            raw = load(path)
        else
            @assert false "it aint implemented yet"
        end
        L, W = size(raw)
        dat = zeros(Pnt3, L, W)
        for l in 1:L
            for w in 1:W
                c = raw[l,w]
                dat[l,w] = Pnt3(c.r, c.g, c.b)
            end
        end
        return new(
            dat,
            size(dat)[1],
            size(dat)[2],
            tile::Pnt2
        )
    end
end

function (it::ImageTexture)(si::SurfaceInteraction)
    u, v = si.uv
    # TODO
    # fucking bump mapping
    u = min(do_tile(u, it.tile.x), 1-eps(Float64))
    v = min(do_tile(v, it.tile.y), 1-eps(Float64))

    L = Int(floor(u*it.l)+1)
    W = Int(floor(v*it.w)+1)
    return it.data[L,W]
end