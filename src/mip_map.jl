struct ResampleWeight
	first_texel::Int64
	weight::Pnt4
end

function resample_weights(old_res::Int64, new_res::Int64)::Vector{ResampleWeight}
	@assert new_res > old_res
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

struct MIPMap{T <: Union{Spectrum, Float64}}
	do_trilinear::Bool
	max_anisotropy::Float64
	wrap_mode::Int8
	resolution::Pnt2i
	pyramid::Vector{Matrix{T}}
	pyrsize::Vector{Pnt2i}
	weight_lut::Vector{Float64}

	function MIPMap(
		resolution::Pnt2i, 
		data::Union{Vector{Float64}, Vector{Spectrum}},
		convert_to_float::Bool,
		do_trilinear::Bool=false, 
		max_anisotropy::Float64=8.0, 
		wrap_mode::Int8=Int8(1)
	)
		data_type = convert_to_float ? Float64 : Spectrum
		resampled = false
		res_pow_2 = Pnt2(0,0)
		if (!ispow2(resolution.x)) || (!ispow2(resolution.y))
			resampled = true
			# Resample image to power-of-two resolution
			res_pow_2 = Pnt2i(round_up_pow2(resolution.x), round_up_pow2(resolution.y))
			@info "Resampling MIPMap from $(resolution) to $(res_pow_2). Ratio = $((res_pow_2.x * res_pow_2.y)/(resolution.x * resolution.y))"

			for x in 1:length(data)
				@info "Original Image $x $(data[x])"
			end
			@info "------------------------------------------------"
			
			# Resample image in $s$ direction
			s_weights = resample_weights(resolution.x, res_pow_2.x)
			resampled_image = Vector{data_type}(undef, res_pow_2.x * res_pow_2.y)

			for x in 1:length(s_weights)
				@info "Original Image $x $(s_weights[x])"
			end
			@info "------------------------------------------------"

			
			# apply _sweights_ t zoom in $s$ direction
			for t in 0:(resolution.y-1)
				for s in 0:(res_pow_2.x-1)
					# compute texel $(s,t)$ in $s$-zoomed image
					resampled_image[t * res_pow_2.x + s + 1] = data[1] * 0.0 # JOHN HACK LOL
					for j in 0:3
						orig_s = s_weights[s+1].first_texel + j
						if wrap_mode == Int8(0) # repeat
							@assert false
							orig_s = orig_s % resolution.x
						elseif wrap_mode == Int8(1) # clamp
							orig_s = clamp(orig_s, 0, resolution.x - 1)
						else
							@assert false
						end
						
						if (orig_s >= 0) && (orig_s < resolution.x)
							resampled_image[t * res_pow_2.x + s + 1] = resampled_image[t * res_pow_2.x + s + 1] .+ (s_weights[s+1].weight[j+1] .* data[t * resolution.x + orig_s + 1])
							@info "MIPMAP READ: $(s), $(orig_s), $(t), $(j), $(resampled_image[t * res_pow_2.x + s + 1]) $(s_weights[s+1].weight[j+1]), $(data[t * resolution.x + orig_s + 1])"

						end
					end
				end
			end
			@info "------------------------------------------------"


			for x in 1:length(resampled_image)
				@info "Resampled Image $x $(resampled_image[x])"
			end
			@info "------------------------------------------------"


			# resample image in $t$ direction
			t_weights = resample_weights(resolution.y, res_pow_2.y)
			for s in 0:(res_pow_2.x - 1)
				work_data = Vector{data_type}(undef, res_pow_2.y)
				for t in 0:(res_pow_2.y - 1)
					work_data[t+1] = data[1] * 0.0 # BIG BRAIN JOHN HACK
					for j in 0:3
						offset = t_weights[t+1].first_texel + j
						if wrap_mode == Int8(0) # repeat
							offset = offset % resolution.y
						elseif wrap_mode == Int8(1) # clamp
							offset = clamp(offset, 0, resolution.y - 1)
						else
							@assert false
						end
						
						if (offset >= 0) && (offset < resolution.y)
							# @info "MIPMAP READ: $(s), $(t), $(offset * res_pow_2.x + s) = $(resampled_image[offset * res_pow_2.x + s + 1])"
							work_data[t+1] += t_weights[t+1].weight[j+1] * resampled_image[offset * res_pow_2.x + s + 1]
						end
					end
				end
				for t in 0:(res_pow_2.y - 1)
					resampled_image[t * res_pow_2.x + s + 1] = clamp.(work_data[t+1], 0, typemax(Float64))
				end
			end
			for x in 1:length(resampled_image)
				@info "Resampled Image $x $(resampled_image[x])"
			end
			@info "------------------------------------------------"
		end
		
		# initialize levels of MIPMap from image
		n_levels = 1 + log_2_int(UInt32(max(maximum(res_pow_2), maximum(resolution))))
		@info "N LEVELS: $(n_levels)" 

		pyramid = Vector{Matrix{data_type}}(undef, n_levels)
		pyrsize = Vector{Pnt2i}(undef, n_levels) # JOHN HACK oh god i hope this doesnt bite me later
		
		# Initialize most detailed level of MIPMap
		pyrsize[1] = resampled ? res_pow_2 : resolution
		# JOHN HACK: this is big brain shit but in the bad way
		# JOHN HACK TODO
		# if you have a 5x5 matrix mat[5,5] == mat[25] so I can get rid of this reshape! I think!
		pyramid[1] = reshape(resampled ? resampled_image : data, (pyrsize[1].x, pyrsize[1].y)) # yeehaw
		

		# @info "PYRAMID TESTING: $(pyramid[1][2+1, 6+1]) $(pyramid[1][6+1, 2+1])"

		for i in 1:(n_levels-1)
			# Initialize $i$th MIPMap level from $i-1$st level
			s_res::Int64 = max(1, pyrsize[i-1+1].x ÷ 2)
			t_res::Int64 = max(1, pyrsize[i-1+1].y ÷ 2)
			# @info "PYR BUILD: $(i), $(s_res), $(t_res)"
			pyramid[i+1] = zeros(data_type, s_res, t_res)
			pyrsize[i+1] = Pnt2(s_res, t_res)

			for t in 0:(t_res-1)
				for s in 0:(s_res-1)
					a = texel(pyramid[i - 1 + 1], pyrsize[i - 1 + 1], wrap_mode, 2 * s    , 2 * t    )
					b = texel(pyramid[i - 1 + 1], pyrsize[i - 1 + 1], wrap_mode, 2 * s + 1, 2 * t    )
					c = texel(pyramid[i - 1 + 1], pyrsize[i - 1 + 1], wrap_mode, 2 * s    , 2 * t + 1)
					d = texel(pyramid[i - 1 + 1], pyrsize[i - 1 + 1], wrap_mode, 2 * s + 1, 2 * t + 1)
					tmp = 0.25 * (a + b + c + d)
					pyramid[i+1][s+1, t+1] = tmp
					
				end
			end

			for s in 0:(s_res-1)
				for t in 0:(t_res-1)
					@info "PYRAMID: ($i, $(s), $(t)) $(pyramid[i+1][s+1,t+1])"
				end
			end
		end


    	weight_lut = zeros(Float64, 128) # JOHN HACK HARDCODING
		# Initialize EWA filter weights if needed
		if weight_lut[0+1] == 0.0
			for i in 1:(length(weight_lut)-1)
				alpha = 2.0
				r2 = i / (length(weight_lut) - 1.0)
				weight_lut[i+1] = -exp(-alpha * r2) - exp(-alpha)
			end
		end

		return new{data_type}(
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

function texel(l::Matrix{T}, size::Pnt2i, wrap_mode::Int8, s::Int64, t::Int64)::T where {T <: Union{Spectrum, Float64}}
	x, y = size.x, size.y
	if wrap_mode == Int8(0) # repeat
		@assert false # THIS IS GIVING INDEX OUT OF BOUNDS ERRORS
		s = s % x
		t = t % y
	elseif wrap_mode == Int8(1) # clamp
		s = clamp(s, 0, x - 1)
		t = clamp(t, 0, y - 1)
	elseif wrap_mode == Int8(2) # black
		if (s < 0) || (s > x) || (t < 0) || (t > y)
			return T == Float64 ? 0.0 : spectrum_from_float(0.0)
		end
	else
		@assert false
	end
	return l[s + 1, t + 1]
end

function levels(mip_map::MIPMap)::Int64
	return length(mip_map.pyramid)
end

function lerp(t::Float64, a::T, b::T)::T where {T <: Union{Spectrum, Float64}}
	return t .* a + (1.0 - t) .* b 
end

function triangle(mip_map::MIPMap{T}, level::Int64, st::Pnt2)::T where {T <: Union{Spectrum, Float64}}
	level = clamp(level, 0, levels(mip_map) - 1)
	s = st.x * mip_map.pyrsize[level + 1].x - 0.5
	t = st.y * mip_map.pyrsize[level + 1].y - 0.5
	s0::Int64 = floor(s)
	t0::Int64 = floor(t)
	ds = s - s0
	dt = t - t0
	return (1 - ds) * (1 - dt) * texel(mip_map.pyramid[level + 1], mip_map.pyrsize[level + 1], mip_map.wrap_mode, s0    , t0) + 
		   (1 - ds) *       dt * texel(mip_map.pyramid[level + 1], mip_map.pyrsize[level + 1], mip_map.wrap_mode, s0    , t0 + 1) + 
		         ds * (1 - dt) * texel(mip_map.pyramid[level + 1], mip_map.pyrsize[level + 1], mip_map.wrap_mode, s0 + 1, t0) + 
				 ds *       dt * texel(mip_map.pyramid[level + 1], mip_map.pyrsize[level + 1], mip_map.wrap_mode, s0 + 1, t0 + 1)
end

function lookup(mip_map::MIPMap{T}, st::Pnt2, width::Float64=0.0)::T where {T <: Union{Spectrum, Float64}}
	# compute MIPMap level for trilienar filtering
	level::Float64 = levels(mip_map) - 1.0 + log2(max(width, 1e-8))
	
	# preform trilinear interpolation at the appropriate MIPMap level
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

function lookup(mip_map::MIPMap{T}, st::Pnt2, dst0::Vec2, dst1::Vec2)::T where {T <: Union{Spectrum, Float64}}
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
		dst1 .*= scale
		minor_length .*= scale
	end
	if minor_length == 0.0
		return triangle(mip_map, 0, st)
	end
   
	# chose level of detail for EWA lookup and perform EWA filtering
	lod = max(0.0, levels(mip_map) - 1.0 + log2(minor_length))
	ilod::Int64 = floor(lod)
	return lerp(lod-ilod, EWA(mip_map, ilod, st, dst0, dst1), EWA(mip_map, ilod+1, st, dst0, dst1))
end

function EWA(mip_map::MIPMap{T}, level::Int64, st::Pnt2, dst0::Vec2, dst1::Vec2)::T where {T <: Union{Spectrum, Float64}}
	if level >= levels(mip_map)
		return texel(mip_map.pyramid[levels(mip_map) - 1 + 1], mip_map.pyrsize[levels(mip_map) - 1 + 1], mip_map.wrap_mode, 0, 0)
	end

	# Convert EWA coordinates to appropriate scale for level
	st = Pnt2(
		st.x * mip_map.pyrsize[level-1].x - 0.5,
		st.y * mip_map.pyrsize[level-1].y - 0.5
	)
	dst0::Vec2 = dst0 .* mip_map.pyrsize[level-1]
	dst1::Vec2 = dst1 .* mip_map.pyrsize[level-1]

	# Compute ellipse coefficients to bound EWA filter region
	A = dst0[1+1] * dst0[1+1] + dst1[1+1] * dst1[1+1] + 1
	B = -2 * (dst0[0+1] * dst0[1+1] + dst1[0+1] * dst1[1+1]);
	C = dst0[0+1] * dst0[0+1] + dst1[0+1] * dst1[0+1] + 1
	invF = 1 / (A * C - B * B * 0.25)

	A *= invF
	B *= invF
	C *= invF

	# Compute the ellipse's $(s,t)$ bounding box in texture space
	det = -B * B + 4 * A * C;
	invDet = 1 / det;
	uSqrt = sqrt(det * C)
	vSqrt = sqrt(A * det)
	s0 = ceil(st[0+1] - 2 * invDet * uSqrt)
	s1 = floor(st[0+1] + 2 * invDet * uSqrt)
	t0 = ceil(st[1+1] - 2 * invDet * vSqrt)
	t1 = floor(st[1+1] + 2 * invDet * vSqrt)

	# Scan over ellipse bound and compute quadratic equation
	total = mip_map.pyramid[1][1] * 0.0
	sumWts = 0.0
	for it in t0:t1
		tt = it - st[1+1]
		for is in s0:s1
			ss = is - st[0+1]
			# Compute squared radius and filter texel if inside ellipse
			r2 = A * ss * ss + B * ss * tt + C * tt * tt
			if r2 < 1.0
				index::Int64 = min(floor(r2 * WeightLUTSize), length(mip_map.weight_lut) - 1) # HARD CODE
				weight = mip_map.weight_lut[index+1]
				total = total + texel(mip_map.pyramid[level+1], mip_map.pyramid_size[level+1], is, it) * weight
				sumWts += weight
			end
		end
	end
	return total / sumWts
end