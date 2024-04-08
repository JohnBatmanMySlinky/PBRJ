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
		# @info "ResampleWeights: $(i) $(first_texel) $(weight)"
	end
	return wt
end

struct MIPMap
	do_trilinear::Bool
	max_anisotropy::Float64
	image_wrap::Int8
	resolution::Pnt2
	pyramid::Vector{T} where T <: Union{Spectrum, Float64}
	weight_lut::Vector{Float64}

	function MIPMap(
		resolution::Pnt2, 
		data::Vector{T} where T <: Union{Spectrum, Float64}, 
		do_trilinear::Bool=false, 
		max_anisotropy::Float64=8.0, 
		wrap_mode::Int8=Int8(0)
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
							orig_s = orig_s % resolution.x
						elseif wrap_mode == Int8(1) # clamp
							orig_s = clamp(orig_s, 0, resolution.x - 1)
						else
							@assert false
						end
						
						if (orig_s >= 0) && (orig_s < resolution.x)
							# @info "MIPMAP READ: $(s), $(t), $(t * resolution.x + orig_s) = $(data[Int64(t * resolution.x + orig_s + 1)])"
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
					resampled_image[Int64(t * res_pow_2.x + s + 1)] = clamp.(work_data[t+1], 0, 1)
				end
			end
		end
		
		# initialize levels of MIPMap from image
		n_levels = 1 + Int64(floor(log(maximum(resolution))))
		@info "N LEVELS: $(n_levels)" 

		pyramid = Vector{Matrix{typeof(data[1])}}(undef, n_levels)
		pyrsize = Vector{Pnt2}(undef, n_levels) # JOHN HACK oh god i hope this doesnt bite me later
		
		# Initialize most detailed level of MIPMap
		pyrsize[1] = resampled ? res_pow_2 : resolution
		pyramid[1] = reshape(resampled ? resampled_image : data, (Int64(pyrsize[1].x), Int64(pyrsize[1].y))) # yeehaw
		# JOHN HACK: this is big brain shit but in the bad way

		for i in 1:(n_levels-1)
			# Initialize $i$th MIPMap level from $i-1$st level
			s_res = Int64(max(1, pyrsize[i-1+1].x/2))
			t_res = Int64(max(1, pyrsize[i-1+1].y/2))
			pyramid[i+1] = zeros(typeof(data[1]), s_res, t_res)
			pyrsize[i+1] = Pnt2(s_res, t_res)

			for t in 0:t_res
				for s in 0:s_res
					pyramid[i+1][s,t] = 0.25 * (
						texel(i - 1, 2 * s    , 2 * t    ) +
						texel(i - 1, 2 * s + 1, 2 * t    ) +
						texel(i - 1, 2 * s    , 2 * t + 1) +
						texel(i - 1, 2 * s + 1, 2 * t + 1)
					)
				end
			end
		end

		# Initialize EWA filter weights if needed
		if weight_lut[0+1] == 0.0
			for i in 1:weight_lut_size
				alpha = 2.0
				r2 = i / (weight_lut_size - 1.0)
				weight_lut[i+1] = -exp(-alpha * r2) - exp(-alpha)
			end
		end
	
		return new(
			do_trilinear,
			max_anisotropy,
			image_wrap,
			resolution,
			pyramid,
			weight_lut
		)
	end
end