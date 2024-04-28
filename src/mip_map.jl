# TODO
# stop using Int64 all over the place here and do conversion ONCE

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
		@info "ResampleWeights: $(i) $(first_texel) $(weight)"
	end
	return wt
end

struct MIPMap
	do_trilinear::Bool
	max_anisotropy::Float64
	wrap_mode::Int8
	resolution::Pnt2
	pyramid::Vector{Matrix{T}} where T <: Union{Spectrum, Float64}
	pyrsize::Vector{Pnt2}
	weight_lut::Vector{Float64}

	function MIPMap(
		resolution::Pnt2, 
		data::Vector{T} where T <: Union{Spectrum, Float64}, 
		do_trilinear::Bool=false, 
		max_anisotropy::Float64=8.0, 
		wrap_mode::Int8=Int8(1)
	)
		resampled = false
		if (!ispow2(Int64(resolution.x))) || (!ispow2(Int64(resolution.y)))
			resampled = true
			# Resample image to power-of-two resolution
			res_pow_2 = Pnt2(round_up_pow2(Int64(resolution.x)), round_up_pow2(Int64(resolution.y)))
			@info "Resampling MIPMap from $(resolution) to $(res_pow_2). Ratio = $((res_pow_2.x * res_pow_2.y)/(resolution.x * resolution.y))"

			# i = 0
			# for x in 1:resolution.x
			# 	for y in 1:resolution.y
			# 		i += 1
			# 		@info "MIPMAP: ($(x), $(y)) = $(i) = $(data[i])\n"
			# 	end
			# end
			
			# Resample image in $s$ direction
			s_weights = resample_weights(Int64(resolution.x), Int64(res_pow_2.x))
			resampled_image = Vector{typeof(data[1])}(undef, Int64(res_pow_2.x * res_pow_2.y))
			
			# apply _sweights_ t zoom in $s$ direction
			for t in 0:(resolution.y-1)
				for s in 0:Int64(res_pow_2.x-1)
					# compute texel $(s,t)$ in $s$-zoomed image
					resampled_image[Int64(t * res_pow_2.x + s + 1)] = data[1] * 0.0 # JOHN HACK LOL
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
							@info "MIPMAP READ: $(s), $(t), $(t * resolution.x + orig_s) = $(data[Int64(t * resolution.x + orig_s + 1)])"
							resampled_image[Int64(t * res_pow_2.x + s + 1)] += s_weights[s+1].weight[j+1] * data[Int64(t * resolution.x + orig_s + 1)]
						end
					end
				end
			end
			
			# resample image in $t$ direction
			t_weights = resample_weights(Int64(resolution.y), Int64(res_pow_2.y))
			for s in 0:Int64(res_pow_2.x - 1)
				work_data = Vector{typeof(data[1])}(undef, Int64(res_pow_2.y))
				for t in 0:Int64(res_pow_2.y - 1)
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
							@info "MIPMAP READ: $(s), $(t), $(offset * res_pow_2.x + s) = $(resampled_image[Int64(offset * res_pow_2.x + s + 1)])"
							work_data[t+1] += t_weights[t+1].weight[j+1] * resampled_image[Int64(offset * res_pow_2.x + s + 1)]
						end
					end
				end
				for t in 0:Int64(res_pow_2.y - 1)
					resampled_image[Int64(t * res_pow_2.x + s + 1)] = clamp.(work_data[t+1], 0, typemax(Float64))
				end
			end
		end
		
		# initialize levels of MIPMap from image
		n_levels = 1 + log_2_int(UInt32(max(maximum(res_pow_2), maximum(resolution))))
		@info "N LEVELS: $(n_levels)" 

		pyramid = Vector{Matrix{typeof(data[1])}}(undef, n_levels)
		pyrsize = Vector{Pnt2}(undef, n_levels) # JOHN HACK oh god i hope this doesnt bite me later
		
		# Initialize most detailed level of MIPMap
		pyrsize[1] = resampled ? res_pow_2 : resolution
		# JOHN HACK: this is big brain shit but in the bad way
		# JOHN HACK TODO
		# if you have a 5x5 matrix mat[5,5] == mat[25] so I can get rid of this reshape! I think!
		pyramid[1] = reshape(resampled ? resampled_image : data, (Int64(pyrsize[1].x), Int64(pyrsize[1].y))) # yeehaw
		

		@info "PYRAMID TESTING: $(pyramid[1][2+1, 6+1]) $(pyramid[1][6+1, 2+1])"

		for i in 1:(n_levels-1)
			# Initialize $i$th MIPMap level from $i-1$st level
			s_res = Int64(max(1, pyrsize[i-1+1].x/2))
			t_res = Int64(max(1, pyrsize[i-1+1].y/2))
			@info "PYR BUILD: $(i), $(s_res), $(t_res)"
			pyramid[i+1] = zeros(typeof(data[1]), s_res, t_res)
			pyrsize[i+1] = Pnt2(s_res, t_res)

			for t in 0:(t_res-1)
				for s in 0:(s_res-1)
					a = texel(pyramid[i - 1 + 1], pyrsize[i - 1 + 1], wrap_mode, 2 * s    , 2 * t    )
					b = texel(pyramid[i - 1 + 1], pyrsize[i - 1 + 1], wrap_mode, 2 * s + 1, 2 * t    )
					c = texel(pyramid[i - 1 + 1], pyrsize[i - 1 + 1], wrap_mode, 2 * s    , 2 * t + 1)
					d = texel(pyramid[i - 1 + 1], pyrsize[i - 1 + 1], wrap_mode, 2 * s + 1, 2 * t + 1)
					tmp = 0.25 * (a + b + c + d)
					pyramid[i+1][s+1, t+1] = tmp
					# @info "\tlil texel test $(a), $(b), $(c), $(d), $(tmp)"
					@info "\tlil texel test $(tmp)"
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

		return new(
			do_trilinear,
			max_anisotropy,
			wrap_mode,
			resolution,
			pyramid,
			pyrsize,
			weight_lut
		)
	end
