include("../RayTracing.jl")

using Mmap
using Base.Threads
using StaticArrays

struct UniformGridData
    nx::Int
    ny::Int
    nz::Int
    p0::SVector{3, Float32}
    p1::SVector{3, Float32}
    lescale::Vector{Float32}
    density::Vector{Float32}
end

# ──────────────────────────────────────────────
# Entry point
# ──────────────────────────────────────────────
function parse_uniformgrid(filepath::String)::UniformGridData
    io = open(filepath, "r")
    buf = mmap(io, Vector{UInt8})
    result = parse_uniformgrid_buf(buf)
    close(io)
    result
end

function parse_uniformgrid_buf(buf::Vector{UInt8})::UniformGridData
    n = length(buf)
    nx = ny = nz = 0
    p0 = p1 = SVector{3,Float32}(0f0, 0f0, 0f0)
    lescale_offset = -1
    density_offset  = -1

    # ── Pass 1: scan for quoted keys anywhere in the buffer ──
    pos = 1
    while pos <= n
        # find next '"' — keys can be anywhere on any line
        @inbounds while pos <= n && buf[pos] != UInt8('"'); pos += 1; end
        pos > n && break

        # find closing '"' of key
        key_start = pos + 1
        pos = key_start
        @inbounds while pos <= n && buf[pos] != UInt8('"'); pos += 1; end
        key = String(buf[key_start:pos-1])
        pos += 1  # skip closing '"'

        # find '['
        @inbounds while pos <= n && buf[pos] != UInt8('['); pos += 1; end
        pos += 1  # skip '['
        bracket_pos = pos

        if key == "integer nx"
            nx = parse_single_int(buf, bracket_pos, bracket_pos + 20)
        elseif key == "integer ny"
            ny = parse_single_int(buf, bracket_pos, bracket_pos + 20)
        elseif key == "integer nz"
            nz = parse_single_int(buf, bracket_pos, bracket_pos + 20)
        elseif key == "point3 p0"
            p0 = parse_point3(buf, bracket_pos, bracket_pos + 60)
        elseif key == "point3 p1"
            p1 = parse_point3(buf, bracket_pos, bracket_pos + 60)
        elseif key == "float Lescale"
            lescale_offset = bracket_pos
        elseif key == "float density"
            density_offset = bracket_pos
        end

        # skip to closing ']' of this field so the next '"' we find is a new key
        # EXCEPT for the big arrays — we don't want to scan 2GB looking for their ']'
        if key != "float Lescale" && key != "float density"
            @inbounds while pos <= n && buf[pos] != UInt8(']'); pos += 1; end
            pos += 1  # skip ']'
        else
            # just advance past the '[' we already recorded; next '"' will be after ']'
            # but we don't scan for it — leave pos right after '[' and let the
            # outer '"' scanner skip over the data naturally by finding the next '"'
            # which will be beyond the ']' anyway
            pos = bracket_pos
        end
    end

    @assert nx > 0 && ny > 0 && nz > 0   "Failed to parse grid dimensions"
    @assert lescale_offset > 0             "float Lescale not found"
    @assert density_offset  > 0            "float density not found"

    count = nx * ny * nz

    # ── Pass 2: parse the two big arrays from recorded offsets ──
    lescale = Vector{Float32}(undef, count)
    density  = Vector{Float32}(undef, count)

    @sync begin
        Threads.@spawn parse_float_array_threaded!(lescale, buf, lescale_offset, n, count)
        Threads.@spawn parse_float_array_threaded!(density,  buf, density_offset,  n, count)
    end

    UniformGridData(nx, ny, nz, p0, p1, lescale, density)
end

# ──────────────────────────────────────────────
# Key + bracket extraction
# ──────────────────────────────────────────────
@inline function extract_key(buf::Vector{UInt8}, from::Int, to::Int)
    i = from
    @inbounds while i <= to && buf[i] != UInt8('"'); i += 1; end
    i += 1
    key_start = i
    @inbounds while i <= to && buf[i] != UInt8('"'); i += 1; end
    key = String(buf[key_start:i-1])
    @inbounds while i <= to && buf[i] != UInt8('['); i += 1; end
    return key, i + 1
end

# ──────────────────────────────────────────────
# Scalar int
# ──────────────────────────────────────────────
@inline function parse_single_int(buf::Vector{UInt8}, from::Int, to::Int)::Int
    i = from
    @inbounds while i <= to && (buf[i] == UInt8(' ') || buf[i] == UInt8('\t')); i += 1; end
    val = 0
    @inbounds while i <= to
        c = buf[i]
        UInt8('0') <= c <= UInt8('9') || break
        val = val * 10 + (c - UInt8('0'))
        i += 1
    end
    val
end

# ──────────────────────────────────────────────
# point3: exactly 3 floats between [ ]
# ──────────────────────────────────────────────
@inline function parse_point3(buf::Vector{UInt8}, from::Int, to::Int)::SVector{3,Float32}
    tmp = MVector{3,Float32}(undef)
    i = from
    @inbounds for k in 1:3
        while i <= to && (buf[i] == UInt8(' ') || buf[i] == UInt8('\t')); i += 1; end
        v, i = parse_one_float(buf, i, to)
        tmp[k] = v
    end
    SVector(tmp)
end

