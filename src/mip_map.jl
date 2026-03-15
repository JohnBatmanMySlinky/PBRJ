struct ResampleWeight
	first_texel::Int64
	weight::Pnt4
end

function resample_weights(old_res::Int64, new_res::Int64)::Vector{ResampleWeight}
	@assert new_res >= old_res
	wt = Vector{ResampleWeight}(undef, new_res)
	filter_width = 2.0
	for i in 0:(new_res-1)
		center = (i + 0.5) * old_res / new_res
		first_texel = floor((center - filter_width) + 0.5)
		weight = Pnt4(
			lanczos((first_texel + 0.0 + 0.5 - center) / filter_width, 2.0),
			lanczos((first_texel + 1.0 + 0.5 - center) / filter_width, 2.0),
			lanczos((first_texel + 2.0 + 0.5 - center) / filter_width, 2.0),
			lanczos((first_texel + 3.0 + 0.5 - center) / filter_width, 2.0),
		)
		weight /= sum(weight)
		wt[i+1] = ResampleWeight(first_texel, weight)
	end
	return wt
end

const MipTexel = Union{Spectrum, Float64, Float32, Float16, SVector{3, Float32}, SVector{3, Float16}}

mip_clamp(x::AbstractFloat) = clamp(x, zero(x), typemax(typeof(x)))
mip_clamp(x::SVector{3, T}) where T = clamp.(x, zero(T), typemax(T))

struct MIPMap{T <: MipTexel}
	do_trilinear::Bool
	max_anisotropy::Float64
	wrap_mode::Int8
	resolution::Pnt2i
	pyramid::Vector{Matrix{T}}
	pyrsize::Vector{Pnt2i}
	weight_lut::Vector{Float64}

	function MIPMap(
		resolution::Pnt2i,
		data::Vector{T},
		do_trilinear::Bool=false,
		max_anisotropy::Float64=8.0,
		wrap_mode::Int8=Int8(0)
	) where T <: MipTexel
		resampled = false
		res_pow_2 = Pnt2(0,0)
		if (!ispow2(resolution.x)) || (!ispow2(resolution.y))
			resampled = true
			# Resample image to power-of-two resolution
			res_pow_2 = Pnt2i(round_up_pow2(resolution.x), round_up_pow2(resolution.y))

			# Resample image in s direction
			s_weights = resample_weights(resolution.x, res_pow_2.x)
			resampled_image = fill(zero(T), res_pow_2.x * res_pow_2.y)

			for t in 0:(resolution.y-1)
				for s in 0:(res_pow_2.x-1)
					resampled_image[t * res_pow_2.x + s + 1] = zero(T)
					for j in 0:3
						orig_s = s_weights[s+1].first_texel + j
						if wrap_mode == Int8(0) # repeat
							orig_s = mod(orig_s, resolution.x)
						elseif wrap_mode == Int8(1) # clamp
							orig_s = clamp(orig_s, 0, resolution.x - 1)
						else
							@assert false
						end

						if (orig_s >= 0) && (orig_s < resolution.x)
							resampled_image[t * res_pow_2.x + s + 1] = resampled_image[t * res_pow_2.x + s + 1] .+ (eltype(T)(s_weights[s+1].weight[j+1]) .* data[t * resolution.x + orig_s + 1])
						end
					end
				end
			end

			# resample image in t direction
			t_weights = resample_weights(resolution.y, res_pow_2.y)
			for s in 0:(res_pow_2.x - 1)
				work_data = Vector{T}(undef, res_pow_2.y)
				for t in 0:(res_pow_2.y - 1)
					work_data[t+1] = zero(T)
					for j in 0:3
						offset = t_weights[t+1].first_texel + j
						if wrap_mode == Int8(0) # repeat
							offset = mod(offset, resolution.y)
						elseif wrap_mode == Int8(1) # clamp
							offset = clamp(offset, 0, resolution.y - 1)
						else
							@assert false
						end

						if (offset >= 0) && (offset < resolution.y)
							work_data[t+1] += eltype(T)(t_weights[t+1].weight[j+1]) * resampled_image[offset * res_pow_2.x + s + 1]
						end
					end
				end
				for t in 0:(res_pow_2.y - 1)
					resampled_image[t * res_pow_2.x + s + 1] = mip_clamp(work_data[t+1])
				end
			end
		end

		# initialize levels of MIPMap from image
		n_levels = 1 + log_2_int(UInt32(max(maximum(res_pow_2), maximum(resolution))))

		pyramid = Vector{Matrix{T}}(undef, n_levels)
		pyrsize = Vector{Pnt2i}(undef, n_levels)

		# Initialize most detailed level of MIPMap
		pyrsize[1] = resampled ? res_pow_2 : resolution
		pyramid[1] = reshape(resampled ? resampled_image : data, (pyrsize[1].x, pyrsize[1].y))

		for i in 1:(n_levels-1)
			# Initialize ith MIPMap level from i-1st level
			s_res::Int64 = max(1, pyrsize[i-1+1].x ÷ 2)
			t_res::Int64 = max(1, pyrsize[i-1+1].y ÷ 2)
			pyramid[i+1] = fill(zero(T), s_res, t_res)
			pyrsize[i+1] = Pnt2(s_res, t_res)

			for t in 0:(t_res-1)
				for s in 0:(s_res-1)
					a = texel(pyramid[i - 1 + 1], pyrsize[i - 1 + 1], wrap_mode, 2 * s    , 2 * t    )
					b = texel(pyramid[i - 1 + 1], pyrsize[i - 1 + 1], wrap_mode, 2 * s + 1, 2 * t    )
					c = texel(pyramid[i - 1 + 1], pyrsize[i - 1 + 1], wrap_mode, 2 * s    , 2 * t + 1)
					d = texel(pyramid[i - 1 + 1], pyrsize[i - 1 + 1], wrap_mode, 2 * s + 1, 2 * t + 1)
					pyramid[i+1][s+1, t+1] = eltype(T)(0.25) * (a + b + c + d)
				end
			end
		end

    	weight_lut = zeros(Float64, 128) # JOHN HACK HARDCODING
		# Initialize EWA filter weights if needed
		if weight_lut[0+1] == 0.0
			for i in 0:(length(weight_lut)-1)
				alpha = 2.0
				r2 = i / (length(weight_lut) - 1.0)
				weight_lut[i+1] = exp(-alpha * r2) - exp(-alpha)
			end
		end

		return new{T}(
			do_trilinear,
			max_anisotropy,
			wrap_mode,
			pyrsize[1],
			pyramid,
			pyrsize,
			weight_lut
		)
	end
