struct ResampleWeight
	first_texel::Int64
	weight::Pnt4
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

			i = 0
			for x in 1:resolution.x
				for y in 1:resolution.y
					i += 1
					@info "MIPMAP: ($(x), $(y)) = $(i) = $(data[i])\n"
				end
			end
			
			# Resample image in $s$ direction
			s_weights = resample_weights(resolution.x, res_pow_2.x)
			
			# apply _sweights_ t zoom in $s$ direction
			for t in 0:resolution.y
				for s in 0:res_pow_2
					# compute texel $(s,t)$ in $s$-zoomed image
					resampled_image[t * res_pow_2.x + s + 1] = 0.0
					for j in 0:4
						orig_s = s_weights[s+1].first_texel + j
						if wrap_mode == Int8(0) # repeat
							orig_s = orig_s % resolution.x
						elseif wrap_mode == Int8(1) # clamp
							orig_s = clamp(orig_s, 0, resolution.x - 1)
						else
							@assert false
						end
						
						if (orig_s >= 0) && (orig_s < resolution.x)
							resampled_image[t * res_pow_2.x + s + 1] += s_weights[s+1].weight[j+1] * data[t * resolution.x + orig_s + 1]
						end
					end
				end
			end
			
			# resample image in $t$ direction
			t_weights = resample_weights(resolution.y, res_pow_2.y)
			for s in 0:res_pow_2.x
				for t in 0:res_pow_2.y
					for j in 0:4
						offset = t_weights[t+1].first_texel + j
						if wrap_mode == Int8(0) # repeat
							offset = offset % resolution.y
						elseif wrap_mode == Int8(1) # clamp
							offset = clamp(offset, 0, resolution.y - 1)
						else
							@assert false
						end
						
						if (offset >= 0) && (offset < resolution.y)
							work_data[t+1] += t_weights[t+1].weights[j+1] * resampled_image[offset * res_pow_2.x + s + 1]
						end
					end
				end
				for t in 0:res_pow_2.y
					resampled_image[t * res_pow_2.x + s + 1] = clamp(work_data, 0, 1)
				end
			end
		end
		
		# initialize levels of MIPMap from image
		n_levels = 1 + log_2_int(max.(resolution))
		
		# Initialize most detailed level of MIPMap
		pyramid[1] = resampled ? resampled_image : data
		
		for i in 1:levels
			# Initialize $i$th MIPMap level from $i-1$st level
			s_res = max(1, u_size(pyramid[i-1+1])/2)
			t_res = max(1, v_size(pyramid[i-1+1])/2)
			pyramid[i+1] = zeros(s_res, t_res)

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