@START_OF_DEBUG_CATEGORY "math"

@logged function optimize(f::Function, params::Vector{Float64}, agression::Float64=100.0, δ::Float64=0.01, good_enough_derivative::Float64=0.1, max_time::Float64=1.0)::Vector{Float64}
	derivatives = [good_enough_derivative+1 for i ∈ 1:length(params)]

	start_time = time()
	while ∃(x->x>good_enough_derivative, derivatives)
		derivatives = [
			(f(mcopy(params, i, x->x+δ)...) - f(mcopy(params, i, x->x-δ)...)) / (2δ)
			for i ∈ 1:length(params)
		]

		params = [
				params[i] - agression*derivatives[i]
				for i ∈ 1:length(params)
		]

		if time() - start_time >= max_time
			@warn "time limit reached"
			break
		end

		@log params
		@log f(params...)
	end

	return params
end

@END_OF_DEBUG_CATEGORY
