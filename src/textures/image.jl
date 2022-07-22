struct ImageTexture <: Texture
    data::Matrix{Pnt3}
    l::Int64
    w::Int64

    function ImageTexture(path::String)
        raw = load(path)
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
            size(dat)[2]
        )
    end
end

function (it::ImageTexture)(si::SurfaceInteraction)
    u, v = si.uv
    L = Int(floor(u*it.l)+1)
    W = Int(floor(v*it.w)+1)
    return it.data[L,W]
end
