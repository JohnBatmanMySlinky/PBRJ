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

    # byte offsets of the '[' content start for the two big arrays
    lescale_offset = -1
    density_offset  = -1

    # ── Pass 1: scan all lines, parse cheap fields, record offsets for grids ──
    pos = 1
    while pos <= n
        line_end = pos
        @inbounds while line_end <= n && buf[line_end] != UInt8('\n')
            line_end += 1
        end

        key, bracket_pos = extract_key(buf, pos, line_end)

        if key == "integer nx"
            nx = parse_single_int(buf, bracket_pos, line_end)
        elseif key == "integer ny"
            ny = parse_single_int(buf, bracket_pos, line_end)
        elseif key == "integer nz"
            nz = parse_single_int(buf, bracket_pos, line_end)
        elseif key == "point3 p0"
            p0 = parse_point3(buf, bracket_pos, line_end)
        elseif key == "point3 p1"
            p1 = parse_point3(buf, bracket_pos, line_end)
        elseif key == "float Lescale"
            lescale_offset = bracket_pos   # just record, don't parse yet
        elseif key == "float density"
            density_offset = bracket_pos
        end

        pos = line_end + 1
    end

    @assert nx > 0 && ny > 0 && nz > 0 "Failed to parse grid dimensions"
    @assert lescale_offset > 0          "float Lescale row not found"
    @assert density_offset  > 0         "float density row not found"

    count = nx * ny * nz

    # ── Pass 2: parse the two big arrays using recorded offsets ──
    # These can themselves run concurrently if you have cores to spare
    lescale = Vector{Float32}(undef, count)
    density  = Vector{Float32}(undef, count)

    # Outer parallelism: parse both grids simultaneously
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
data_v2 = parse_uniformgrid(path)
@time data_v2 = parse_uniformgrid(path)

println("Small n slow")
RayTracing.parse_media(path)
@time RayTracing.parse_media(path)

println("Big n fast")
path = RayTracing.jmfp("/Users/johnmyslinski/Documents/pbrt-v4-volumes/scenes/anemone/geometry/anemone_medium.pbrt")
data_v2 = parse_uniformgrid(path)
@time data_v2 = parse_uniformgrid(path)