end

function texel(l::Matrix{T}, size::Pnt2i, wrap_mode::Int8, s::Int64, t::Int64)::T where {T <: MipTexel}
	x, y = size.x, size.y
	if wrap_mode == Int8(0) # repeat
		s = mod(s, x)
		t = mod(t, y)
	elseif wrap_mode == Int8(1) # clamp
		s = clamp(s, 0, x - 1)
		t = clamp(t, 0, y - 1)
	elseif wrap_mode == Int8(2) # black
		if (s < 0) || (s > x) || (t < 0) || (t > y)
			return zero(T)
		end
	else
		@assert false
	end
	return l[s + 1, t + 1]
end

function levels(mip_map::MIPMap)::Int64
	return length(mip_map.pyramid)
end

function lerp(t::Float64, a::T, b::T) where {T <: MipTexel}
	ft = eltype(T)(t)
	return (one(eltype(T)) - ft) .* a .+ ft .* b
end

function triangle(mip_map::MIPMap{T}, level::Int64, st::Pnt2)::T where {T <: MipTexel}
	level = clamp(level, 0, levels(mip_map) - 1)
	s = st.x * mip_map.pyrsize[level + 1].x - 0.5
	t = st.y * mip_map.pyrsize[level + 1].y - 0.5

	s0::Int64 = floor(s)
	t0::Int64 = floor(t)
	ds = eltype(T)(s - s0)
	dt = eltype(T)(t - t0)
	return (one(eltype(T)) - ds) * (one(eltype(T)) - dt) * texel(mip_map.pyramid[level + 1], mip_map.pyrsize[level + 1], mip_map.wrap_mode, s0    , t0) +
		   (one(eltype(T)) - ds) *                    dt * texel(mip_map.pyramid[level + 1], mip_map.pyrsize[level + 1], mip_map.wrap_mode, s0    , t0 + 1) +
		                     ds * (one(eltype(T)) - dt) * texel(mip_map.pyramid[level + 1], mip_map.pyrsize[level + 1], mip_map.wrap_mode, s0 + 1, t0) +
				             ds *                    dt * texel(mip_map.pyramid[level + 1], mip_map.pyrsize[level + 1], mip_map.wrap_mode, s0 + 1, t0 + 1)
end

function lookup(mip_map::MIPMap{T}, st::Pnt2, width::Float64=0.0)::T where {T <: MipTexel}
	# compute MIPMap level for trilinear filtering
	level::Float64 = levels(mip_map) - 1.0 + log2(max(width, 1e-8))

	# perform trilinear interpolation at the appropriate MIPMap level
	if level < 0
		return triangle(mip_map, 0, st)
	elseif level >= levels(mip_map) - 1
		return texel(mip_map.pyramid[levels(mip_map) - 1 + 1], mip_map.pyrsize[levels(mip_map) - 1 + 1], mip_map.wrap_mode, 0, 0)
	else
		ilevel::Int64 = floor(level)
		delta = level - ilevel
		return lerp(delta, triangle(mip_map, ilevel, st), triangle(mip_map, ilevel + 1, st))
	end
end

