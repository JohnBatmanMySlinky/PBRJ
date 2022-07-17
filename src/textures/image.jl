struct ImageTexture <: Texture
    data::Matrix{Pnt3}

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
            dat
        )
    end
end

function (it::ImageTexture)(si::SurfaceInteraction)
    u, v = si.uv
    l, w = size(it.data)
    L = Int(floor(u*l)+1)
    W = Int(floor(v*w)+1)
    return it.data[L,W]
end