# ──────────────────────────────────────────────
# Single float parser — returns (value, next_pos)
# ──────────────────────────────────────────────
@inline function parse_one_float(buf::Vector{UInt8}, i::Int, to::Int)::Tuple{Float32,Int}
    neg = false
    @inbounds if i <= to && buf[i] == UInt8('-')
        neg = true; i += 1
    elseif i <= to && buf[i] == UInt8('+')
        i += 1
    end

    int_part = Int64(0)
    @inbounds while i <= to
        c = buf[i]
        UInt8('0') <= c <= UInt8('9') || break
        int_part = int_part * 10 + (c - UInt8('0'))
        i += 1
    end

    frac_part  = Int64(0)
    frac_scale = 1.0f0
    @inbounds if i <= to && buf[i] == UInt8('.')
        i += 1
        while i <= to
            c = buf[i]
            (UInt8('0') <= c <= UInt8('9')) || break
            frac_part  = frac_part * 10 + (c - UInt8('0'))
            frac_scale *= 10.0f0
            i += 1
        end
    end

    val = Float32(int_part) + Float32(frac_part) / frac_scale

    @inbounds if i <= to && (buf[i] == UInt8('e') || buf[i] == UInt8('E'))
        i += 1
        exp_neg = false
        if buf[i] == UInt8('-'); exp_neg = true; i += 1
        elseif buf[i] == UInt8('+'); i += 1
        end
        exp = 0
        while i <= to && UInt8('0') <= buf[i] <= UInt8('9')
            exp = exp * 10 + (buf[i] - UInt8('0'))
            i += 1
        end
        val *= exp_neg ? 10.0f0^(-exp) : 10.0f0^exp
    end

    (neg ? -val : val), i
end

# ──────────────────────────────────────────────
# Threaded large float array parser
# ──────────────────────────────────────────────
function parse_float_array_threaded!(out::Vector{Float32}, buf::Vector{UInt8},
                                      from::Int, buflen::Int, count::Int)
    nt = min(nthreads(), count)

    # find end of this array's data
    data_end = from
    @inbounds while data_end <= buflen && buf[data_end] != UInt8(']')
        data_end += 1
    end
    data_end -= 1

    chunk_bytes = (data_end - from + 1) ÷ nt

    # snap boundaries to whitespace
    boundaries = Vector{Tuple{Int,Int}}(undef, nt)
    lo = from
    @inbounds for t in 1:nt
        hi = t == nt ? data_end : lo + chunk_bytes - 1
        while hi < data_end && buf[hi] != UInt8(' ')  &&
                                buf[hi] != UInt8('\t') &&
                                buf[hi] != UInt8('\n')
            hi += 1
        end
        boundaries[t] = (lo, hi)
        lo = hi + 1
    end

    # Pass 1: count tokens per chunk
    counts = zeros(Int, nt)
    @threads for t in 1:nt
        l, h = boundaries[t]
        in_tok = false
        c = 0
        @inbounds for i in l:h
            b = buf[i]
            is_sp = b == UInt8(' ')  || b == UInt8('\t') ||
                    b == UInt8('\n') || b == UInt8('\r')
            if !is_sp && !in_tok
                c += 1; in_tok = true
            elseif is_sp
                in_tok = false
            end
        end
        counts[t] = c
    end

    # prefix offsets
    offsets = Vector{Int}(undef, nt)
    offsets[1] = 0
    for t in 2:nt
        offsets[t] = offsets[t-1] + counts[t-1]
    end
    @assert offsets[end] + counts[end] == count "Token count mismatch: expected $count, got $(offsets[end] + counts[end])"

    # Pass 2: parse into output
    @threads for t in 1:nt
        l, h   = boundaries[t]
        idx    = offsets[t]
        i      = l
        in_tok = false
        tok_i  = l

        @inbounds while i <= h
            b     = buf[i]
            is_sp = b == UInt8(' ')  || b == UInt8('\t') ||
                    b == UInt8('\n') || b == UInt8('\r')
            if !is_sp && !in_tok
                tok_i = i; in_tok = true
            elseif is_sp && in_tok
                v, _ = parse_one_float(buf, tok_i, i - 1)
                idx += 1; out[idx] = v
                in_tok = false
            end
            i += 1
        end
        if in_tok
            v, _ = parse_one_float(buf, tok_i, h)
            idx += 1; out[idx] = v
        end
    end
end

path = RayTracing.jmfp("/Users/johnmyslinski/Documents/pbrt-v4-volumes/scenes/anemone/geometry/anemone_medium_downsampled.pbrt")

println("Small n fast")
small_n_fast = parse_uniformgrid(path)
@time parse_uniformgrid(path)

println("Small n slow")
nx, ny, nz, density, Lescale, nothing, p0, p1 = RayTracing.parse_media(path)
@time RayTracing.parse_media(path)

@assert nx == small_n_fast.nx
@assert ny == small_n_fast.ny
@assert nz == small_n_fast.nz
@assert p0 == small_n_fast.p0
@assert p1 == small_n_fast.p1
@assert abs(sum(density) - sum(small_n_fast.density)) < 5.0
@assert abs(sum(Lescale) - sum(small_n_fast.lescale)) < 5.0

println("Big n fast")
path = RayTracing.jmfp("/Users/johnmyslinski/Documents/pbrt-v4-volumes/scenes/anemone/geometry/anemone_medium.pbrt")
big_n_fast = parse_uniformgrid(path)
@time parse_uniformgrid(path)

nx, ny, nz, density, Lescale, nothing, p0, p1 = RayTracing.parse_media(path)

@assert nx == big_n_fast.nx
@assert ny == big_n_fast.ny
@assert nz == big_n_fast.nz
@assert p0 == big_n_fast.p0
@assert p1 == big_n_fast.p1
@assert abs(sum(density) - sum(big_n_fast.density)) < 5.0
@assert abs(sum(Lescale) - sum(big_n_fast.lescale)) < 5.0