function lookup(mip_map::MIPMap{T}, st::Pnt2, dst0::Vec2, dst1::Vec2)::T where {T <: MipTexel}
	if mip_map.do_trilinear
		width = max(maximum(abs.(dst0)), maximum(abs.(dst1)))
		return lookup(mip_map, st, width)
	end

	# compute ellipse minor and major axes
	if length_squared(dst0) < length_squared(dst1)
		dst1, dst0 = dst0, dst1
	end
	major_length = length_pbrt(dst0)
	minor_length = length_pbrt(dst1)

	# clamp ellipse eccentricity if too large
	if (minor_length * mip_map.max_anisotropy < major_length) && (minor_length > 0)
		scale = major_length / (minor_length * mip_map.max_anisotropy)
		dst1 = dst1 * scale
		minor_length = minor_length * scale
	end

	level = clamp(0, 0, levels(mip_map) - 1)
	s = st.x * mip_map.pyrsize[level + 1].x - 0.5
	t = st.y * mip_map.pyrsize[level + 1].y - 0.5

	s0::Int64 = floor(s)
	t0::Int64 = floor(t)
	ds = eltype(T)(s - s0)
	dt = eltype(T)(t - t0)

	johna = (one(eltype(T)) - ds) * (one(eltype(T)) - dt) * texel(mip_map.pyramid[level + 1], mip_map.pyrsize[level + 1], mip_map.wrap_mode, s0    , t0)
	johnb = (one(eltype(T)) - ds) *                    dt * texel(mip_map.pyramid[level + 1], mip_map.pyrsize[level + 1], mip_map.wrap_mode, s0    , t0 + 1)
	johnc =                   ds * (one(eltype(T)) - dt) * texel(mip_map.pyramid[level + 1], mip_map.pyrsize[level + 1], mip_map.wrap_mode, s0 + 1, t0)
	johnd =                   ds *                    dt * texel(mip_map.pyramid[level + 1], mip_map.pyrsize[level + 1], mip_map.wrap_mode, s0 + 1, t0 + 1)

	if (minor_length == 0) || isinf(minor_length)
		return triangle(mip_map, 0, st)
    end

	# chose level of detail for EWA lookup and perform EWA filtering
	lod = max(0.0, levels(mip_map) - 1.0 + log2(minor_length))
	ilod::Int64 = floor(lod)
	return lerp(lod-ilod, EWA(mip_map, ilod, st, dst0, dst1), EWA(mip_map, ilod+1, st, dst0, dst1))
end

function EWA(mip_map::MIPMap{T}, level::Int64, st::Pnt2, dst0::Vec2, dst1::Vec2)::T where {T <: MipTexel}
	if level >= levels(mip_map) # JOHN INDEXING ADDITION
		return texel(mip_map.pyramid[levels(mip_map) - 1 + 1], mip_map.pyrsize[levels(mip_map) - 1 + 1], mip_map.wrap_mode, 0, 0)
	end

	# Convert EWA coordinates to appropriate scale for level
	st = Pnt2(
		st.x * mip_map.pyrsize[level+1].x - 0.5,
		st.y * mip_map.pyrsize[level+1].y - 0.5
	)
	dst0::Vec2 = dst0 .* mip_map.pyrsize[level+1]
	dst1::Vec2 = dst1 .* mip_map.pyrsize[level+1]

	# Compute ellipse coefficients to bound EWA filter region
	A = dst0[1+1] * dst0[1+1] + dst1[1+1] * dst1[1+1] + 1
	B = -2 * (dst0[0+1] * dst0[1+1] + dst1[0+1] * dst1[1+1]);
	C = dst0[0+1] * dst0[0+1] + dst1[0+1] * dst1[0+1] + 1
	invF = 1 / (A * C - B * B * 0.25)

	A *= invF
	B *= invF
	C *= invF

	# Compute the ellipse's (s,t) bounding box in texture space
	det = -B * B + 4 * A * C;
	invDet = 1.0 / det;
	uSqrt = sqrt(det * C)
	vSqrt = sqrt(A * det)
	s0::Int64 = ceil( st[0+1] - 2 * invDet * uSqrt)
	s1::Int64 = floor(st[0+1] + 2 * invDet * uSqrt)
	t0::Int64 = ceil( st[1+1] - 2 * invDet * vSqrt)
	t1::Int64 = floor(st[1+1] + 2 * invDet * vSqrt)

	# Scan over ellipse bound and compute quadratic equation
	total = zero(T)
	sumWts = 0.0
	for it in t0:t1
		tt = it - st[1+1]
		for is in s0:s1
			ss = is - st[0+1]
			# Compute squared radius and filter texel if inside ellipse
			r2 = A * ss * ss + B * ss * tt + C * tt * tt
			if r2 < 1.0
				index::Int64 = min(floor(r2 * length(mip_map.weight_lut)), length(mip_map.weight_lut) - 1) # HARD CODE
				weight = mip_map.weight_lut[index+1]
				total = total + texel(mip_map.pyramid[level+1], mip_map.pyrsize[level+1], mip_map.wrap_mode, is, it) * eltype(T)(weight)
				sumWts += weight
			end
		end
	end
	return total / eltype(T)(sumWts)
end