end

function texel(l::Matrix{Spectrum}, size::Pnt2, wrap_mode::Int8, s::Int64, t::Int64)::Spectrum
	x, y = Int64(size.x), Int64(size.y)
	# hacky, not fucking with indexing in here. making me do that before texel is called
	if wrap_mode == Int8(0) # repeat
		s = s % x
		t = t % y
	elseif wrap_mode == Int8(1) # clamp
		s = clamp(s, 0, x - 1)
		t = clamp(t, 0, y - 1)
	elseif wrap_mode == Int8(2) # black
		black = spectrum_from_float(0.0)
		if (s < 0) || (s > x) || (t < 0) || (t > y)
			return black
		end
	else
		@assert false
	end
	return l[s + 1, t + 1]
end

function levels(mipmap::MIPMap)::Int64
	return length(mipmap.pyramid)
end

function lerp(t::Float64, a::Spectrum, b::Spectrum)::Spectrum
	return t .* a + (1.0 - t) .* b 
end

function triangle(mip_map::MIPMap, level::Int64, st::Pnt2)::Spectrum
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

function lookup(mipmap::MIPMap, st::Pnt2, width::Float64)::Spectrum
	# compute MIPMap level for trilienar filtering
	level::Float64 = levels(mipmap) - 1.0 + log2(max(width, 1e-8))
	
	# preform trilinear interpolation at the appropriate MIPMap level
	if level < 0
		return triangle(mip_map, 0, st)
	elseif level >= levels(mipmap) - 1
		return texel(mip_map.pyramid[levels(mipmap) - 1], mip_map.pyrsize[levels(mipmap) - 1], mip_map.wrap_mode, 0, 0)
	else
		ilevel::Int64 = floor(level)
		delta = level - ilevel
		return lerp(delta, triangle(mipmap, ilevel, st), triangle(mipmap, ilevel + 1, st))
	end
end

function lookup(mipmap::MIPMap, st::Pnt2, dst0::Vec2, dst1::Vec2)::Spectrum
	if mip_map.do_trilinear
		width = max(maximum(abs.(dst0)), maximum(abs.(dst1)))
		return lookup(mipmap, st, width)
	end

	# compute ellipse minor and major axes
	if length_squared(dst0) < length_squared(dst1)
		dst1, dst0 = dst0, dst1
	end
	major_length = length_pbrt(dst0)
	minor_length = length_pbrt(dst1)
   
	# clamp ellipse eccentricity if too large
	if (minor_length * max_anisotropy < major_length) && (minor_length > 0)
				scale = major_length / (minor_length * max_anisotropy)
				dst1 .*= scale
				minor_length .*= scale
	end
	if minor_length == 0.0
		return triangle(mip_map, 0.0, st)
	end
   
	# chose level of detail for EWA lookup and perform EWA filtering
	lod = max(0.0, levels(mipmap) - 1.0 + log2(minor_length))
	ilod::Int64 = floor(lod)
	return lerp(lod-ilod, EWA(ilod, st, dst0, dst1), EWA(ilod+1, st, dst0, dst1))
end

function EWA()
	@assert false # not implemented
end